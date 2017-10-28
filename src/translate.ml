module type Translatable = sig
  type t
  val extension: string
  val read_only_tag: string option
  val definition: (Yojson.Basic.json -> Easy_format.t) -> t -> Easy_format.t
  val definitions: Easy_format.t list -> string
end

module Translator (Impl: Translatable) : (sig
  type t

  val format: Yojson.Basic.json -> Easy_format.t
  val definition: t -> Easy_format.t
  val output_filename: string -> string -> string
  val definitions: Easy_format.t list -> string
end with type t = Impl.t) = struct
  open Core
  open Easy_format
  type t = Impl.t

  exception Unreachable 
  exception Invalid_extension of string option

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
  and format_field (key, value) =
    let read_only_tag = Option.value Impl.read_only_tag ~default:"" in
    Label ((Atom (read_only_tag ^ key ^ ":", atom), label), format value)
  and format_list xs =
    let array_or_tuple = List.map ~f:format xs in
    if is_array array_or_tuple then
      match array_or_tuple with
      | [] -> raise Unreachable
      | x::_ -> Atom (Pretty.to_string x ^ "[]", atom)
    else
      List (("[", ",", "]", list), array_or_tuple)
  and is_array = function
    | [] -> true
    | x::xs -> xs
               |> List.fold
                 ~init:(x, true)
                 ~f:(fun (before, is_array') next -> (next, is_array' && before = next))
               |> Tuple2.get2

  let definition = Impl.definition format
  let definitions = Impl.definitions

  let output_filename path namespace =
    let filename = Filename.basename path in
    match Filename.split_extension filename with 
    | filename, Some ("json") -> filename ^ "." ^ namespace ^ "." ^ Impl.extension 
    | _, Some x -> raise @@ Invalid_extension (Some x)
    | _ -> raise @@ Invalid_extension None
end
