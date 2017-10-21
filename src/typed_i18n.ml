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
let walk json =
  let rec walk_impl path = Yojson.Basic.(function
      | `Assoc xs as value ->
        let current = { path; value; } in
        let children = List.fold
            xs
            ~init:[]
            ~f:(fun acc (k, v) -> acc @ walk_impl (insert_dot path k) v) in
        if path = "" then children
        else current :: children
      | `List xs as value ->
        let current = { path; value; } in
        let children = List.foldi
            xs
            ~init:[]
            ~f:(fun i acc x -> acc @ walk_impl (insert_dot path "[" ^ string_of_int i ^ "]") x) in

        current :: children
      | value -> [{ path; value; }]
    )
  in
  walk_impl "" json

let rec format = function
  | `List [] -> Atom ("[]", atom)
  | `Assoc [] -> Atom ("{}", atom)
  | `Assoc xs -> List (
      ("{", ",", "}", list),
      List.map ~f:format_field xs
    )
  | `List xs -> List (
      ("[", ",", "]", list),
      List.map ~f:format xs
    )
  | `Bool _ -> Atom ("boolean", atom)
  | `Float _ -> Atom ("number", atom)
  | `Int _ -> Atom ("number", atom)
  | `String _ -> Atom ("string", atom)
  | `Null -> Atom ("null", atom)
and format_field (key, value) = Label ((Atom ("+" ^ key ^ ":", atom), label), format value)

let to_flow_type { path; value; } =
  let fname = "t" in
  let typedef = Easy_format.Pretty.to_string @@ format value in
  let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";" in
  result

let handle_language json =
  let rec gather_langs = Yojson.Basic.(function
      | `Assoc [] -> []
      | `Assoc ((l, v)::xs) -> (l, v)::(gather_langs (`Assoc xs))
      | _ -> []
    )
  in
  let languages = gather_langs json in
  (* TODO: Check compatibility between languages
     List.fold ~init:true ~f:(fun acc (lan, v) -> acc) languages; *)

  languages
  |> List.hd_exn
  |> (fun (l, v) -> walk v)

exception Invalid_extension of string
let output_filename path =
  let filename = Filename.basename path in
  match Filename.split_extension filename with 
  | filename, Some ("json") -> filename ^ ".js.flow" 
  | _, Some x -> raise @@ Invalid_extension (x ^ " is invalid extension")
  | _ -> raise @@ Invalid_extension "has not extension"

module Cmd : sig
  val name: string
  val run: string -> string -> unit
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

  let run input output =
    input
    |> Yojson.Basic.from_file
    |> handle_language
    |> List.map ~f:to_flow_type
    |> String.concat ~sep:"\n"
    |> (fun content ->
        let content = "//@flow\n\n" ^ content ^ "\n\nexport default t\n" in
        let dist = output ^ "/" ^ output_filename input in
        Out_channel.write_all dist content;
        print_endline @@ "Generated in " ^ dist
      )

  let term = Term.(const run $ input $ output)
end

let () =
  let open Cmdliner in
  Term.exit @@ Term.eval (Cmd.term, Term.info Cmd.name)
