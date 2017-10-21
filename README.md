# typed_i18n

Produce safety type definition for i18n from json file.

```json
{
  "ja": {
    "title": "タイトル",
    "body_copies": [
      "これは",
      "本文",
      "です"
    ],
    "child": {
      "title_of_child": "サブタイトル",
      "variable_types": {
        "key_of_int": 999,
        "key_of_float": 999.999,
        "key_of_boolean": true,
        "key_of_null": null
      }
    },
    "children": [{
      "first_name": "太郎",
      "familly_name": "山田"
    }, {
      "first_name": "花子",
      "familly_name": "田中"
    }]
  }
}
```

```javascript
//@flow

declare function t(_: "title"): string;
declare function t(_: "body_copies"): [ string, string, string ];
declare function t(_: "body_copies.[0]"): string;
declare function t(_: "body_copies.[1]"): string;
declare function t(_: "body_copies.[2]"): string;
declare function t(_: "child"): {
  +title_of_child: string,
  +variable_types: {
    +key_of_int: number,
    +key_of_float: number,
    +key_of_boolean: boolean,
    +key_of_null: null
  }
};
declare function t(_: "child.title_of_child"): string;
declare function t(_: "child.variable_types"): {
  +key_of_int: number,
  +key_of_float: number,
  +key_of_boolean: boolean,
  +key_of_null: null
};
declare function t(_: "child.variable_types.key_of_int"): number;
declare function t(_: "child.variable_types.key_of_float"): number;
declare function t(_: "child.variable_types.key_of_boolean"): boolean;
declare function t(_: "child.variable_types.key_of_null"): null;
declare function t(_: "children"): [
  { +first_name: string, +familly_name: string },
  { +first_name: string, +familly_name: string }
];
declare function t(_: "children.[0]"): { +first_name: string, +familly_name: string };
declare function t(_: "children.[0].first_name"): string;
declare function t(_: "children.[0].familly_name"): string;
declare function t(_: "children.[1]"): { +first_name: string, +familly_name: string };
declare function t(_: "children.[1].first_name"): string;
declare function t(_: "children.[1].familly_name"): string;

 declare module.exports: {|
  +TFunction: typeof t;
|};
```
