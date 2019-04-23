open Easy_format;

[@bs.module]
external pkg : {
  .
  "version": string,
  "name": string,
} =
  "../package.json";

type ty = {
  path: string,
  value: Js.Json.t,
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
      Format.sprintf(
        "declare function %s(_: \"%s\", _?: {}): %s;",
        fname,
        path,
        typedef,
      );
    Atom(result, atom);
  };
  let definitions = contents =>
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
    Atom(Format.sprintf("(_: \"%s\", __?: {}): %s", path, typedef), atom);
  };
  let definitions = contents => {
    let methods = List(("interface TFunction {", ";", "}", list), contents);
    let interface = Atom(Easy_format.Pretty.to_string(methods), atom);
    let ns =
      List(("declare namespace typed_i18n {", "", "}", list), [interface]);
    Easy_format.Pretty.to_string(ns) ++ "\nexport = typed_i18n;\n";
  };
};

let create_translator =
  fun
  | "flow" => ((module Flow): (module Translate.Translatable with type t = ty))
  | "typescript" => (
      (module Typescript): (module Translate.Translatable with type t = ty)
    )
  | lang => raise @@ Invalid_target_language(lang);

let insert_dot = (k1, k2) =>
  if (k1 == "") {
    k2;
  } else {
    k1 ++ "." ++ k2;
  };

/* json -> t list */
let rec walk = (~path="", ~current_depth=0, ~max_depth, value) => {
  switch (Js.Json.classify(value)) {
  | _ when current_depth >= (max_depth + 1) => []
  | Js.Json.JSONObject(xs) =>
    let current = {path, value};
    let next_depth = current_depth + 1;
    let children =
      List.fold_left(
        (acc, (k, v)) =>
          List.append(acc, walk(~path=insert_dot(path, k), ~current_depth=next_depth, ~max_depth, v)),
        [],
        xs |> Js.Dict.entries |> Array.to_list,
      );
    path == "" ? children : [current, ...children];
  | Js.Json.JSONArray(xs) =>
    let current = {path, value};
    let next_depth = current_depth + 1;
    let children =
      List.fold_left(
        (acc, (i, x)) => {
          let path =
            insert_dot(path, Format.sprintf("[%s]", string_of_int(i)));
          List.append(acc, walk(~path, ~current_depth=next_depth, ~max_depth, x));
        },
        [],
        xs |> Array.to_list |> Utils.with_idx,
      );
    [current, ...children];
  | _ => [{path, value}]
  }
};

