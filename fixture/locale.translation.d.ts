declare namespace typed_i18n {
  interface TFunction {
  (_: "title", _?: {}): string; (_: "body_copies", _?: {}): string[];
  (_: "body_copies.[0]", _?: {}): string;
  (_: "body_copies.[1]", _?: {}): string;
  (_: "body_copies.[2]", _?: {}): string;
  (_: "support_tuple", _?: {}): [ string, number, boolean ];
  (_: "support_tuple.[0]", _?: {}): string;
  (_: "support_tuple.[1]", _?: {}): number;
  (_: "support_tuple.[2]", _?: {}): boolean;
  (_: "array_of_array", _?: {}): number[][];
  (_: "array_of_array.[0]", _?: {}): number[];
  (_: "array_of_array.[0].[0]", _?: {}): number;
  (_: "array_of_array.[0].[1]", _?: {}): number;
  (_: "array_of_array.[1]", _?: {}): number[];
  (_: "array_of_array.[1].[0]", _?: {}): number;
  (_: "array_of_array.[1].[1]", _?: {}): number;
  (_: "tuple_of_tuple", _?: {}): [
  [ string, boolean, { readonly "foo": string, readonly "bar": null } ],
  [ string, boolean, number ]
];
  (_: "tuple_of_tuple.[0]", _?: {}): [ string, boolean, { readonly "foo": string, readonly "bar": null } ];
  (_: "tuple_of_tuple.[0].[0]", _?: {}): string;
  (_: "tuple_of_tuple.[0].[1]", _?: {}): boolean;
  (_: "tuple_of_tuple.[0].[2]", _?: {}): { readonly "foo": string, readonly "bar": null };
  (_: "tuple_of_tuple.[0].[2].foo", _?: {}): string;
  (_: "tuple_of_tuple.[0].[2].bar", _?: {}): null;
  (_: "tuple_of_tuple.[1]", _?: {}): [ string, boolean, number ];
  (_: "tuple_of_tuple.[1].[0]", _?: {}): string;
  (_: "tuple_of_tuple.[1].[1]", _?: {}): boolean;
  (_: "tuple_of_tuple.[1].[2]", _?: {}): number;
  (_: "child", _?: {}): {
  readonly "title_of_child": string,
  readonly "variable_types": {
    readonly "key_of_int": number,
    readonly "key_of_float": number,
    readonly "key_of_boolean": boolean,
    readonly "key_of_null": null
  }
};
  (_: "child.title_of_child", _?: {}): string;
  (_: "child.variable_types", _?: {}): {
  readonly "key_of_int": number,
  readonly "key_of_float": number,
  readonly "key_of_boolean": boolean,
  readonly "key_of_null": null
};
  (_: "child.variable_types.key_of_int", _?: {}): number;
  (_: "child.variable_types.key_of_float", _?: {}): number;
  (_: "child.variable_types.key_of_boolean", _?: {}): boolean;
  (_: "child.variable_types.key_of_null", _?: {}): null;
  (_: "children", _?: {}): { readonly "first_name": string, readonly "familly_name": string }[];
  (_: "children.[0]", _?: {}): { readonly "first_name": string, readonly "familly_name": string };
  (_: "children.[0].first_name", _?: {}): string;
  (_: "children.[0].familly_name", _?: {}): string;
  (_: "children.[1]", _?: {}): { readonly "first_name": string, readonly "familly_name": string };
  (_: "children.[1].first_name", _?: {}): string;
  (_: "children.[1].familly_name", _?: {}): string;
  (_: "array_of_empty_object", _?: {}): {}[];
  (_: "array_of_empty_object.[0]", _?: {}): {};
  (_: "allow-comupted-properties", _?: {}): { readonly "0": string, readonly "foo-bar": boolean };
  (_: "allow-comupted-properties.0", _?: {}): string;
  (_: "allow-comupted-properties.foo-bar", _?: {}): boolean
}
}
export = typed_i18n;
