# Badge · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/badge.ex`](../../lib/pulsar/components/badge.ex)
**Tests:** [`test/pulsar/components/badge_test.exs`](../../test/pulsar/components/badge_test.exs)
**Audited:** 2026-05-24 (code-only)

Non-interactive display marker — renders a `<span>` with variant
(solid/outline/ghost), color, and size, plus optional start/end addon
slots for icons or interactive controls.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Badge is text-first: `inner_block` is `required: true` —
`lib/pulsar/components/badge.ex:152`. Addon slots are optional and
expected to contain icons (decorative by default via the Icon
component's `aria-hidden="true"` default).

**Notes:** The badge body always carries text content; non-text addons
inherit the Icon component's hidden-by-default behavior, so the
accessible name comes from the inner text.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Single semantic `<span>` wrapping inline addon/text/addon
flow — `lib/pulsar/components/badge.ex:167–173`. No grouping
relationships to preserve.

**Notes:** Badge is a presentational marker; no implicit ARIA role is
required. Text content is exposed directly to AT.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order is `start_addon` → `inner_block` → `end_addon`,
matching visual `inline-flex items-center` order —
`lib/pulsar/components/badge.ex:82, 168–172`.

**Notes:** No `flex-direction: row-reverse` or absolute positioning.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Color variants are paired with required text content
(`inner_block` required at `lib/pulsar/components/badge.ex:152`). Status
meaning (success/danger/warning) reaches AT through the text, not just
the color token.

**Notes:** Caller is responsible for writing meaningful text (e.g.,
"Completed" inside a success badge). The required-slot contract prevents
empty color-only badges.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Required `inner_block` (`lib/pulsar/components/badge.ex:152`)
ensures text accompanies every color variant. The 7-color palette
(neutral/primary/secondary/success/danger/warning/info) is decorative
on top of the text label.

**Notes:** Code makes it impossible to ship a badge whose meaning is
conveyed by color alone.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Foreground/background colors come from semantic tokens
(`bg-*`/`text-*-foreground`, `text-*` for outline/ghost) —
`lib/pulsar/components/badge.ex:89–125`. Browser measurement of 91 cells
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
`rem`-based spacing utilities — `lib/pulsar/components/badge.ex:72–78`.
No fixed `px` heights constrain text.

**Notes:** Badge height is content-driven (padding only), so text
resizes without clipping.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` layout with no `min-width` or fixed widths —
`lib/pulsar/components/badge.ex:82`.

**Notes:** Badge sizes to its content and reflows at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Outline variant uses `border border-*` against
`bg-background` — `lib/pulsar/components/badge.ex:99–114`. The
`outline-neutral` variant routes through `border-border-strong` —
`lib/pulsar/components/badge.ex:113`. Focus-within ring is
`focus-within:ring-2 focus-within:ring-current focus-within:ring-offset-2`
— `lib/pulsar/components/badge.ex:84–85`. Browser measurement: 30 cells
with measurable borders, all pass in both themes (min 4.63:1 light /
6.22:1 dark) ([light](measurements/badge-light.md),
[dark](measurements/badge-dark.md)).

**Notes:** `--color-border-strong` resolves to `gray-500` (light) /
`gray-400` (dark), giving the outline-neutral edge ≥4.5:1 against the
page background.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights; padding-only sizing
(`px-*`/`py-*`/`gap-*`) — `lib/pulsar/components/badge.ex:72–78`. No
`!important` overrides on text spacing.

**Notes:** Badge adapts to user-overridden line-height/letter-spacing
because vertical size is driven by padding, not a fixed height.

### 2.4.7 Focus Visible (AA) — ✓ PASS (caller-driven)

**Evidence:** `focus-within:outline-none focus-within:ring-2
focus-within:ring-current focus-within:ring-offset-2` —
`lib/pulsar/components/badge.ex:84–85`. The badge itself is not
focusable; the ring appears when a focusable addon child (e.g., a
remove button) is focused. Measurement reads `not-focusable-in-state`
for every cell because the wrapping `<span>` doesn't receive focus.

**Notes:** `ring-current` adopts the inherited text color. On solid
badges the ring color equals the foreground text color, which meets
4.5:1 against the badge background (1.4.3 measurement above) — that
satisfies the 3:1 non-text minimum by a wide margin in every cell.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Badge is a single inline element that doesn't create
sticky or overlapping content — `lib/pulsar/components/badge.ex:167–173`.

**Notes:** Page-level concern if badges sit in sticky toolbars; not a
component-level gap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Badge itself has no click handlers. Any interactive
controls live in caller-provided `start_addon`/`end_addon` slots and
inherit their own activation semantics (native buttons, etc.).

**Notes:** Sample usage in module docs (`lib/pulsar/components/badge.ex:32–53`)
uses `<button phx-click="...">` which fires on mouseup.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — xs size below floor

**Evidence:** Badge body is non-interactive (N/A for the wrapper).
Interactive addon controls are caller-supplied via the
`start_addon`/`end_addon` slots — `lib/pulsar/components/badge.ex:153–154`.
The xs/sm sizes use small padding (`py-0.5`,
`lib/pulsar/components/badge.ex:74–77`). Browser measurement: 73/91
cells pass ≥ 24×24; 18 fail. All failures are `xs` size cells —
they render at 20px height. `sm`, `md`, `lg`, `xl` all pass.

**Notes:** Badge is non-interactive on its own, so 2.5.8 doesn't
strictly apply to the wrapper. However, if a caller adds a
`<button>` to `end_addon` to make a dismissible badge, the addon
inherits the badge's height — at `xs` (20 px) the addon falls below
the 24×24 floor. WCAG 2.5.8 spacing exception applies for inline
controls, but Badge `xs` is intentionally a "label, never
interactive" size. Document this in the Badge usage docs;
component-level fix not required.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Semantic `<span>` with no implicit role —
`lib/pulsar/components/badge.ex:168`. Accessible name comes from inner
text content; `@rest` allows callers to pass `aria-label`, `id`, or
other ARIA properties — `lib/pulsar/components/badge.ex:150, 168`.

**Notes:** Test confirms global attribute pass-through —
`test/pulsar/components/badge_test.exs:191–197`. Badge has no state, so
no state attributes are needed.

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
