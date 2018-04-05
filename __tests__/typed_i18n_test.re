open Jest;

open Expect;

open! Expect.Operators;

describe("Expect", () =>
  Expect.(test("toBe", () =>
            expect(1 + 2) |> toBe(3)
          ))
);

describe("Expect.Operators", () =>
  test("==", () =>
    expect(1 + 2) === 3
  )
);

describe("Utils", () => {
  let json =
    Json.Encode.(object_([("a", string("a")), ("b", string("b"))]));
  test("find member", () =>
    expect(Utils.member("a", json)) === Json.Encode.(string("a"))
  );
});
