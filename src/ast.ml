(* filename * line * column *)
type info = string * int * int
[@@deriving show]

let show_info (file, line, column) = Format.sprintf "%s:%d:%d" file line column
let create_info file line column = (file, line, column)

type t =
  | Identifier of info * string
[@@deriving show]

let get_info = function
  | Identifier (i, _) -> i

let rec string_of_t = Printf.(function
    | Identifier (_, name) -> name
  )
