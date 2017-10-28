declare namespace typed_i18n {
declare function t(_: "title"): string;
declare function t(_: "body_copies"): string[];
declare function t(_: "body_copies.[0]"): string;
declare function t(_: "body_copies.[1]"): string;
declare function t(_: "body_copies.[2]"): string;
declare function t(_: "support_tuple"): [ string, number, boolean ];
declare function t(_: "support_tuple.[0]"): string;
declare function t(_: "support_tuple.[1]"): number;
declare function t(_: "support_tuple.[2]"): boolean;
declare function t(_: "array_of_array"): number[][];
declare function t(_: "array_of_array.[0]"): number[];
declare function t(_: "array_of_array.[0].[0]"): number;
declare function t(_: "array_of_array.[0].[1]"): number;
declare function t(_: "array_of_array.[1]"): number[];
declare function t(_: "array_of_array.[1].[0]"): number;
declare function t(_: "array_of_array.[1].[1]"): number;
declare function t(_: "tuple_of_tuple"): [
  [ string, boolean, { readonly foo: string, readonly bar: null } ],
  [ string, boolean, number ]
];
declare function t(_: "tuple_of_tuple.[0]"): [ string, boolean, { readonly foo: string, readonly bar: null } ];
declare function t(_: "tuple_of_tuple.[0].[0]"): string;
declare function t(_: "tuple_of_tuple.[0].[1]"): boolean;
declare function t(_: "tuple_of_tuple.[0].[2]"): { readonly foo: string, readonly bar: null };
declare function t(_: "tuple_of_tuple.[0].[2].foo"): string;
declare function t(_: "tuple_of_tuple.[0].[2].bar"): null;
declare function t(_: "tuple_of_tuple.[1]"): [ string, boolean, number ];
declare function t(_: "tuple_of_tuple.[1].[0]"): string;
declare function t(_: "tuple_of_tuple.[1].[1]"): boolean;
declare function t(_: "tuple_of_tuple.[1].[2]"): number;
declare function t(_: "child"): {
  readonly title_of_child: string,
  readonly variable_types: {
    readonly key_of_int: number,
    readonly key_of_float: number,
    readonly key_of_boolean: boolean,
    readonly key_of_null: null
  }
};
declare function t(_: "child.title_of_child"): string;
declare function t(_: "child.variable_types"): {
  readonly key_of_int: number,
  readonly key_of_float: number,
  readonly key_of_boolean: boolean,
  readonly key_of_null: null
};
declare function t(_: "child.variable_types.key_of_int"): number;
declare function t(_: "child.variable_types.key_of_float"): number;
declare function t(_: "child.variable_types.key_of_boolean"): boolean;
declare function t(_: "child.variable_types.key_of_null"): null;
declare function t(_: "children"): { readonly first_name: string, readonly familly_name: string }[];
declare function t(_: "children.[0]"): { readonly first_name: string, readonly familly_name: string };
declare function t(_: "children.[0].first_name"): string;
declare function t(_: "children.[0].familly_name"): string;
declare function t(_: "children.[1]"): { readonly first_name: string, readonly familly_name: string };
declare function t(_: "children.[1].first_name"): string;
declare function t(_: "children.[1].familly_name"): string;
declare function t(_: "array_of_empty_object"): {}[];
declare function t(_: "array_of_empty_object.[0]"): {};

export type TFunction = typeof t
}