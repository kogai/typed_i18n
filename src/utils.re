let rec range = (from, to_) =>
  if (from > to_) {
    []
  } else {
    [from, ...range(from + 1, to_)]
  };

let with_idx = (xs) => List.combine(range(0, List.length(xs) - 1), xs);

let find = (p, xs) =>
  try (Some(List.find(p, xs))) {
  | Not_found => None
  };

let rec last_exn =
  fun
  | [] => raise(Not_found)
  | [x] => x
  | [_, ...xs] => last_exn(xs);
