open Js_of_ocaml
open Easy_format

type ty = {
  path: string;
  value: Yojson.Basic.json;
}

exception Unreachable
exception Invalid_namespace_key of string
exception Invalid_language_key of string option
exception Invalid_target_language of string

module Flow = struct
  type t = ty
  let extension = "js.flow"
  let read_only_tag =  Some "+"
  let definition format {path; value;} =
    let fname = "t" in
    let typedef = Easy_format.Pretty.to_string @@ format value in
    let result = Format.sprintf "declare function %s(_: \"%s\", _?: {}): %s;" fname path typedef in
    Atom (result, atom)
  let definitions contents =
    contents
    |> List.map Easy_format.Pretty.to_string
    |> String.concat "\n"
    |> Format.sprintf "// @flow\n\n%s\n\nexport type TFunction = typeof t\n"
end

module Typescript = struct
  type t = ty
  let extension = "d.ts"
  let read_only_tag =  Some "readonly "
  let definition format {path; value;} =
    let typedef = Easy_format.Pretty.to_string @@ format value in
    Atom (Format.sprintf "(_: \"%s\", __?: {}): %s" path typedef, atom)

  let definitions contents =
    let methods = List (
        ("interface TFunction {", ";", "}", list),
        contents
      ) in
    let interface = Atom (Easy_format.Pretty.to_string methods, atom) in
    let ns = List (
        ("declare namespace typed_i18n {", "", "}", list),
        interface::[]
      ) in
    Easy_format.Pretty.to_string ns ^ "\nexport = typed_i18n;\n"
end

let create_translator = function
  | "flow" -> (module Flow : Translate.Translatable with type t = ty)
  | "typescript" -> (module Typescript : Translate.Translatable with type t = ty)
  | lang -> raise @@ Invalid_target_language lang

let insert_dot k1 k2 =
  if k1 = "" then k2
  else k1 ^ "." ^ k2

(* json -> t list *)
let rec walk ?(path = "") = Yojson.Basic.(function
    | `Assoc xs as value ->
      let current = { path; value; } in
      let children = List.fold_left
          (fun acc (k, v) -> acc @ walk ~path:(insert_dot path k) v)
          []
          xs
      in
      if path = "" then children
      else current :: children
    | `List xs as value ->
      let current = { path; value; } in
      let children = List.fold_left
          (fun acc (i, x) -> acc @ walk ~path:(insert_dot path "[" ^ string_of_int i ^ "]") x)
          [] 
          (Utils.with_idx xs)
      in

      current :: children
    | value -> [{ path; value; }]
  )

