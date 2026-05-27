# Switch · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/switch.ex`](../../lib/pulsar/components/switch.ex)
**Tests:** [`test/pulsar/components/switch_test.exs`](../../test/pulsar/components/switch_test.exs)
**Audited:** 2026-05-24 (code-only)

iOS-style toggle implemented as a visually-hidden native
`<input type="checkbox" role="switch">` (the real keyboard target) paired
with a decorative visual track `<button tabindex="-1">` that re-dispatches
clicks to the input. Optional loading state with spinner.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Loading spinner SVG has `aria-hidden="true"` —
`lib/pulsar/components/switch.ex:525`. The visual track button has
`tabindex="-1"` so AT doesn't see it as a separate control —
`lib/pulsar/components/switch.ex:507`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Real input has explicit `role="switch"` —
  `lib/pulsar/components/switch.ex:496`
- `aria-checked` reflects state explicitly —
  `lib/pulsar/components/switch.ex:497`
- Test `renders role="switch" on the input` —
  `test/pulsar/components/switch_test.exs:276–281`
- Test `renders aria-checked` —
  `test/pulsar/components/switch_test.exs:283–299`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: hidden companion → real input → visual track →
thumb. Visual order matches DOM order —
`lib/pulsar/components/switch.ex:478–547`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** State change combines color shift + thumb translation +
`aria-checked` value flip — `lib/pulsar/components/switch.ex:104–127, 497`.
Disabled combines opacity + cursor + native `disabled` —
`lib/pulsar/components/switch.ex:240`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** On/off is signaled by thumb position (not color alone) —
`lib/pulsar/components/switch.ex:105, 110, 115, 120, 125`. Invalid is
`ring-danger` plus `aria-invalid="true"` —
`lib/pulsar/components/switch.ex:500, 635`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Color matrix for 7 colors × 3 variants —
`lib/pulsar/components/switch.ex:131–230`. Browser measurement of 120
cells per theme: all pass, min 19.27:1 (light) / 16.98:1 (dark)
([light](measurements/switch-light.md),
[dark](measurements/switch-dark.md)).

**Notes:** Switch has no text content; the measurement traces text on
the wrapper label against the page background. Track/thumb colors
are non-text and covered under 1.4.11.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Track/thumb sizes use rem-based Tailwind classes
(`h-3.5`, `h-7`, etc.) — `lib/pulsar/components/switch.ex:102–127`.

