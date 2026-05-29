# Card · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/card.ex`](../../lib/pulsar/components/card.ex)
**Tests:** [`test/pulsar/components/card_test.exs`](../../test/pulsar/components/card_test.exs)
**Audited:** 2026-05-24 (code-only)

Layout container with optional `media` / `header` / `footer` slots.
Renders as a static `<div>` by default, or as a keyboard-operable
pseudo-button (`role="button"`, `tabindex="0"`, hook-driven Space/Enter
activation) when a `phx-click` handler is provided.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Card renders no non-text content of its own; media / icon
content is supplied by the caller through slots —
`lib/pulsar/components/card.ex:350–356`. Callers are responsible for
`alt` text on images (e.g. test `<img src="/image.jpg" alt="Hero" />` —
`test/pulsar/components/card_test.exs:231`).

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Static card renders a plain `<div>`; interactive card adds
  `role="button"` — `lib/pulsar/components/card.ex:453`
- Card preserves caller-supplied heading levels and structure in
  `header` / `footer` / body slots —
  `lib/pulsar/components/card.ex:350–364`
- Tests verify slot heading rendering — `test/pulsar/components/card_test.exs:188–203, 416–436`

**Notes:** Card is a presentational container and does not wrap content
in extra semantic landmarks. Slot content keeps the structural intent
the caller chose.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Slots render in DOM order media → header → body → footer
matching their visual stacking — `lib/pulsar/components/card.ex:349–364`.

**Notes:** No flex direction reversal; body uses `flex-col` which keeps
top-down order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Variants (`solid` / `outline` / `ghost` / `elevated`) use
combinations of border + background + shadow — `lib/pulsar/components/card.ex:199–237`.
Interactive state adds `cursor-pointer` plus focus ring, not color
alone — `lib/pulsar/components/card.ex:428–435`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Card color encodes visual emphasis; no information is
conveyed by color alone. Interactive state combines `cursor-pointer`,
focus ring, and `role="button"` — `lib/pulsar/components/card.ex:428–435, 453`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Card renders no text of its own; text contrast is the
caller's responsibility for slot content. Background + border tokens
(`bg-surface-1`, `border-border`, etc.) come from the theme —
`lib/pulsar/components/card.ex:199–237`. Browser measurement of 72
cells per theme: all pass, min 15.93:1 (light) / 14.03:1 (dark)
([light](measurements/card-light.md),
[dark](measurements/card-dark.md)). The fixture's heading/body text
inside cards measures comfortably above 4.5:1 in both themes.

**Notes:** Card-on-page is a non-text-contrast concern (1.4.11), not
a text-contrast one. Caller-supplied text is out of scope.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** No fixed `px` font sizes or heights on the card itself;
padding is `rem`-based via Tailwind (`p-3` through `p-8`) —
`lib/pulsar/components/card.ex:155–186`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Card uses `block w-full overflow-hidden` —
`lib/pulsar/components/card.ex:190`. No `min-width` is enforced.

**Notes:** `overflow-hidden` on the card root means caller content that
exceeds the card width is clipped rather than producing horizontal page
scroll, which is consistent with 1.4.10.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS (decorative borders are out of scope)

**Evidence:**
- Outline variant border is `border-2` in the active color —
  `lib/pulsar/components/card.ex:218–226`
- Outline-neutral routes through `border-border-strong` —
  `lib/pulsar/components/card.ex:219`
- Solid variant border is at 20% opacity, except `solid-neutral`
  which now routes through `border-border-strong` —
  `lib/pulsar/components/card.ex:227–236`
- Interactive focus ring is `ring-2 ring-primary` —
  `lib/pulsar/components/card.ex:431–434`

Browser measurement of 36 border cells per theme: outline variants
all pass (`outline-neutral` 4.63:1 in both themes via
`--color-border-strong`). `solid-neutral` now passes (~5:1 via
`--color-border-strong`). Remaining failing cells are `solid-*`
(non-neutral) variants where the colored 20% alpha border resolves
below 3:1 against page background
([light](measurements/card-light.md),
[dark](measurements/card-dark.md)) — classified as decorative
(see Notes).

