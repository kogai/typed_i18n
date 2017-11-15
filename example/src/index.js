// @flow

import type { TFunction } from './locale.translation';
declare var t: TFunction;

// $ExpectError
const x = t("invalid.string")
const y = t("children.[1].first_name")
const zs = t("body_copies")
const can_receive_option = t("body_copies", {})

// $ExpectError
zs.map(z => (z: number))
