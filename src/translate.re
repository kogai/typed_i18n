exception Unreachable;

exception Invalid_extension(option(string));

module type Translatable = {
  type t;
  let extension: string;
  let read_only_tag: option(string);
  let definition: (Js.Json.t => Easy_format.t, t) => Easy_format.t;
  let definitions: list(Easy_format.t) => string;
};

module Translator =
       (Impl: Translatable)
       : (
           {
             type t;
             let format: Js.Json.t => Easy_format.t;
             let definition: t => Easy_format.t;
             let output_filename: (string, string) => string;
             let definitions: list(Easy_format.t) => string;
           } with
             type t = Impl.t
         ) => {
  open Easy_format;
  type t = Impl.t;
  let rec format = json =>
    switch (Js.Json.classify(json)) {
    | Js.Json.JSONObject(xs) =>
      let es = Js.Dict.entries(xs);
      if (Array.length(es) == 0) {
        Atom("{}", atom);
      } else {
        es
        |> Array.map(format_field)
        |> (xs => List(("{", ",", "}", list), Array.to_list(xs)));
      };
    | Js.Json.JSONArray(xs) => format_list(Array.to_list(xs))
    | Js.Json.JSONFalse
    | Js.Json.JSONTrue => Atom("boolean", atom)
    | Js.Json.JSONNumber(_) => Atom("number", atom)
    | Js.Json.JSONString(_) => Atom("string", atom)
    | Js.Json.JSONNull => Atom("null", atom)
    }
  and format_field = ((key, value)) => {
    let read_only_tag =
      switch (Impl.read_only_tag) {
      | Some(s) => s
      | None => ""
      };
    let prop = Format.sprintf("%s\"%s\":", read_only_tag, key);
    Label((Atom(prop, atom), label), format(value));
  }
  and format_list = xs => {
    let array_or_tuple = List.map(format, xs);
    if (is_array(array_or_tuple)) {
      switch (array_or_tuple) {
      | [] => raise(Unreachable)
      | [x, ..._] => Atom(Pretty.to_string(x) ++ "[]", atom)
      };
    } else {
      List(("[", ",", "]", list), array_or_tuple);
    };
  }
  and is_array =
    fun
    | [] => true
    | [x, ...xs] =>
      xs
      |> List.fold_left(
           ((before, is_array'), next) => (
             next,
             is_array' && before == next,
           ),
           (x, true),
         )
      |> (((_, x)) => x);
  let definition = Impl.definition(format);
  let definitions = Impl.definitions;
  let output_filename = (path, namespace) => {
    let filename = Filename.basename(path);
    switch (Filename.chop_extension(filename)) {
    | name => Format.sprintf("%s.%s.%s", name, namespace, Impl.extension)
    | exception _ => raise(Invalid_extension(None))
    };
  };
};