**Notes:** Per WCAG 1.4.11 understanding, decorative section
separators / container outlines that don't communicate state are
out of scope. The colored `solid-*` variants pair a tinted fill
(`bg-X/10`) with a slightly darker decorative border (`border-X/20`)
— the fill alone provides clear visual delineation against the
page background; the border is reinforcement decoration. State
(interactive vs static) is communicated by `role="button"`,
`tabindex`, hover/focus changes, and `cursor-pointer`, not by the
border. `solid-neutral` is the one case without a colored fill, so
its border IS the boundary — that variant now uses
`border-border-strong`.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed-height containers, no `!important` text-spacing
overrides. Card body uses `flex flex-col` with `gap-*` between children —
`lib/pulsar/components/card.ex:155–186`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- Interactive card gets `tabindex="0"` — `lib/pulsar/components/card.ex:454`
- Colocated `.PulsarCard` hook handles Space (keyup, prevents page
  scroll on keydown) and Enter to trigger `el.click()` —
  `lib/pulsar/components/card.ex:366–397`
- Test `adds keyboard activation hook for interactive cards` —
  `test/pulsar/components/card_test.exs:676–682`

**Notes:** Matches WAI-ARIA APG button activation pattern.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Hook listens only for Space/Enter; does not block Tab or
Shift+Tab — `lib/pulsar/components/card.ex:372–387`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Card transitions are `transition-colors duration-200`
only — `lib/pulsar/components/card.ex:191`. No looping motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing animation; only smooth color transition —
`lib/pulsar/components/card.ex:191`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Interactive card uses `tabindex="0"` (default order); no
positive tabindex anywhere — `lib/pulsar/components/card.ex:454`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Card preserves caller-supplied heading text in the
`header` slot without altering or wrapping the heading element —
`lib/pulsar/components/card.ex:354–356`. Tests confirm `<h3>` slot
content is rendered verbatim — `test/pulsar/components/card_test.exs:188–203`.

**Notes:** Caller is responsible for the heading text itself; the
component does not enforce hierarchy.

### 2.4.7 Focus Visible (AA) — ✓ PASS (inferred)

**Evidence:** Interactive card applies `focus-visible:outline-none`,
`focus-visible:ring-2`, `focus-visible:ring-primary`,
`dark:focus-visible:ring-dark-primary`, `focus-visible:ring-offset-2` —
`lib/pulsar/components/card.ex:430–434`. Test asserts these classes —
`test/pulsar/components/card_test.exs:665–674`. The card fixture
doesn't render interactive cards (the fixture is static cards), so
per-cell focus measurements are `not-focusable-in-state`.

**Notes:** Ring color `ring-primary` resolves to the same
`--color-primary` token as Button uses (5.02:1 / 6.72:1 measured
on Button). Inferred PASS by token symmetry.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Card does not create sticky or overlapping content. Single
container render.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Hook listens for `click` (mouseup-fired) for Enter, and
for `keyup` for Space — `lib/pulsar/components/card.ex:382–390`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Interactive card derives its accessible name from inner
content unless `aria-label` is passed; test demonstrates pass-through —
`test/pulsar/components/card_test.exs:641–654`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Interactive cards are full-width container elements
(`block w-full`, padding `p-3`+) — `lib/pulsar/components/card.ex:155–192`.
Total height vastly exceeds the 24×24 minimum.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No `phx-focus` or focus-triggered context change in the
component template — `lib/pulsar/components/card.ex:348–399`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Interactive card adds `role="button"` and `tabindex="0"` —
  `lib/pulsar/components/card.ex:453–454`
- Caller-supplied `role` is respected (uses `Map.put_new`) —
  `lib/pulsar/components/card.ex:452–455`
- Test `respects explicitly provided role attribute` —
  `test/pulsar/components/card_test.exs:612–625`

**Notes:** No state to expose beyond focus; static cards intentionally
have no role.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or popover.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — card is not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no multipoint/path gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.2 On Input (A)** — not a form input.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.3 Status Messages (AA)** — no status content emitted by the card itself.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — interactive card uses
  `ring-2` with `ring-offset-2`, which meets the minimum thickness and
  separation for AAA focus appearance. Contrast still needs browser
  verification.
- **2.5.5 Target Size (Enhanced) (AAA)** — interactive cards far exceed
  the 44×44 AAA target since they fill their grid cell.