module Logger: {
  type t = [ | `Warn | `Error | `Info];
  let log: (t, format('a, out_channel, unit)) => 'a;
} = {
  type t = [ | `Warn | `Error | `Info];
  let log = (level, msg) => {
    switch (level) {
    | `Info => Printf.printf("\027[1;32m[INFO]: \027[0m")
    | `Warn => Printf.printf("\027[1;33m[WARN]: \027[0m")
    | `Error => Printf.printf("\027[1;31m[ERROR]: \027[0m")
    };
    Printf.printf(msg);
  };
};

module Compatible: {
  let find: (Js.Json.t, string) => Js.Json.t;
  let correct: (~max_depth: int, Js.Json.t, Js.Json.t) => list(string);
  let check: (~max_depth: int, (string, Js.Json.t), (string, Js.Json.t)) => unit;
} = {
  let rec find = (tree, key) =>
    switch (Belt.List.fromArray(Js.String.split(".", key))) {
    | []
    | [""] => raise(Unreachable)
    | [k] =>
      let r = Js.Re.fromString("^\\[([0-9])\\]$");
      switch (Js.String.match(r, k)) {
      | Some(rs) =>
        let idx =
          switch (Belt.Array.get(rs, 1)) {
          | Some(i) => i
          | _ => "0"
          };
        Utils.member(idx, tree);
      | None => Utils.member(key, tree)
      };
    | [k, ...ks] =>
      find(
        Utils.member(k, tree),
        Js.Array.joinWith(".", Belt.List.toArray(ks)),
      )
    };
  let correct = (~max_depth, primary, secondary) => {
    let impl = create_translator("flow");
    module Impl = (val impl);
    module M = Translate.Translator(Impl);
    let type_of_json = json =>
      json |> M.format |> Easy_format.Pretty.to_string;
    primary
    |> walk(~max_depth)
    |> List.map(({path, value}) => {
         let is_match =
           try (type_of_json(find(secondary, path)) == type_of_json(value)) {
           | Not_found => false
           };
         (path, is_match);
       })
    |> List.filter(((_, is_match)) => ! is_match)
    |> List.map(((x, _)) => x);
  };
  let check = (~max_depth, (p_lang, p_json), (s_lang, s_json)) =>
    correct(~max_depth, p_json, s_json)
    |> (
      errors => {
        if (List.length(errors) > 0) {
          Logger.log(
            `Warn,
            "[%s] and [%s] are not compatible\n",
            p_lang,
            s_lang,
          );
        };
        errors;
      }
    )
    |> (
      errors =>
        switch (Belt.List.splitAt(errors, 10)) {
        | Some((xs, ys)) =>
          List.iter(
            path => Logger.log(`Warn, "[%s] isn't compatible\n", path),
            xs,
          );
          Logger.log(
            `Warn,
            "And there are [%i] imcompatibles left\n",
            List.length(ys),
          );
        | None =>
          List.iter(
            path => Logger.log(`Warn, "[%s] isn't compatible\n", path),
            errors,
          )
        }
    );
};

let check_compatibility = (~max_depth: int) =>
  fun
  | [] => raise @@ Invalid_language_key(None)
  | [(primary_lang, primary_json), ...rest_langs] =>
    List.iter(
      ((other_lang, other_json)) =>
        Compatible.check(
          ~max_depth,
          (primary_lang, primary_json),
          (other_lang, other_json),
        ),
      rest_langs,
    );

let handle_language =
    (~max_depth: int, prefer_lang: string, namespaces: list(string), json: Js.Json.t) => {
  let gather_langs =
    Js.Json.(
      fun
      | JSONObject(x) => Belt.List.fromArray(Js.Dict.entries(x))
      | _ => []
    );
  let languages = gather_langs(Js.Json.classify(json));
  check_compatibility(~max_depth, languages);
  languages
  |> Utils.find(((l, _)) => l == prefer_lang)
  |> (
    fun
    | Some((_, json)) =>
      List.map(
        name => {
          let json =
            try (Utils.member(name, json)) {
            | Not_found => raise @@ Invalid_namespace_key(name)
            };
          (name, walk(json, ~max_depth));
        },
        namespaces,
      )
    | _ => raise(Unreachable)
  );
};

let translate =
    (~input_file, ~output_dir, ~languages, (namespace, path_and_values)) =>
  List.iter(
    lang => {
      let impl = create_translator(lang);
      module Impl = (val impl);
      module M = Translate.Translator(Impl);
      path_and_values
      |> List.map(M.definition)
      |> M.definitions
      |> (
        content => {
          let dist =
            output_dir ++ "/" ++ M.output_filename(input_file, namespace);
          Node.Fs.writeFileSync(dist, content, `utf8);
          Logger.log(`Info, "Generated %s\n", dist);
        }
      );
    },
    languages,
  );

module Cmd: {
  let name: string;
  let version: string;
  let run: (string, string, string, list(string), list(string), int) => unit;
  let term: Cmdliner.Term.t(unit);
} = {
  open Cmdliner;
  let name = pkg##name;
  let version = "Version: " ++ pkg##version;
  let input = {
    let doc = "Path of source locale file";
    Arg.(
      value & opt(string, "") & info(["i", "input"], ~docv="INPUT", ~doc)
    );
  };
  let output = {
    let doc = "Directory of output distination";
    Arg.(
      value & opt(string, "") & info(["o", "output"], ~docv="OUTPUT", ~doc)
    );
  };
  let prefer = {
    let doc = "Preferred language";
    Arg.(
      value
      & opt(string, "en")
      & info(["p", "prefer"], ~docv="PREFER", ~doc)
    );
  };
  let namespaces = {
    let doc = "List of namespace declared in locale file";
    Arg.(
      value
      & opt_all(string, ["translation"])
      & info(["n", "namespaces"], ~docv="NAMESPACES", ~doc)
    );
  };
  let languages = {
    let doc = "Destination language like flow or typescript";
    Arg.(
      value
      & opt_all(string, ["flow"])
      & info(["l", "languages"], ~docv="LANGUAGES", ~doc)
    );
  };
  let max_depth = {
    let doc = "Max depth of dictionary JSON tree";
    Arg.(
      value
      & opt(int, 255)
      & info(["d", "max_depth"], ~docv="MAX_DEPTH", ~doc)
    );
  };
  let run = (input_file, output_dir, prefer, namespaces, languages, max_depth) =>
    try (
      input_file
      |> Node.Fs.readFileSync(_, `utf8)
      |> Js.Json.parseExn
      |> handle_language(~max_depth, prefer, namespaces)
      |> List.iter(translate(~input_file, ~output_dir, ~languages))
    ) {
    | Invalid_namespace_key(key) =>
      Logger.log(`Error, "Invalid namespace [%s] designated\n", key)
    | Invalid_language_key(None) =>
      Logger.log(`Error, "Language key isn't existed\n")
    | Invalid_language_key(Some(lang)) =>
      Logger.log(`Error, "Invalid language, [%s] isn't supported\n", lang)
    | Invalid_target_language(lang) =>
      Logger.log(`Error, "Invalid target, [%s] isn't supported\n", lang)
    | Translate.Invalid_extension(Some(ext)) =>
      Logger.log(`Error, "Invalid extension, [%s] isn't supported\n", ext)
    | Translate.Invalid_extension(None) =>
      Logger.log(`Error, "Extention doesn't existed\n")
    | Js.Exn.Error(err) =>
      let msg =
        switch (Js.Exn.message(err)) {
        | Some(m) => m
        | None => "UnKnown"
        };
      Logger.log(`Error, "Invalid JSON \n%s\n", msg);
    | e =>
      Logger.log(`Error, "Unhandled error occured\n");
      raise(e);
    };
  let term =
    Term.(const(run) $ input $ output $ prefer $ namespaces $ languages $ max_depth);
};

let () = {
  let argv =
    Sys.argv
    |> Belt.List.fromArray
    |> Belt.List.tail
    |> (
      fun
      | Some(xs) => Belt.List.toArray(xs)
      | _ => [||]
    );
  Cmdliner.(
    Term.exit @@
    Term.eval((Cmd.term, Term.info(Cmd.name, ~version=Cmd.version)), ~argv)
  );
};
