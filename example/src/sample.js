// @flow
import type { TFunction } from './locale.translate';

declare var t: TFunction;

const x = t("invalid.string") // ExpectError
const y = t("children.[1].first_name")
const zs = t("body_copies")

zs.map(z => (z: number)) // ExpectError