**Notes:** Thumb translation distances are written in pixel custom
values (e.g., `translate-x-[24px]`) — `lib/pulsar/components/switch.ex:110`.
These don't affect text resizing but won't scale to ems.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` wrapper — `lib/pulsar/components/switch.ex:479`.
No fixed widths.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (serious, PUL-19 follow-up: switch-dark-focus-indicator)

**Evidence:**
- Track has `shadow-inner` + variant-specific bg —
  `lib/pulsar/components/switch.ex:242–243`
- Focus ring `focus-visible:ring-2 focus-visible:ring-offset-2` on the
  input — `lib/pulsar/components/switch.ex:237`
- Thumb has shadow rings —
  `lib/pulsar/components/switch.ex:621, 625, 629`

Browser measurement: focus indicator detection finds the
`peer-focus-visible:` border on the track (not the `sr-only` input
itself). Light theme: 96/96 pass focus ring contrast (5.73:1). Dark
theme: 0/96 pass — the peer-focus border resolves to 2.97:1 across
all 24 color×size cells, just below the 3:1 floor.

**Notes:** New finding — `switch-dark-focus-indicator` to be filed
as a Linear sub-issue parented to PUL-19. The dark-mode focus
indicator border color is one step too light against the dark
track background. Fix is to bump the `peer-focus-visible:border-*`
token to a brighter shade in dark mode (e.g. `border-dark-primary`
→ `border-dark-primary-300`).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Track has fixed `h-*` — `lib/pulsar/components/switch.ex:104–127`.
No text inside the switch itself. Browser test injects the WCAG
overrides and re-measures: 0 cells overflow
([light](measurements/switch-light.md#text-spacing-override-wcag-1412),
[dark](measurements/switch-dark.md#text-spacing-override-wcag-1412)).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Real input is a native checkbox with `role="switch"`,
keyboard-toggleable via Space — `lib/pulsar/components/switch.ex:488–502`.
Visual track has `tabindex="-1"` so it's not in the tab order —
`lib/pulsar/components/switch.ex:507`. Clicks on the visual track
dispatch a click to the real input —
`lib/pulsar/components/switch.ex:508`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No custom keydown handler; native checkbox Tab behavior
preserved.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Loading spinner uses `animate-spin` (essential per WCAG
exemption) — `lib/pulsar/components/switch.ex:526`. Thumb position
transition is a smooth 200ms color/transform —
`lib/pulsar/components/switch.ex:235, 249`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only smooth transitions and `animate-spin` (continuous
rotation, not flash).

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Real input is `sr-only peer`; tabindex is the browser
default (0). Visual track is `tabindex="-1"`. No positive tabindex —
`lib/pulsar/components/switch.ex:493, 507`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Switch accepts `aria_label` and `aria_labelledby`
attributes — `lib/pulsar/components/switch.ex:376–384, 498–499`. The
`field` wrapper provides the visible label and passes it via inline
`<label for=>` for the switch type.

### 2.4.7 Focus Visible (AA) — ⚠ GAP (serious, PUL-19 follow-up: switch-dark-focus-indicator)

**Evidence:** Real input is `sr-only`, so its native focus ring is
invisible. Visual feedback uses `peer-focus-visible:bg-*` and
`peer-focus-visible:border-*` on the track —
`lib/pulsar/components/switch.ex:573, 585, 596`, plus
`peer-focus-visible:scale-110` on the thumb —
`lib/pulsar/components/switch.ex:255`.

Light theme passes (5.73:1). Dark theme fails (2.97:1) — same
defect documented under 1.4.11 above.

**Notes:** Both criteria resolved by `switch-dark-focus-indicator`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Inline render; no sticky overlap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native checkbox click; visual track uses
`phx-click={JS.dispatch("click", to: ...)}` which fires on click
(mouseup) — `lib/pulsar/components/switch.ex:508`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** `aria_label` is supported but optional. When `field`
provides an inline `<label>`, the accessible name comes from that visible
text — `lib/pulsar/components/field.ex:406–432`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — per WCAG spacing exception

**Evidence:** Track sizes: `xs`=14×28px, `sm`=16×36px, `md`=20×44px,
`lg`=24×56px, `xl`=28×64px — `lib/pulsar/components/switch.ex:104–127`.
Browser measurement: 0/120 cells pass ≥ 24×24 — the data-fixture-cell
is on the `sr-only` input which has size 0×0. The visible track meets
24px floor only at `lg` and `xl`.

**Notes:** WCAG 2.5.8 spacing exception applies: each switch in `field`
usage is paired with a `<label>` (clickable via `for=`) and surrounded
by flex-col gap-3 / form-grid spacing. The effective target is the
label-plus-switch group which exceeds 24×24 even at `xs`. Document
in usage notes that `xs` / `sm` / `md` switches should always be
paired with a label of adequate width. Same situation as Checkbox.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler in component template.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-change`, but component itself
triggers no navigation/submit — `lib/pulsar/components/switch.ex:393, 501`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid={@invalid && "true"}` —
`lib/pulsar/components/switch.ex:500`. Test
`sets aria-invalid for field errors` —
`test/pulsar/components/switch_test.exs:258–265`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label is caller's responsibility via `field`; switch
supports `aria_label`/`aria_labelledby` for standalone use.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Error text is rendered at the `field` wrapper level;
switch doesn't suppress.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: explicit `role="switch"` on the input —
  `lib/pulsar/components/switch.ex:496`
- Name: `aria_label`/`aria_labelledby` or associated `<label for=>` —
  `lib/pulsar/components/switch.ex:498–499`
- Value: `aria-checked="true"`/`"false"` —
  `lib/pulsar/components/switch.ex:497`
- State: `aria-invalid`, native `disabled`/`required` —
  `lib/pulsar/components/switch.ex:494–500`
- Tests assert `role="switch"`, `aria-checked`, `aria-label`,
  `aria-labelledby`, `aria-invalid` —
  `test/pulsar/components/switch_test.exs:244–299`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` reflects validation —
`lib/pulsar/components/switch.ex:500`. Loading state is communicated via
`data-loading="true"` on the track and thumb; the spinner SVG is
`aria-hidden` and intended as decorative. Note that the switch does
*not* set `aria-busy` for the loading state, which would be the more
correct signal for assistive tech.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — switches don't carry user
  identity / personal info; `autocomplete` doesn't apply.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip/popover.
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

- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `lg` (`h-6 w-14` =
  24×56px) and `xl` (28×64px) exceed the AAA 44×44 floor in their
  larger dimension; both still under in the smaller (track height)
  dimension. Marginal pass.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — track focus background
  swap + thumb scale-110 provides a clear, thick indicator. Light
  theme passes AAA (5.73:1); dark theme falls short (2.97:1, under
  the AAA 4.5:1 floor — and AA 3:1) — see `switch-dark-focus-indicator`
  follow-up under 1.4.11 / 2.4.7.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `button-name` | toggle button lacks accessible name | both | [PUL-40](https://linear.app/bigrefactor/issue/PUL-40/switch-fix-axe-button-name-violation) |
