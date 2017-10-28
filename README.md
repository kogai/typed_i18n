# typed_i18n

[![npm version](https://badge.fury.io/js/%40kogai%2Ftyped_i18n.svg)](https://badge.fury.io/js/%40kogai%2Ftyped_i18n)
[![CircleCI](https://circleci.com/gh/kogai/typed_i18n.svg?style=svg)](https://circleci.com/gh/kogai/typed_i18n)

Generate strictly typed definition of TFunction from own [i18next](https://github.com/i18next/i18next) dictionary file.

It generate from

```json
{
  "translation": {
    "foo": {
      "bar": "some text",
      "buzz": 999
    }
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

or

```typescript
declare namespace typed_i18n {
  interface TFunction {
    t(_: "foo"): {
      +bar: string,
      +buzz: number,
    };
    t(_: "foo.bar"): string;
    t(_: "foo.buzz"): number;
  }
}
export = typed_i18n;
export as namespace typed_i18n;
```

then if you use TFunction like below, type-checker warn you function call by invalid path

```javascript
// @flow

import type { TFunction } from './locale.translation'; // Definition file generated

declare var t: TFunction;

// Those are ok
const x: { bar: string, buzz: number } = t("foo")
const x1: string = x.bar;
const x2: number = x.buzz;
// Expect error
const x3 = x.buzzz;

// Expect error
const y = t("fooo")

// Those are also strictly typed too
const z1: string = t("foo.bar");
const z2: number = t("foo.buzz");
```

### Usage

```bash
# Basic usage
$ typed_i18n -i path/to/your.json -o path/to/out/dir

# You can specify namespaces instead of default "translation"
$ typed_i18n ... -n translate -n my-namespace -n  other-namespace
```
