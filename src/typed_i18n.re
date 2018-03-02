open Js_of_ocaml;

open Easy_format;

type ty = {
  path: string,
  value: Yojson.Basic.json
};

exception Unreachable;

exception Invalid_namespace_key(string);

exception Invalid_language_key(option(string));

exception Invalid_target_language(string);

module Flow = {
  type t = ty;
  let extension = "js.flow";
  let read_only_tag = Some("+");
  let definition = (format, {path, value}) => {
    let fname = "t";
    let typedef = Easy_format.Pretty.to_string @@ format(value);
    let result =
      Format.sprintf("declare function %s(_: \"%s\", _?: {}): %s;", fname, path, typedef);
    Atom(result, atom)
  };
  let definitions = (contents) =>
    contents
    |> List.map(Easy_format.Pretty.to_string)
    |> String.concat("\n")
    |> Format.sprintf("// @flow\n\n%s\n\nexport type TFunction = typeof t\n");
};

module Typescript = {
  type t = ty;
  let extension = "d.ts";
  let read_only_tag = Some("readonly ");
  let definition = (format, {path, value}) => {
    let typedef = Easy_format.Pretty.to_string @@ format(value);
    Atom(Format.sprintf("(_: \"%s\", __?: {}): %s", path, typedef), atom)
  };
  let definitions = (contents) => {
    let methods = List(("interface TFunction {", ";", "}", list), contents);
    let interface = Atom(Easy_format.Pretty.to_string(methods), atom);
    let ns = List(("declare namespace typed_i18n {", "", "}", list), [interface]);
    Easy_format.Pretty.to_string(ns) ++ "\nexport = typed_i18n;\n"
  };
};

let create_translator =
  fun
  | "flow" => ((module Flow): (module Translate.Translatable with type t = ty))
  | "typescript" => ((module Typescript): (module Translate.Translatable with type t = ty))
  | lang => raise @@ Invalid_target_language(lang);

let insert_dot = (k1, k2) =>
  if (k1 == "") {
    k2
  } else {
    k1 ++ "." ++ k2
  };

/* json -> t list */
let rec walk = (~path="") =>
  Yojson.Basic.(
    fun
    | `Assoc(xs) as value => {
        let current = {path, value};
        let children =
          List.fold_left((acc, (k, v)) => acc @ walk(~path=insert_dot(path, k), v), [], xs);
        if (path == "") {
          children
        } else {
          [current, ...children]
        }
      }
    | `List(xs) as value => {
        let current = {path, value};
        let children =
          List.fold_left(
            (acc, (i, x)) => acc @ walk(~path=insert_dot(path, "[") ++ string_of_int(i) ++ "]", x),
            [],
            Utils.with_idx(xs)
          );
        [current, ...children]
      }
    | value => [{path, value}]
  );

module Logger: {
  type t = [ | `Warn | `Error | `Info];
  let log: (t, format('a, out_channel, unit)) => 'a;
} = {
  open Lwt_log_js;
  type t = [ | `Warn | `Error | `Info];
  let log = (level) => {
    switch level {
    | `Info => Printf.printf("[INFO]: ")
    | `Warn => Printf.printf("[WARN]: ")
    | `Error => Printf.eprintf("[ERROR]: ")
    };
    Printf.printf
  };
};

module Compatible: {
  open Yojson.Basic;
  let find: (json, string) => json;
  let correct: (json, json) => list(string);
  let check: ((string, json), (string, json)) => unit;
} = {
  open Yojson.Basic;
  open Yojson.Basic.Util;
  let rec find = (tree, key) =>
    switch (Regexp.split(Regexp.regexp_string("."), key)) {
    | [] => raise(Unreachable)
    | [""] =>
      print_endline("Maybe unreachable");
      member(key, tree)
    | [k] =>
      let r = Regexp.regexp_string("^\\[\\([0-9]\\)\\]$");
      switch (Regexp.string_match(r, k, 0)) {
      | Some(r) =>
        let idx =
          switch (Regexp.matched_group(r, 1)) {
          | Some(i) => i
          | _ => "0"
          };
        index(int_of_string(idx), tree)
      | None => member(key, tree)
      }
    | [k, ...ks] => find(member(k, tree), String.concat(".", ks))
    };
  let correct = (primary, secondary) => {
    let impl = create_translator("flow");
    module Impl = (val impl);
    module M = Translate.Translator(Impl);
    let type_of_json = (json) => json |> M.format |> Easy_format.Pretty.to_string;
    primary
    |> walk
    |> List.map(
         ({path, value}) => {
           let is_match =
             try (type_of_json(find(secondary, path)) == type_of_json(value)) {
             | Yojson.Basic.Util.Type_error(_) => false
             };
           (path, is_match)
         }
       )
    |> List.filter(((_, is_match)) => ! is_match)
    |> List.map(((x, _)) => x)
  };
  let check = ((p_lang, p_json), (s_lang, s_json)) =>
    correct(p_json, s_json)
    |> (
      (errors) => {
        if (List.length(errors) > 0) {
          Logger.log(`Warn, "[%s] and [%s] are not compatible\n", p_lang, s_lang)
        };
        errors
      }
    )
    |> List.iter((path) => Logger.log(`Warn, "[%s] isn't compatible\n", path));
};

let check_compatibility =
  fun
  | [] => raise @@ Invalid_language_key(None)
  | [(primary_lang, primary_json), ...rest_langs] =>
    List.iter(
      ((other_lang, other_json)) =>
        Compatible.check((primary_lang, primary_json), (other_lang, other_json)),
      rest_langs
    );

let handle_language = (prefer_lang, namespaces, json) => {
  let rec gather_langs =
    Yojson.Basic.(
      fun
      | `Assoc([]) => []
      | `Assoc([(lang, json), ...xs]) => [(lang, json), ...gather_langs(`Assoc(xs))]
      | _ => []
    );
  let languages = gather_langs(json);
  check_compatibility(languages);
  languages
  |> Utils.find(((l, _)) => l == prefer_lang)
  |> (
    fun
    | Some((_, json)) =>
      Yojson.Basic.(
        namespaces
        |> List.map(
             (name) =>
               switch (Util.member(name, json)) {
               | `Null => raise @@ Invalid_namespace_key(name)
               | json => (name, walk(json))
               }
           )
      )
    | _ => raise(Unreachable)
  )
};

let translate = (~input_file, ~output_dir, ~languages, (namespace, path_and_values)) =>
  List.iter(
    (lang) => {
      let impl = create_translator(lang);
      module Impl = (val impl);
      module M = Translate.Translator(Impl);
      path_and_values
      |> List.map(M.definition)
      |> M.definitions
      |> (
        (content) => {
          let dist = output_dir ++ "/" ++ M.output_filename(input_file, namespace);
          let oc = open_out(dist);
          output_string(oc, content);
          Logger.log(`Info, "Generated %s\n", dist)
        }
      )
    },
    languages
  );

