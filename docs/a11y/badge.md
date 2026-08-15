# Badge · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/badge.ex`](../../lib/pulsar/components/badge.ex)
**Tests:** [`test/pulsar/components/badge_test.exs`](../../test/pulsar/components/badge_test.exs)
**Audited:** 2026-08-15 (code-only)

Display marker and removable token — renders a `<span>` (or a `<div>` via
`as`) with variant (solid/outline/ghost), color, and size, plus optional
start/end addon slots and an optional built-in remove control (`on_remove`).

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Badge is text-first: `inner_block` is `required: true` —
`lib/pulsar/components/badge.ex`, `badge/1`. Addon slots are optional and
expected to contain icons (decorative by default via the Icon
component's `aria-hidden="true"` default). The built-in remove control's
`<svg>` is `aria-hidden="true"`, with the accessible name supplied by the
required `remove_label` — `lib/pulsar/components/badge.ex`, `badge/1`.

**Notes:** The badge body always carries text content; non-text addons
inherit the Icon component's hidden-by-default behavior, so the
accessible name comes from the inner text. `badge/1` raises when
`on_remove` is set without `remove_label`, so the icon-only dismiss
control cannot ship unnamed — `validate_remove!/2`; test
`test "raises when on_remove is set without remove_label"`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Single semantic `<span>`/`<div>` wrapping inline
addon/text/addon/remove flow — `lib/pulsar/components/badge.ex`, `badge/1`. No
grouping relationships to preserve.

**Notes:** Badge is a presentational marker; no implicit ARIA role is
required. Text content is exposed directly to AT.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order is `start_addon` → `inner_block` → `end_addon` →
remove control, matching visual `inline-flex items-center` order —
`lib/pulsar/components/badge.ex`, `base_badge_classes/0`, `badge/1`.

**Notes:** No `flex-direction: row-reverse` or absolute positioning.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Color variants are paired with required text content
(`inner_block` required at `lib/pulsar/components/badge.ex`, `badge/1`). Status
meaning (success/danger/warning) reaches AT through the text, not just
the color token.

**Notes:** Caller is responsible for writing meaningful text (e.g.,
"Completed" inside a success badge). The required-slot contract prevents
empty color-only badges.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Required `inner_block` (`lib/pulsar/components/badge.ex`, `badge/1`)
ensures text accompanies every color variant. The 7-color palette
(neutral/primary/secondary/success/danger/warning/info) is decorative
on top of the text label.

**Notes:** Code makes it impossible to ship a badge whose meaning is
conveyed by color alone.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Foreground/background colors come from semantic tokens
(`bg-*`/`text-*-foreground`, `text-*` for outline/ghost) —
`lib/pulsar/components/badge.ex`, `variant_color_classes/2`. Browser measurement of 91 cells
per theme — all pass, min 5.64:1 (light) / 4.84:1 (dark)
([light](measurements/badge-light.md),
[dark](measurements/badge-dark.md)).

**Notes:** The earlier success/warning and ghost/outline-neutral
shortfalls were resolved by the theme-token contrast work; every
variant × color now clears the 4.5:1 minimum (3:1 for large text).
The axe-core browser gate reports no `color-contrast` violation for
the Badge fixture in either theme.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All text classes use `rem`-based Tailwind tokens
(`text-xs`/`text-sm`/`text-base`/`text-lg`) and padding uses
`rem`-based spacing utilities — `lib/pulsar/components/badge.ex`, `size_classes/1`.
No fixed `px` heights constrain text.

**Notes:** Badge height is content-driven (padding only), so text
resizes without clipping.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` layout with no `min-width` or fixed widths —
`lib/pulsar/components/badge.ex`, `base_badge_classes/0`.

**Notes:** Badge sizes to its content and reflows at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Outline variant uses `border border-*` against
`bg-background` — `lib/pulsar/components/badge.ex`, `variant_color_classes/2`. The
`outline-neutral` variant routes through `border-border-strong` —
`lib/pulsar/components/badge.ex`, `variant_color_classes/2`. The control focus ring is
`[&>button]:focus-visible:ring-2 [&>button]:focus-visible:ring-current`
(and the `[&>a]` equivalent) — `lib/pulsar/components/badge.ex`,
`base_badge_classes/0`. Browser measurement: 30 cells
with measurable borders, all pass in both themes (min 4.63:1 light /
6.22:1 dark) ([light](measurements/badge-light.md),
[dark](measurements/badge-dark.md)).

**Notes:** `--color-border-strong` resolves to `gray-500` (light) /
`gray-400` (dark), giving the outline-neutral edge ≥4.5:1 against the
page background.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights; padding-only sizing
(`px-*`/`py-*`/`gap-*`) — `lib/pulsar/components/badge.ex`, `size_classes/1`. No
`!important` overrides on text spacing.

**Notes:** Badge adapts to user-overridden line-height/letter-spacing
because vertical size is driven by padding, not a fixed height.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** `[&>button]:focus-visible:outline-none
[&>button]:focus-visible:ring-2 [&>button]:focus-visible:ring-current`, and the
matching `[&>a]` rules — `lib/pulsar/components/badge.ex`,
`base_badge_classes/0`. The badge itself is not focusable; each control it
contains rings itself. A token carrying two controls (an interactive label and
a remove control) therefore shows which one holds focus, rather than ringing
the whole token for either. Measurement reads `not-focusable-in-state`
for every cell because the badge wrapper doesn't receive focus.

**Notes:** `ring-current` adopts the inherited text color. On solid
badges the ring color equals the foreground text color, which meets
4.5:1 against the badge background (1.4.3 measurement above) — that
satisfies the 3:1 non-text minimum by a wide margin in every cell.

The selectors are scoped to direct children (`>`), so a popover panel hosted
inside an `as={:div}` badge keeps its own focus styling for its own controls.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Badge is a single inline element that doesn't create
sticky or overlapping content — `lib/pulsar/components/badge.ex`, `badge/1`.

**Notes:** Page-level concern if badges sit in sticky toolbars; not a
component-level gap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The built-in remove control is a native `<button>` carrying
`phx-click={@on_remove}` — `lib/pulsar/components/badge.ex`, `badge/1`. Any
other interactive controls live in caller-provided slots and inherit their
own activation semantics (native buttons, etc.).

**Notes:** `phx-click` fires on mouseup, so a pointer-down that moves off
the control does not activate it.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The badge body is non-interactive, so 2.5.8 does not apply
to the wrapper `<span>` — the body-cell matrix still measures the `xs`
body at 20px (73/91 body cells ≥24×24; the 18 sub-floor cells are `xs`
bodies, which carry no pointer action). The *interactive* targets are the
built-in remove control rendered by `on_remove`, plus any caller-supplied
control in the default slot or in `start_addon`/`end_addon`
(`lib/pulsar/components/badge.ex`, `badge/1`). The badge root and both addon
wrappers size any direct `<button>`/`<a>` to a ≥24px floor
(`[&>button]:min-h-6 [&>button]:min-w-6`,
`lib/pulsar/components/badge.ex`, `base_badge_classes/0`), so both a
dismissible badge and a two-action token meet the floor even at `xs`.

**Notes:** A decorative addon (icon, status dot) is left untouched — only
interactive direct children are sized up, so the floor applies exactly
where 2.5.8 does. Caveat: the selector targets *direct* `<button>`/`<a>`
children; a control nested deeper inside custom slot markup should set
its own ≥24px target. That scoping is deliberate — it keeps the floor off
the contents of a popover panel an `as={:div}` badge hosts, which sets its
own targets.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Semantic `<span>` (or `<div>`) with no implicit role —
`lib/pulsar/components/badge.ex`, `badge/1`. Accessible name comes from inner
text content; `@rest` allows callers to pass `aria-label`, `id`, or
other ARIA properties — `lib/pulsar/components/badge.ex`, `badge/1`. The
built-in remove control is a native `<button type="button">` named by
`remove_label` — `lib/pulsar/components/badge.ex`, `badge/1`.

**Notes:** Test confirms global attribute pass-through —
`test "accepts global attributes"` —
`test/pulsar/components/badge_test.exs`. The wrapper has no state, so no
state attributes are needed. When the badge hosts a popover, `aria-expanded`
and `aria-controls` live on the caller's trigger button, wired by Popover —
real-browser coverage in
`test/integration/a11y/keyboard/badge_test.exs`.

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
- **2.1.1 Keyboard (A)** — badge wrapper is non-interactive.
- **2.1.2 No Keyboard Trap (A)** — badge wrapper is non-interactive.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no moving or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — only `transition-colors`, no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — badge wrapper is non-focusable; addon order matches DOM.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — not a heading or form label.
- **2.5.1 Pointer Gestures (A)** — no multipoint or path gestures.
- **2.5.3 Label in Name (A)** — no `aria_label` attr exposed by component.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — non-interactive wrapper.
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
- **4.1.3 Status Messages (AA)** — badge is static markup; status announcements are the caller's responsibility (e.g., wrap in `role="status"` region).

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — focus-within ring uses
  `ring-2` (2px) with `ring-offset-2`, meeting AAA minimum thickness.
  Ring uses `ring-current`; since 1.4.3 text contrast passes across
  every variant, the AAA focus-appearance contrast passes too.

## Browser a11y findings

The axe-core browser gate reports no violations for the Badge fixture
in either theme.
