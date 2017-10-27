module type Translator = sig
  (* TODO: Consider to include from typed_i18n.ml without circular references *)
  type t = {
    path: string;
    value: Yojson.Basic.json;
  }

  val read_only_tag: string
  val t_of_string: t -> string
end

module Flowtype (Impl: Translator) : (sig
  type t
  val  format: Yojson.Basic.json -> Easy_format.t
end with type t = Impl.t) = struct
  open Core
  open Easy_format
  type t = Impl.t

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
    let array_or_tuple = List.map ~f:format xs in
    if is_array array_or_tuple then
      match array_or_tuple with
      | [] -> exit 1
      | x::_ -> Atom (Easy_format.Pretty.to_string x ^ "[]", atom)
    else
      List (("[", ",", "]", list), array_or_tuple)
  and is_array = function
    | [] -> true
    | x::xs -> xs
               |> List.fold
                 ~init:(x, true)
                 ~f:(fun (before, is_array') next -> (next, is_array' && before = next))
               |> Tuple2.get2

  (* let to_flow_type { path; value; } =
     let fname = "t" in
     let typedef = Easy_format.Pretty.to_string @@ format value in
     let result = "declare function " ^ fname ^ "(_: \""^ path ^ "\"): " ^ typedef ^ ";" in
     result *)
end
