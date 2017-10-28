open Core
open Easy_format
open Textutils.Std

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
    let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";"in
    Atom (result, atom)
  let definitions contents =
    contents
    |> List.map ~f:Easy_format.Pretty.to_string
    |> String.concat ~sep:"\n"
    |> (fun content ->
        "// @flow\n\n" ^ content ^ "\n\nexport type TFunction = typeof t\n"
      )
end

module Typescript = struct
  type t = ty
  let extension = "d.ts"
  let read_only_tag =  Some "readonly "
  let definition format {path; value;} =
    let typedef = Easy_format.Pretty.to_string @@ format value in
    Atom ("(_: \""^ path ^ "\"): " ^ typedef, atom)

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
    Easy_format.Pretty.to_string ns ^ "\nexport = typed_i18n;\nexport as namespace typed_i18n;\n"
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
      let children = List.fold
          xs
          ~init:[]
          ~f:(fun acc (k, v) -> acc @ walk ~path:(insert_dot path k) v) in
      if path = "" then children
      else current :: children
    | `List xs as value ->
      let current = { path; value; } in
      let children = List.foldi
          xs
          ~init:[]
          ~f:(fun i acc x -> acc @ walk ~path:(insert_dot path "[" ^ string_of_int i ^ "]") x) in

      current :: children
    | value -> [{ path; value; }]
  )

module Logger : sig
  type t = [`Warn | `Error | `Info]

  val log: t -> ('a, Out_channel.t, unit) format -> 'a
end = struct
  open Console
  type t = [`Warn | `Error | `Info]

  let log level =
    (match level with
     | `Warn -> Ansi.printf [`Yellow] "[WARN]: "
     | `Error -> Ansi.printf [`Red] "[ERROR]: "
     | `Info -> Ansi.printf [`Cyan] "[INFO]: "
    );
    Console.Ansi.printf [`White]
end

let check_compatibility  = function
  | [] -> raise @@ Invalid_language_key None
  | ((primary_language, primary_json)::rest_languages) ->
    List.iter
      ~f:(fun (other_lang, other_json) -> 
          if primary_json <> other_json then 
            Logger.log `Warn "[%s] and [%s] are not compatible\n" primary_language other_lang
        )
      rest_languages

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
  |> List.find ~f:(fun (l, _) -> l = prefer_lang)
  |> (function
      | Some (_, json) ->
        Yojson.Basic.(namespaces
                      |> List.map ~f:(fun name ->
                          (match Util.member name json with
                           | `Null -> raise @@ Invalid_namespace_key name
                           | json -> name, (walk json))
                        ))
      | _ -> raise Unreachable)

let translate ~input_file ~output_dir ~languages (namespace, path_and_values) =
  List.iter languages ~f:(fun lang ->
      let impl = create_translator lang in
      let module Impl = (val impl) in
      let module M = Translate.Translator (Impl) in

      path_and_values
      |> List.map ~f:M.definition
      |> M.definitions
      |> (fun content ->
          let dist = output_dir ^ "/" ^ M.output_filename input_file namespace in
          Out_channel.write_all dist content;
          Logger.log `Info "Generated %s\n" dist
        )
    ) 

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
            |> String.split ~on:'/'
            |> List.last_exn

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
    let open Console in
    try
      input_file
      |> Yojson.Basic.from_file
      |> handle_language prefer namespaces
      |> List.iter ~f:(translate ~input_file ~output_dir ~languages)
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
