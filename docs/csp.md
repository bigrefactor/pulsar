# Content Security Policy

Pulsar is designed to run under a strict Content-Security-Policy without
loosening `style-src`.

## Supported policy

    default-src 'self'; img-src 'self' data:

## What Pulsar does not require

**`style-src 'unsafe-inline'` is not required.** No Pulsar component renders an
inline `style` attribute. Dynamic values reach CSS as static utility classes, or
as SVG presentation attributes, which CSP does not govern. Every component
accepts `:global` attrs, and `style` is one of Phoenix's global attributes — a
caller who explicitly passes `style="…"` to a component still renders an inline
style attribute and reintroduces the violation.

A nonce would not have helped here: a `nonce-` value whitelists `<style>` and
`<script>` *elements*, not style *attributes*. Style attributes are governed by
`'unsafe-inline'`, or by `'unsafe-hashes'` plus a hash of each declaration.

**Runtime style mutation is permitted.** LiveView's own JavaScript sets inline
styles at runtime — `JS.show` and `JS.hide` set `display`, and Pulsar's resizable
hook sets a custom property as you drag. CSP governs style attributes in markup,
not scripted style mutation from an already-allowed script. One consequence:
`resizable`'s second panel renders at a fixed 30% until its hook mounts and
applies `default_size`, so a static render without JavaScript shows 30%
regardless of the configured `default_size`.

## What Pulsar does require

**`img-src 'self' data:`.** Heroicons are applied as CSS masks whose source is a
`data:` URI. Confirmed in a real browser: with `default-src 'self'` and no
`img-src`, Chrome blocks the `mask-image` load and logs `Loading the image
'data:image/svg+xml,…' violates the following Content Security Policy directive:
"default-src 'self'". Note that 'img-src' was not explicitly set, so 'default-src'
is used as a fallback.` The masked element renders with no visible content at
all — not an unmasked box, nothing. The same markup under `img-src 'self' data:`
renders the icon correctly. `mask-image` is fetched with an image destination,
same as `background-image`; the [Fetch Standard's destination table](https://fetch.spec.whatwg.org/#request-destinations)
and [MDN's `Sec-Fetch-Dest` reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Sec-Fetch-Dest)
describe the `image` destination as covering `<img>`, SVG `<image>`, and CSS
image-referencing properties generally (`background-image`, `cursor`,
`list-style-image`, "etc.") — CSP's `img-src` directive governs that
destination. Under `default-src 'self'` alone, every icon is blocked and
renders empty.

`data:` in `img-src` is a narrow allowance. It does not permit script execution
and is unrelated to the `'unsafe-inline'` relaxations above.

## Scripts

Pulsar ships colocated hooks, which LiveView bundles into your application's
JavaScript. Nothing is loaded from a third-party origin and no inline `<script>`
is emitted, so `script-src 'self'` — with a nonce if your app uses one — is
sufficient.
