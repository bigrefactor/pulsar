# Motion

Pulsar's motion is token-driven and consistent across components. Use these
utilities; do not hard-code durations or easings, and do not use `transition-all`.

## Tokens

**Durations** (`duration-*` utilities): `duration-fast` (120ms), `duration-normal`
(200ms), `duration-slow` (320ms).

**Easing** (`ease-*` utilities):

| Utility | Curve | Use |
|---|---|---|
| `ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` | in-place moves: hover, color, focus ring, size |
| `ease-decelerate` | `cubic-bezier(0, 0, 0.2, 1)` | entrances (fast → slow) |
| `ease-accelerate` | `cubic-bezier(0.4, 0, 1, 1)` | exits (slow → fast) |
| `ease-emphasized` | `cubic-bezier(0.05, 0.7, 0.1, 1)` | reserved for large surfaces (drawer, modal); use sparingly |

## The contract (interaction → duration + easing)

| Interaction | Duration | Easing |
|---|---|---|
| Micro — hover, focus ring, color, small size | `fast` | `standard` |
| Enter — overlay / menu / tooltip / flash appears | `normal` | `decelerate` |
| Exit — those disappear | `fast` | `accelerate` |
| Disclosure — drawer / accordion expand ↔ collapse | `normal` | `emphasized` |
| Large-surface enter — drawer / modal | `slow` | `emphasized` |
| Continuous — spinner, skeleton | — | `linear`, looped |

Principle: **exits are faster than entrances** — never make a user wait to dismiss.

## Rules

- **No `transition-all`.** Transition explicit properties: `transition-colors`,
  `transition-opacity`, `transition-[transform,box-shadow]`, etc.
- **Don't guard duration/animation per component.** A single global
  `@media (prefers-reduced-motion: reduce)` rule near-zeroes all transition and
  animation durations — you don't need `motion-reduce:transition-none` or
  `motion-reduce:animate-none` on individual components.
- **Do reset transform-based motion.** The global rule only zeroes durations; it
  does not undo a `transform`'s end state. If a component animates `transform`
  (e.g. `hover:scale-[1.02]`), keep a `motion-reduce:` guard that resets it
  (`motion-reduce:hover:scale-100`) — otherwise the scale still applies under
  reduced motion, just instantly.
- **No raw values.** Use the `duration-*` / `ease-*` utilities, never `duration-300`
  or `ease-in` directly.

## Entrance/exit helpers

For show/hide on overlays, pair the `ease-decelerate` (in) / `ease-accelerate` (out)
utilities with `Phoenix.LiveView.JS` transitions. (Standardized per-component
choreography is applied across the library as a follow-up pass.)
