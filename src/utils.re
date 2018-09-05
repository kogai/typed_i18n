let rec range = (from, to_) =>
  if (from > to_) {
    [];
  } else {
    [from, ...range(from + 1, to_)];
  };

let with_idx = xs => List.combine(range(0, List.length(xs) - 1), xs);

let find = (p, xs) =>
  try (Some(List.find(p, xs))) {
  | Not_found => None
  };

let rec last_exn =
  fun
  | [] => raise(Not_found)
  | [x] => x
  | [_, ...xs] => last_exn(xs);

let member = (key: string, json: Js.Json.t) : Js.Json.t => {
  let mem = k =>
    fun
    | Js.Json.JSONObject(xs) =>
      switch (Js.Dict.get(xs, k)) {
      | Some(x) => x
      | None => raise(Not_found)
      }
    | Js.Json.JSONArray(xs) =>
      try (xs[int_of_string(k)]) {
      | Invalid_argument(_) => raise(Not_found)
      }
    | JSONFalse => Js.Json.boolean(false)
    | JSONTrue => Js.Json.boolean(true)
    | JSONNull => Js.Json.null
    | JSONNumber(x) => Js.Json.number(x)
    | JSONString(x) => Js.Json.string(x);
  mem(key, Js.Json.classify(json));
};
