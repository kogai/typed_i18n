exception Unreachable;

exception Invalid_extension(option(string));

module type Translatable = {
  type t;
  let extension: string;
  let read_only_tag: option(string);
  let definition: (Yojson.Basic.json => Easy_format.t, t) => Easy_format.t;
  let definitions: list(Easy_format.t) => string;
};

module Translator =
       (Impl: Translatable)
       : (
           {
             type t;
             let format: Yojson.Basic.json => Easy_format.t;
             let definition: t => Easy_format.t;
             let output_filename: (string, string) => string;
             let definitions: list(Easy_format.t) => string;
           } with
             type t = Impl.t
         ) => {
  open Easy_format;
  type t = Impl.t;
  let rec format =
    fun
    | `List([]) => [@implicit_arity] Atom("[]", atom)
    | `Assoc([]) => [@implicit_arity] Atom("{}", atom)
    | `Assoc(xs) => [@implicit_arity] List(("{", ",", "}", list), List.map(format_field, xs))
    | `List(xs) => format_list(xs)
    | `Bool(_) => [@implicit_arity] Atom("boolean", atom)
    | `Float(_) => [@implicit_arity] Atom("number", atom)
    | `Int(_) => [@implicit_arity] Atom("number", atom)
    | `String(_) => [@implicit_arity] Atom("string", atom)
    | `Null => [@implicit_arity] Atom("null", atom)
  and format_field = ((key, value)) => {
    let read_only_tag =
      switch Impl.read_only_tag {
      | Some(s) => s
      | None => ""
      };
    let prop = Format.sprintf("%s\"%s\":", read_only_tag, key);
    [@implicit_arity] Label(([@implicit_arity] Atom(prop, atom), label), format(value))
  }
  and format_list = (xs) => {
    let array_or_tuple = List.map(format, xs);
    if (is_array(array_or_tuple)) {
      switch array_or_tuple {
      | [] => raise(Unreachable)
      | [x, ..._] => [@implicit_arity] Atom(Pretty.to_string(x) ++ "[]", atom)
      }
    } else {
      [@implicit_arity] List(("[", ",", "]", list), array_or_tuple)
    }
  }
  and is_array =
    fun
    | [] => true
    | [x, ...xs] =>
      xs
      |> List.fold_left(
           ((before, is_array'), next) => (next, is_array' && before == next),
           (x, true)
         )
      |> (((_, x)) => x);
  let definition = Impl.definition(format);
  let definitions = Impl.definitions;
  let output_filename = (path, namespace) => {
    let filename = Filename.basename(path);
    switch (Filename.chop_extension(filename)) {
    | name => Format.sprintf("%s.%s.%s", name, namespace, Impl.extension)
    | exception _ => raise(Invalid_extension(None))
    }
  };
};
