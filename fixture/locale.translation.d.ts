declare namespace typed_i18n {
  interface TFunction {
  (_: "title"): string; (_: "body_copies"): string[];
  (_: "body_copies.[0]"): string; (_: "body_copies.[1]"): string;
  (_: "body_copies.[2]"): string;
  (_: "support_tuple"): [ string, number, boolean ];
  (_: "support_tuple.[0]"): string; (_: "support_tuple.[1]"): number;
  (_: "support_tuple.[2]"): boolean; (_: "array_of_array"): number[][];
  (_: "array_of_array.[0]"): number[]; (_: "array_of_array.[0].[0]"): number;
  (_: "array_of_array.[0].[1]"): number; (_: "array_of_array.[1]"): number[];
  (_: "array_of_array.[1].[0]"): number;
  (_: "array_of_array.[1].[1]"): number;
  (_: "tuple_of_tuple"): [
  [ string, boolean, { readonly foo: string, readonly bar: null } ],
  [ string, boolean, number ]
];
  (_: "tuple_of_tuple.[0]"): [ string, boolean, { readonly foo: string, readonly bar: null } ];
  (_: "tuple_of_tuple.[0].[0]"): string;
  (_: "tuple_of_tuple.[0].[1]"): boolean;
  (_: "tuple_of_tuple.[0].[2]"): { readonly foo: string, readonly bar: null };
  (_: "tuple_of_tuple.[0].[2].foo"): string;
  (_: "tuple_of_tuple.[0].[2].bar"): null;
  (_: "tuple_of_tuple.[1]"): [ string, boolean, number ];
  (_: "tuple_of_tuple.[1].[0]"): string;
  (_: "tuple_of_tuple.[1].[1]"): boolean;
  (_: "tuple_of_tuple.[1].[2]"): number;
  (_: "child"): {
  readonly title_of_child: string,
  readonly variable_types: {
    readonly key_of_int: number,
    readonly key_of_float: number,
    readonly key_of_boolean: boolean,
    readonly key_of_null: null
  }
};
  (_: "child.title_of_child"): string;
  (_: "child.variable_types"): {
  readonly key_of_int: number,
  readonly key_of_float: number,
  readonly key_of_boolean: boolean,
  readonly key_of_null: null
};
  (_: "child.variable_types.key_of_int"): number;
  (_: "child.variable_types.key_of_float"): number;
  (_: "child.variable_types.key_of_boolean"): boolean;
  (_: "child.variable_types.key_of_null"): null;
  (_: "children"): { readonly first_name: string, readonly familly_name: string }[];
  (_: "children.[0]"): { readonly first_name: string, readonly familly_name: string };
  (_: "children.[0].first_name"): string;
  (_: "children.[0].familly_name"): string;
  (_: "children.[1]"): { readonly first_name: string, readonly familly_name: string };
  (_: "children.[1].first_name"): string;
  (_: "children.[1].familly_name"): string;
  (_: "array_of_empty_object"): {}[]; (_: "array_of_empty_object.[0]"): {}
}
}
export = typed_i18n;
export as namespace typed_i18n;
