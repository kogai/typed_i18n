# typed_i18n

[![npm version](https://badge.fury.io/js/%40kogai%2Ftyped_i18n.svg)](https://badge.fury.io/js/%40kogai%2Ftyped_i18n)

Generate strictly typed definition of TFunction from own i18next-locale file.
See [example](./example)

```bash
# Basic usage
$ typed_i18n -i path/to/your.json -o path/to/out/dir -p ja

# To use namespaces
$ typed_i18n ... -n translate -n my-namespace -n  other-namespace
```