module Logger : sig
  type t = [`Warn | `Error | `Info]
  val log: t -> ('a, out_channel, unit) format -> 'a
end = struct
  open Lwt_log_js
  type t = [`Warn | `Error | `Info]

  let log level =
    (match level with
     | `Info -> Printf.printf "[INFO]: "
     | `Warn -> Printf.printf "[WARN]: "
     | `Error -> Printf.eprintf "[ERROR]: "
    );
    Printf.printf
end

module Compatible : sig
  open Yojson.Basic
  val find: json -> string -> json
  val correct: json -> json -> string list
  val check: string * json -> string * json -> unit
end = struct
  open Yojson.Basic
  open Yojson.Basic.Util

  let rec find tree key =
    match Regexp.split (Regexp.regexp_string ".") key with
    | [] -> raise Unreachable
    | ""::[] ->
      print_endline "Maybe unreachable";
      member key tree
    | k::[] ->
      let r = Regexp.regexp_string "^\\[\\([0-9]\\)\\]$" in
      (match Regexp.string_match r k 0 with
       | Some r -> 
         let idx = match (Regexp.matched_group r 1) with
           | Some i -> i
           | _ -> "0"
         in
         index (int_of_string idx) tree
       | None -> member key tree)
    | k::ks -> find (member k tree) (String.concat "." ks)

  let correct primary secondary =
    let impl = create_translator "flow" in
    let module Impl = (val impl) in
    let module M = Translate.Translator (Impl) in
    let type_of_json json = json
                            |> M.format
                            |> Easy_format.Pretty.to_string
    in

    primary
    |> walk
    |> List.map (fun { path; value; } ->
        let is_match =
          try
            (type_of_json (find secondary path) = type_of_json value)
          with
          | Yojson.Basic.Util.Type_error _ -> false
        in
        path, is_match)
    |> List.filter (fun (_, is_match) -> not is_match)
    |> List.map (fun (x, _) -> x)

  let check (p_lang, p_json) (s_lang, s_json) =
    correct p_json s_json
    |> (fun errors ->
        (if List.length errors > 0 then
           Logger.log `Warn "[%s] and [%s] are not compatible\n" p_lang s_lang;
        );
        errors)
    |> List.iter (fun path -> Logger.log `Warn "[%s] isn't compatible\n" path)
end

let check_compatibility  = function
  | [] -> raise @@ Invalid_language_key None
  | ((primary_lang, primary_json)::rest_langs) ->
    List.iter
      (fun (other_lang, other_json) -> 
         Compatible.check (primary_lang, primary_json) (other_lang, other_json);
      )
      rest_langs

let handle_language prefer_lang namespaces json =
  let rec gather_langs = Yojson.Basic.(function
      | `Assoc [] -> []
      | `Assoc ((lang, json)::xs) -> (lang, json)::(gather_langs (`Assoc xs))
      | _ -> []
    )
  in
  let languages = gather_langs json in
  check_compatibility languages;

  languages
  |> Utils.find (fun (l, _) -> l = prefer_lang)
  |> (function
      | Some (_, json) ->
        Yojson.Basic.(namespaces
                      |> List.map (fun name ->
                          (match Util.member name json with
                           | `Null -> raise @@ Invalid_namespace_key name
                           | json -> name, (walk json))
                        ))
      | _ -> raise Unreachable)

let translate ~input_file ~output_dir ~languages (namespace, path_and_values) =
  List.iter (fun lang ->
      let impl = create_translator lang in
      let module Impl = (val impl) in
      let module M = Translate.Translator (Impl) in

      path_and_values
      |> List.map M.definition
      |> M.definitions
      |> (fun content ->
          let dist = output_dir ^ "/" ^ M.output_filename input_file namespace in
          let oc = open_out dist in
          output_string oc content;
          Logger.log `Info "Generated %s\n" dist
        )
    ) languages

module Cmd : sig
  val name: string
  val version: string
  val run: string -> string -> string -> string list -> string list -> unit
  val term: unit Cmdliner.Term.t
end = struct
  open Cmdliner
  let get_from_package_json key =
    let open Yojson.Basic in
    let (json: string) = [%blob "../package.json"] in
    json
    |> from_string
    |> Util.member key
    |> Util.to_string

  let name= "name"
            |> get_from_package_json
            |> Regexp.split (Regexp.regexp_string "/")
            |> Utils.last_exn

  let version = "version"
                |> get_from_package_json
                |> (^) "Version: " 

  let input =
    let doc = "Path of source locale file" in
    Arg.(value & opt string "" & info ["i"; "input"] ~docv:"INPUT" ~doc)

  let output =
    let doc = "Directory of output distination" in
    Arg.(value & opt string "" & info ["o"; "output"] ~docv:"OUTPUT" ~doc)

  let prefer =
    let doc = "Preferred language" in
    Arg.(value & opt string "en" & info ["p"; "prefer"] ~docv:"PREFER" ~doc)

  let namespaces =
    let doc = "List of namespace declared in locale file" in
    Arg.(value & opt_all string ["translation"] & info ["n"; "namespaces"] ~docv:"NAMESPACES" ~doc)

  let languages =
    let doc = "Destination language like flow or typescript" in
    Arg.(value & opt_all string ["flow"] & info ["l"; "languages"] ~docv:"LANGUAGES" ~doc)

  let run input_file output_dir prefer namespaces languages =
    try
      input_file
      |> Yojson.Basic.from_file
      |> handle_language prefer namespaces
      |> List.iter (translate ~input_file ~output_dir ~languages)
    with
    | Invalid_namespace_key key -> Logger.log `Error "Invalid namespace [%s] designated\n" key
    | Invalid_language_key None -> Logger.log `Error "Language key isn't existed\n"
    | Invalid_language_key Some lang -> Logger.log `Error "Invalid language, [%s] isn't supported\n" lang
    | Invalid_target_language lang -> Logger.log `Error "Invalid target, [%s] isn't supported\n" lang
    | Translate.Invalid_extension Some ext -> Logger.log `Error "Invalid extension, [%s] isn't supported\n" ext
    | Translate.Invalid_extension None -> Logger.log `Error "Extention doesn't existed\n"
    | Yojson.Json_error err -> Logger.log `Error "Invalid JSON \n%s\n" err
    | e ->
      Logger.log `Error "Unhandled error occured\n";
      raise e

  let term = Term.(const run $ input $ output $ prefer $ namespaces $ languages)
end

let () =
  let open Cmdliner in
  let open Yojson.Basic in

  Term.exit @@ Term.eval (Cmd.term, Term.info Cmd.name ~version: Cmd.version)
