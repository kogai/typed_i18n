declare namespace typed_i18n {
  interface TFunction {
    (_: "title"): string;
    (_: "body_copies"): string[];
    (_: "body_copies.[0]"): string;
    (_: "body_copies.[1]"): string;
    (_: "body_copies.[2]"): string;
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
  }
  }
  
  export = typed_i18n;
  export as namespace typed_i18n;
  