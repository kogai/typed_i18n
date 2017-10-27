open Core
open Easy_format

type t = {
  path: string;
  value: Yojson.Basic.json;
}

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

let rec format = function
  | `List [] -> Atom ("[]", atom)
  | `Assoc [] -> Atom ("{}", atom)
  | `Assoc xs -> List (
      ("{", ",", "}", list),
      List.map ~f:format_field xs
    )
  | `List xs -> format_list xs
  | `Bool _ -> Atom ("boolean", atom)
  | `Float _ -> Atom ("number", atom)
  | `Int _ -> Atom ("number", atom)
  | `String _ -> Atom ("string", atom)
  | `Null -> Atom ("null", atom)
and format_field (key, value) = Label ((Atom ("+" ^ key ^ ":", atom), label), format value)
and format_list xs =
  let list_or_tuple = List.map ~f:format xs in
  if is_array list_or_tuple then
    match list_or_tuple with
    | [] -> raise Unreachable
    | x::_ -> match x with
      | Atom (x, atom) -> Atom (x ^ "[]", atom)
      | List (x, []) -> raise Unreachable
      | List (x, ys) as xs -> Atom (Easy_format.Pretty.to_string xs ^ "[]", atom)
      | Label (x, y) -> raise Unreachable 
      | Custom x -> raise Unreachable
  else
    List (("[", ",", "]", list), list_or_tuple)
and is_array = function
  | [] -> true
  | x::xs -> xs
             |> List.fold
               ~init:(x, true)
               ~f:(fun (before, is_array') next -> (next, is_array' && before = next))
             |> Tuple2.get2

let to_flow_type { path; value; } =
  let fname = "t" in
  let typedef = Easy_format.Pretty.to_string @@ format value in
  let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";" in
  result

exception Invalid_language_key 
exception Invalid_namespace_key 

let check_compatibility  = function
  | [] -> raise Invalid_language_key
  | ((primary_language, primary_json)::rest_languages) ->
    List.iter
      ~f:(fun (other_lang, other_json) -> 
          if format primary_json <> format other_json then
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
      | _ -> raise Invalid_language_key)

exception Invalid_extension of string
let output_filename path namespace =
  let filename = Filename.basename path in
  match Filename.split_extension filename with 
  | filename, Some ("json") -> filename ^ "." ^ namespace ^ ".js.flow" 
  | _, Some x -> raise @@ Invalid_extension (x ^ " is invalid extension")
  | _ -> raise @@ Invalid_extension "has not extension"

module Cmd : sig
  val name: string
  val run: string -> string -> string -> string list -> unit
  val term: unit Cmdliner.Term.t
end = struct
  open Cmdliner
  let name= "typed_i18n"

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

  let run input output prefer namespaces =
    input
    |> Yojson.Basic.from_file
    |> handle_language prefer namespaces
    |> List.iter ~f:(fun (namespace, path_and_values) ->
        path_and_values
        |> List.map ~f:to_flow_type
        |> String.concat ~sep:"\n"
        |> (fun content ->
            let content = "//@flow\n\n" ^ content ^ "\n\nexport type TFunction = typeof t\n" in
            let dist = output ^ "/" ^ output_filename input namespace in
            Out_channel.write_all dist content;
            print_endline @@ "Generated in " ^ dist
          )
      )

  let term = Term.(const run $ input $ output $ prefer $ namespaces)
end

let get_version =
  let open Yojson.Basic in
  let (json: string) = [%blob "../package.json"] in
  json
  |> from_string
  |> Util.member "version"
  |> Util.to_string
  |> (fun v -> "Version: " ^ v)

let () =
  let open Cmdliner in
  let open Yojson.Basic in
  let version = get_version in
  Term.exit @@ Term.eval (Cmd.term, Term.info Cmd.name ~version)
