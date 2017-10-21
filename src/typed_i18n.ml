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
        current :: children
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

let rec format json =
  let module EF = Easy_format in
  let string_of_flow_type = match json with
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
  in

  string_of_flow_type
and format_field (key, value) = Label ((Atom ("+" ^ key ^ ":", atom), label), format value)

let to_flow_type { path; value; } =
  let fname = "t" in
  let typedef = Easy_format.Pretty.to_string @@ format value in
  let result = "declare function " ^ fname ^ "(x: " ^ path ^ "): " ^ typedef ^ ";" in
  result

let () =
  let json = Yojson.Basic.from_file "fixture/locale.json" in
  let paths = walk json in
  List.iter
    ~f:(fun ({ path; value; }) -> print_endline @@ "Hit key -> " ^ path ^ " = " ^ (Yojson.Basic.to_string value))
    paths;

  print_endline "";
  List.iter ~f:(fun x ->
      print_endline @@ to_flow_type x
    ) paths;
  print_endline "";

  print_endline @@ Yojson.Basic.pretty_to_string json
