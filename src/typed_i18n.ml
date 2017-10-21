open Core

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

(* json -> string(represent type of flow) *)
let value_to_print json =
  (* | `Assoc xs ->
     let (key, value) = List.hd_exn xs in
     print_endline @@ "Hit key -> " ^ key;
     []
     | `List x -> []
     | `Bool x -> []
     | `Float x -> []
     | `Int x -> []
     | `String x -> []
     | `Null -> []
  *)
  ""

let () =
  let json = Yojson.Basic.from_file "fixture/locale.json" in
  let paths = walk json in
  List.iter ~f:(fun ({ path; value; }) -> print_endline @@ "Hit key -> " ^ path ^ " = " ^ (Yojson.Basic.to_string value)) paths;
  print_endline @@ Yojson.Basic.pretty_to_string json
