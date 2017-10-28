# typed_i18n

[![npm version](https://badge.fury.io/js/%40kogai%2Ftyped_i18n.svg)](https://badge.fury.io/js/%40kogai%2Ftyped_i18n)
[![CircleCI](https://circleci.com/gh/kogai/typed_i18n.svg?style=svg)](https://circleci.com/gh/kogai/typed_i18n)

Generate strictly typed definition of TFunction from own i18next-locale file.

It generate from

```json
{
  "foo": {
    "bar": "some text",
    "buzz": 999
  }
}
```

as

```javascript
// @flow

declare function t(_: "foo"): {
  +bar: string,
  +buzz: number,
};
declare function t(_: "foo.bar"): string;
declare function t(_: "foo.buzz"): number;

export type TFunction = typeof t
```

### Usage

```bash
# Basic usage
$ typed_i18n -i path/to/your.json -o path/to/out/dir -p ja

# To use namespaces
$ typed_i18n ... -n translate -n my-namespace -n  other-namespace
```
