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

then if you use TFunction like below, type-checker warn you function call by invalid path

```javascript
// @flow

import type { TFunction } from './locale.translation'; // Definition file generated

declare var t: TFunction;

// It is ok
const x = t("foo")

// Expect error
const y = t("fooo")

// Those are also strictly typed too
const z1: string = t("foo.bar");
const z2: number = t("foo.buzz");
const z3: string = x.bar;
const z4: number = x.buzz;
```

### Usage

```bash
# Basic usage
$ typed_i18n -i path/to/your.json -o path/to/out/dir

# You can specify namespaces instead of default "translation"
$ typed_i18n ... -n translate -n my-namespace -n  other-namespace
```