module Cmd: {
  let name: string;
  let version: string;
  let run: (string, string, string, list(string), list(string)) => unit;
  let term: Cmdliner.Term.t(unit);
} = {
  open Cmdliner;
  let get_from_package_json = (key) => {
    open Yojson.Basic;
    let json: string = [%blob "../package.json"];
    json |> from_string |> Util.member(key) |> Util.to_string
  };
  let name =
    "name" |> get_from_package_json |> Regexp.split(Regexp.regexp_string("/")) |> Utils.last_exn;
  let version = "version" |> get_from_package_json |> (++)("Version: ");
  let input = {
    let doc = "Path of source locale file";
    Arg.(value & opt(string, "") & info(["i", "input"], ~docv="INPUT", ~doc))
  };
  let output = {
    let doc = "Directory of output distination";
    Arg.(value & opt(string, "") & info(["o", "output"], ~docv="OUTPUT", ~doc))
  };
  let prefer = {
    let doc = "Preferred language";
    Arg.(value & opt(string, "en") & info(["p", "prefer"], ~docv="PREFER", ~doc))
  };
  let namespaces = {
    let doc = "List of namespace declared in locale file";
    Arg.(
      value
      & opt_all(string, ["translation"])
      & info(["n", "namespaces"], ~docv="NAMESPACES", ~doc)
    )
  };
  let languages = {
    let doc = "Destination language like flow or typescript";
    Arg.(value & opt_all(string, ["flow"]) & info(["l", "languages"], ~docv="LANGUAGES", ~doc))
  };
  let run = (input_file, output_dir, prefer, namespaces, languages) =>
    try (
      input_file
      |> Yojson.Basic.from_file
      |> handle_language(prefer, namespaces)
      |> List.iter(translate(~input_file, ~output_dir, ~languages))
    ) {
    | Invalid_namespace_key(key) => Logger.log(`Error, "Invalid namespace [%s] designated\n", key)
    | Invalid_language_key(None) => Logger.log(`Error, "Language key isn't existed\n")
    | Invalid_language_key(Some(lang)) =>
      Logger.log(`Error, "Invalid language, [%s] isn't supported\n", lang)
    | Invalid_target_language(lang) =>
      Logger.log(`Error, "Invalid target, [%s] isn't supported\n", lang)
    | Translate.Invalid_extension(Some(ext)) =>
      Logger.log(`Error, "Invalid extension, [%s] isn't supported\n", ext)
    | Translate.Invalid_extension(None) => Logger.log(`Error, "Extention doesn't existed\n")
    | Yojson.Json_error(err) => Logger.log(`Error, "Invalid JSON \n%s\n", err)
    | e =>
      Logger.log(`Error, "Unhandled error occured\n");
      raise(e)
    };
  let term = Term.(const(run) $ input $ output $ prefer $ namespaces $ languages);
};

let () =
  Cmdliner.(
    Yojson.Basic.(Term.exit @@ Term.eval((Cmd.term, Term.info(Cmd.name, ~version=Cmd.version))))
  );
