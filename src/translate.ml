exception Unreachable 
exception Invalid_extension of string option

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
  open Easy_format
  type t = Impl.t

  let rec format = function
    | `List [] -> Atom ("[]", atom)
    | `Assoc [] -> Atom ("{}", atom)
    | `Assoc xs -> List (
        ("{", ",", "}", list),
        List.map format_field xs
      )
    | `List xs -> format_list xs
    | `Bool _ -> Atom ("boolean", atom)
    | `Float _ -> Atom ("number", atom)
    | `Int _ -> Atom ("number", atom)
    | `String _ -> Atom ("string", atom)
    | `Null -> Atom ("null", atom)
  and format_field (key, value) =
    let read_only_tag = match Impl.read_only_tag with
      | Some(s) -> s
      | None -> "" 
    in
    let prop = Format.sprintf "%s\"%s\":" read_only_tag key in
    Label ((Atom (prop, atom), label), format value)
  and format_list xs =
    let array_or_tuple = List.map format xs in
    if is_array array_or_tuple then
      match array_or_tuple with
      | [] -> raise Unreachable
      | x::_ -> Atom (Pretty.to_string x ^ "[]", atom)
    else
      List (("[", ",", "]", list), array_or_tuple)
  and is_array = function
    | [] -> true
    | x::xs -> xs
               |> List.fold_left
                 (fun (before, is_array') next -> (next, is_array' && before = next))
                 (x, true)
               |> (fun (_, x) -> x)

  let definition = Impl.definition format
  let definitions = Impl.definitions

  let output_filename path namespace =
    let filename = Filename.basename path in
    match Filename.chop_extension filename with
    | name -> Format.sprintf "%s.%s.%s" name namespace Impl.extension
    | exception _ -> raise (Invalid_extension None)
end
