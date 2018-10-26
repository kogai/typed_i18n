declare namespace typed_i18n {
  interface TFunction {
  (_: "title", __?: {}): string; (_: "interpolation", __?: {}): string;
  (_: "body_copies", __?: {}): string[];
  (_: "body_copies.[0]", __?: {}): string;
  (_: "body_copies.[1]", __?: {}): string;
  (_: "body_copies.[2]", __?: {}): string;
  (_: "support_tuple", __?: {}): [ string, number, boolean ];
  (_: "support_tuple.[0]", __?: {}): string;
  (_: "support_tuple.[1]", __?: {}): number;
  (_: "support_tuple.[2]", __?: {}): boolean;
  (_: "array_of_array", __?: {}): number[][];
  (_: "array_of_array.[0]", __?: {}): number[];
  (_: "array_of_array.[0].[0]", __?: {}): number;
  (_: "array_of_array.[0].[1]", __?: {}): number;
  (_: "array_of_array.[1]", __?: {}): number[];
  (_: "array_of_array.[1].[0]", __?: {}): number;
  (_: "array_of_array.[1].[1]", __?: {}): number;
  (_: "tuple_of_tuple", __?: {}): [
  [ string, boolean, { readonly "foo": string, readonly "bar": null } ],
  [ string, boolean, number ]
];
  (_: "tuple_of_tuple.[0]", __?: {}): [ string, boolean, { readonly "foo": string, readonly "bar": null } ];
  (_: "tuple_of_tuple.[0].[0]", __?: {}): string;
  (_: "tuple_of_tuple.[0].[1]", __?: {}): boolean;
  (_: "tuple_of_tuple.[0].[2]", __?: {}): { readonly "foo": string, readonly "bar": null };
  (_: "tuple_of_tuple.[0].[2].foo", __?: {}): string;
  (_: "tuple_of_tuple.[0].[2].bar", __?: {}): null;
  (_: "tuple_of_tuple.[1]", __?: {}): [ string, boolean, number ];
  (_: "tuple_of_tuple.[1].[0]", __?: {}): string;
  (_: "tuple_of_tuple.[1].[1]", __?: {}): boolean;
  (_: "tuple_of_tuple.[1].[2]", __?: {}): number;
  (_: "child", __?: {}): {
  readonly "title_of_child": string,
  readonly "variable_types": {
    readonly "key_of_int": number,
    readonly "key_of_float": number,
    readonly "key_of_boolean": boolean,
    readonly "key_of_null": null
  }
};
  (_: "child.title_of_child", __?: {}): string;
  (_: "child.variable_types", __?: {}): {
  readonly "key_of_int": number,
  readonly "key_of_float": number,
  readonly "key_of_boolean": boolean,
  readonly "key_of_null": null
};
  (_: "child.variable_types.key_of_int", __?: {}): number;
  (_: "child.variable_types.key_of_float", __?: {}): number;
  (_: "child.variable_types.key_of_boolean", __?: {}): boolean;
  (_: "child.variable_types.key_of_null", __?: {}): null;
  (_: "children", __?: {}): { readonly "first_name": string, readonly "familly_name": string }[];
  (_: "children.[0]", __?: {}): { readonly "first_name": string, readonly "familly_name": string };
  (_: "children.[0].first_name", __?: {}): string;
  (_: "children.[0].familly_name", __?: {}): string;
  (_: "children.[1]", __?: {}): { readonly "first_name": string, readonly "familly_name": string };
  (_: "children.[1].first_name", __?: {}): string;
  (_: "children.[1].familly_name", __?: {}): string;
  (_: "array_of_empty_object", __?: {}): {}[];
  (_: "array_of_empty_object.[0]", __?: {}): {};
  (_: "allow-comupted-properties", __?: {}): { readonly "0": string, readonly "foo-bar": boolean };
  (_: "allow-comupted-properties.0", __?: {}): string;
  (_: "allow-comupted-properties.foo-bar", __?: {}): boolean
}
}
export = typed_i18n;
