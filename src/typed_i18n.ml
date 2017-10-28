open Core
open Easy_format

type ty = {
  path: string;
  value: Yojson.Basic.json;
}

module Flow = Translate.Translator (struct
    type t = ty
    let extension = "js.flow"
    let read_only_tag =  Some "+"
    let string_of_t format {path; value;} =
      let fname = "t" in
      let typedef = Easy_format.Pretty.to_string @@ format value in
      let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";" in
      result
    let definition content = "// @flow\n\n" ^ content ^ "\n\nexport type TFunction = typeof t\n"
  end)

module Typescript = Translate.Translator (struct
    type t = ty
    let extension = "d.ts"
    let read_only_tag =  Some "readonly "
    let string_of_t format {path; value;} =
      let fname = "t" in
      let typedef = Easy_format.Pretty.to_string @@ format value in
      let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";" in
      result
    let definition content = "declare namespace typed_i18n {\n" ^ content ^ "\n\nexport type TFunction = typeof t\n}"
  end)

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

exception Unreachable
exception Invalid_namespace_key 
exception Invalid_language_key 
exception Invalid_language of string

let check_compatibility  = function
  | [] -> raise Invalid_language_key
  | ((primary_language, primary_json)::rest_languages) ->
    List.iter
      ~f:(fun (other_lang, other_json) -> 
          if primary_json <> other_json then
            print_endline @@ "Warning: [" ^ primary_language ^ "] and [" ^ other_lang ^ "] are not compatible"
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
                           | `Null -> raise Invalid_namespace_key
                           | json -> name, (walk json))
                        ))
      | _ -> raise Unreachable)

let translate ~input_file ~output_dir ~languages (namespace, path_and_values) =
  List.iter languages ~f:(fun lang ->
      (* let M = match lang with
         | "flow" -> Flow
         | "typescript" -> Typescript
         | l -> raise @@ Invalid_language (l ^ " is not supported")
         in *)
      let module M = Typescript in

      path_and_values
      |> List.map ~f:M.string_of_t
      |> String.concat ~sep:"\n"
      |> M.definition
      |> (fun content ->
          let dist = output_dir ^ "/" ^ M.output_filename input_file namespace in
          Out_channel.write_all dist content;
          print_endline @@ "Generated in " ^ dist
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
    input_file
    |> Yojson.Basic.from_file
    |> handle_language prefer namespaces
    |> List.iter ~f:(translate ~input_file ~output_dir ~languages)

  let term = Term.(const run $ input $ output $ prefer $ namespaces $ languages)
end

let () =
  let open Cmdliner in
  let open Yojson.Basic in

  Term.exit @@ Term.eval (Cmd.term, Term.info Cmd.name ~version: Cmd.version)
