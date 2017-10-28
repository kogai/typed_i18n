import { TFunction } from './locale.translation';

declare var t: TFunction;

// @ts-ignore
const x = t("invalid.string")
const y = t("children.[1].first_name")
const zs = t("body_copies")

// @ts-ignore
zs.map((z: number) => z)
