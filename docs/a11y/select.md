# Select · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/select.ex`](../../lib/pulsar/components/select.ex)
**Tests:** [`test/pulsar/components/select_test.exs`](../../test/pulsar/components/select_test.exs)
**Audited:** 2026-05-24 (code-only)

Native `<select>` leaf with variants/sizes, multi-select badge display
with per-badge remove buttons, and a colocated JS hook to deselect
options via a `pulsar:remove-selection` event.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Custom chevron icon is rendered in a `pointer-events-none` div without
  an accessible name; semantically decorative —
  `lib/pulsar/components/select.ex:384–390`
- Badge remove button uses `hero-x-mark` icon with explicit
  `aria-hidden="true"` and the button itself has
  `aria-label="Remove #{option.label}"` —
  `lib/pulsar/components/select.ex:351, 353`
- Test `badge close buttons have aria-label for accessibility` —
  `test/pulsar/components/select_test.exs:592–610`

**Notes:** Decorative chevron + labeled remove control match the
correct pattern.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<select>` element carries semantic role —
  `lib/pulsar/components/select.ex:361`
- `aria-invalid` and `aria-describedby` pass through from caller —
  `lib/pulsar/components/select.ex:368–369`
- Option groups render as `<optgroup>` via Phoenix's
  `Form.options_for_select` — `lib/pulsar/components/select.ex:580–583`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: badges (if any) → select wrapper → arrow icon —
`lib/pulsar/components/select.ex:323–391`. Matches visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Error state combines danger color + `aria-invalid` —
`lib/pulsar/components/select.ex:369`. Disabled state combines opacity +
cursor + native `disabled` — `lib/pulsar/components/select.ex:469–475`.

### 1.3.5 Identify Input Purpose (AA) — ✓ PASS

**Evidence:** `:rest` is `:global`, allowing `autocomplete=` pass-through —
`lib/pulsar/components/select.ex:270, 375`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state pairs color with `aria-invalid="true"` —
`lib/pulsar/components/select.ex:369`. Disabled state combines opacity +
`cursor-not-allowed` + native `disabled` —
`lib/pulsar/components/select.ex:469–475`.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious, [PUL-39](https://linear.app/bigrefactor/issue/PUL-39/select-fix-axe-color-contrast-violation))

**Evidence:** Color/variant matrix with semantic tokens —
`lib/pulsar/components/select.ex:127–179`. Arrow color tracks the field
color — `lib/pulsar/components/select.ex:182–190`. Browser measurement
of 289 cells per theme:

- **Dark:** 276/289 pass (min 3.31:1). 13 failures cluster around
  `multi` and `solid-neutral`.
- **Light:** 169/289 pass (min 2.74:1). 120 failures span ghost/
  outline-success/warning and the entire `solid-*` family.

[Light](measurements/select-light.md), [dark](measurements/select-dark.md).

**Notes:** Existing [PUL-39](https://linear.app/bigrefactor/issue/PUL-39)
scoped to "success outline variant"; expand to cover the warning
variant and the solid family in light theme — same defect pattern
as Input and Textarea, addressed by the same upstream token fix.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Min-heights use rem-based `min-h-*` —
`lib/pulsar/components/select.ex:99–105`. Padding/text classes rem.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Select uses `block w-full` —
`lib/pulsar/components/select.ex:117`. Badge container wraps with
`flex-wrap` — `lib/pulsar/components/select.ex:337`.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (serious, PUL-19 follow-up: select-outline-border-contrast)

**Evidence:** Outline variant uses `border-2` —
`lib/pulsar/components/select.ex:122`. Focus ring `focus:ring-2
focus:ring-offset-2` — `lib/pulsar/components/select.ex:117`. Badge
remove button has `focus-visible:ring-1` —
`lib/pulsar/components/select.ex:350`. Browser measurement of 96
outline cells: light 36/96 pass (min 1.18:1), dark 48/96 pass
(min 1.21:1). Failing outline colors in light:
`outline-neutral`, `outline-primary`, `outline-secondary`,
`outline-success`, `outline-warning` — virtually every color
variant's outline border is below 3:1. Focus ring: 217 cells, light
112/217 pass (min 1.95:1), dark 112/217 pass (min 2.11:1). Many
focus rings undershoot.

**Notes:** New finding — `select-outline-border-contrast` to be
filed as a Linear sub-issue parented to PUL-19. The `border-*-300`
shades used by the select outline variant don't meet 3:1. Focus
ring failures are an additional concern: light variants use
`--color-{color}-300` for the focus ring which is the same low-
contrast token as the border. Both stem from one root cause — the
`*-300` shade in the light palette is too light for non-text use.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** `min-h-*` (not `h-*`) allows growth —
`lib/pulsar/components/select.ex:99–105`. Browser test injects the
WCAG overrides and re-measures: 0 cells overflow
([light](measurements/select-light.md#text-spacing-override-wcag-1412),
[dark](measurements/select-dark.md#text-spacing-override-wcag-1412)).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<select>` is fully keyboard-operable —
`lib/pulsar/components/select.ex:361–376`. Badge remove buttons are
native `<button type="button">` with Phoenix click handlers —
`lib/pulsar/components/select.ex:346–354`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No custom keydown handlers; native select Tab behavior.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only smooth color transitions
(`transition-all duration-200 ease-in-out`) —
`lib/pulsar/components/select.ex:117`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing animations.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`. Badge remove buttons are
keyboard-reachable in DOM order before the select itself, matching
visual order — `lib/pulsar/components/select.ex:337–356`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Label is caller's responsibility via `field` wrapper.
Per-badge remove buttons have `aria-label="Remove …"` —
`lib/pulsar/components/select.ex:351`.

### 2.4.7 Focus Visible (AA) — ⚠ GAP (serious, PUL-19 follow-up: select-outline-border-contrast)

**Evidence:** Select has `focus:ring-2 focus:ring-offset-2` —
`lib/pulsar/components/select.ex:117`. Remove button has
`focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-current` —
`lib/pulsar/components/select.ex:350`. Browser measurement: focus ring
contrast varies by variant — neutral resolves to the standard
`--color-ring` token (5.02:1 light / 6.72:1 dark, pass), but colored
variants (primary/success/warning/etc.) use their color's `-300`
shade as the ring color, which falls below 3:1 in light theme.
Specifically: ghost / outline / solid variants in primary/secondary/
success/warning/danger colors fail the 3:1 ring contrast in light.

**Notes:** Same root cause as the 1.4.11 finding above — fix is to
either bump colored focus rings to a darker shade or use the neutral
`--color-ring` token for all variants. Remove button `ring-1` (1px)
is below AAA but meets AA when contrast is adequate; not flagged
separately.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Inline render; no sticky overlap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native `<select>` interaction; remove buttons use
`phx-click` which fires on click (mouseup) —
`lib/pulsar/components/select.ex:348`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Remove button `aria-label` is built from the option label
(`"Remove #{option.label}"`) — `lib/pulsar/components/select.ex:351`.
Visible text "Remove" + option name are reflected in the accessible
name (where the X icon is the visible identifier, the aria-label
expands it).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Select `xs` is `min-h-6` (24px) exactly at floor —
`lib/pulsar/components/select.ex:104`. Badge remove button has `p-0.5`
padding around an `xs` icon — `lib/pulsar/components/select.ex:350, 353`.
Browser measurement of 289 cells: 289/289 pass ≥ 24×24
([light](measurements/select-light.md),
[dark](measurements/select-dark.md)). The remove button receives the
WCAG spacing exception (inline control in a badge with surrounding
gap).

**Notes:** The remove button at `p-0.5` around an `xs` icon renders
≈24×24 due to padding contribution; combined with the spacing
exception, it meets AA.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler in the component template.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-change` to the select, but no
navigation/submit on input from the component itself —
`lib/pulsar/components/select.ex:270, 375`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid={@invalid && "true"}` reflects errors —
`lib/pulsar/components/select.ex:369`. Test asserts presence —
`test/pulsar/components/select_test.exs:773–795`.

**Notes:** `aria-invalid` is *omitted* when there are no errors (rather
than set to `"false"`), which is intentional to reduce screen reader
noise — see test `omits aria-invalid when field has no errors (reduces
noise)` — `test/pulsar/components/select_test.exs:796–818`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label is caller's responsibility via `field` wrapper.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Select doesn't suppress error text; rendering happens at
the `field` wrapper level.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: native `<select>` (with `multiple` as appropriate) —
  `lib/pulsar/components/select.ex:361–364`
- Name: from `name=` attr (array-suffixed for multi-select) —
  `lib/pulsar/components/select.ex:362, 589–598`
- Value: rendered via `Form.options_for_select` —
  `lib/pulsar/components/select.ex:380`
- State: `aria-invalid`, native `required`/`disabled`/`multiple` —
  `lib/pulsar/components/select.ex:365–369`
- Tests assert `data-required`, `data-multiple`, etc. —
  `test/pulsar/components/select_test.exs:903–928`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` reflects validation state —
`lib/pulsar/components/select.ex:369`. Field-level error region carries
`aria-live="polite"`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip/popover; native
  option list is browser-rendered.
- **2.1.4 Character Key Shortcuts (A)** — none registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.4 Motion Actuation (A)** — none.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `lg` (`min-h-12`=48px)
  and `xl` (`min-h-14`=56px) exceed the AAA 44×44 floor. Smaller sizes
  do not.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `select-name` | unlabelled selects in fixture | both | [PUL-38](https://linear.app/bigrefactor/issue/PUL-38/select-fix-axe-select-name-violation) |
| `color-contrast` | success outline variant | both | [PUL-39](https://linear.app/bigrefactor/issue/PUL-39/select-fix-axe-color-contrast-violation) |
