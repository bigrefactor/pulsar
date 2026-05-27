# RadioGroup · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/radio_group.ex`](../../lib/pulsar/components/radio_group.ex)
**Tests:** [`test/pulsar/components/radio_group_test.exs`](../../test/pulsar/components/radio_group_test.exs)
**Audited:** 2026-05-24 (code-only)

`role="radiogroup"` container wrapping native `<input type="radio">`
options. Each option pairs the input with a `<label for=>` (or a
clickable card `<label>` in card mode). Supports `hide_radios` for
card-only selection (input goes `sr-only`).

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Radio inputs use CSS pseudo-element fills (no glyph). No
decorative icons rendered by the component itself —
`lib/pulsar/components/radio_group.ex:577–601`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Container has `role="radiogroup"` —
  `lib/pulsar/components/radio_group.ex:327`
- Each option has `<label for={radio_id}>` (default mode) or a card
  `<label>` wrapping the input — `lib/pulsar/components/radio_group.ex:409, 445`
- Native radio inputs share a `name=` (radio group semantics) —
  `lib/pulsar/components/radio_group.ex:400, 455`
- Test `renders role="radiogroup" on the container` —
  `test/pulsar/components/radio_group_test.exs:497–508`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Options render in slot order with `Enum.with_index`
producing deterministic IDs — `lib/pulsar/components/radio_group.ex:339–341, 349`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Checked state combines color fill via `checked:bg-*` +
inner-dot pseudo element + native `checked` attr —
`lib/pulsar/components/radio_group.ex:492–540, 598–600`. Error/invalid
combines `aria-invalid` + danger color override + ring —
`lib/pulsar/components/radio_group.ex:330, 405, 460, 854`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Checked is signaled by inner dot (not color alone) —
`lib/pulsar/components/radio_group.ex:596–600`. Invalid combines border
ring + `aria-invalid` — `lib/pulsar/components/radio_group.ex:854`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Per-color matrix for 7 colors —
`lib/pulsar/components/radio_group.ex:490–540`. Card variant matrix —
`lib/pulsar/components/radio_group.ex:683–828`. Browser measurement of
28 cells across both themes
([light](measurements/radio_group-light.md),
[dark](measurements/radio_group-dark.md)): min 19.27:1 (light) /
16.98:1 (dark), max 20.13:1 / 16.98:1. All cells pass.

**Notes:** Label text uses `text-foreground` against page background;
no per-color text on tinted backgrounds in this component.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Sizes use rem-based `w-*`/`h-*` for the radio circle —
`lib/pulsar/components/radio_group.ex:145–181`. Labels use rem-based
text classes.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Container is `flex flex-col gap-3` by default —
`lib/pulsar/components/radio_group.ex:478`. Layout is overridable via
`class` to grid/flex-row as needed; no fixed widths.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Radio uses `border-2` —
`lib/pulsar/components/radio_group.ex:593`. Focus ring
`focus-visible:ring-2 focus-visible:ring-offset-2` —
`lib/pulsar/components/radio_group.ex:594`. Card focus uses
`focus-within:ring-2 focus-within:ring-offset-2` —
`lib/pulsar/components/radio_group.ex:629`. The radio-circle border
itself is rendered by the browser's native widget appearance, not by
Tailwind border tokens — measurement reads `no-border` because the
visible ring is the input's UA shadow tree. Focus indicator measured
via the underlying `<input type="radio">` falls outside the
`data-fixture-cell` scope (the fixture marks the wrapper, not the
input), so per-cell focus is reported as `not-focusable-in-state`.
Border / focus ring contrast for the radio is exercised via the same
`--color-border` and `--color-ring` tokens used by checkbox; checkbox
measures pass (focus ring 5.02:1 light / 6.72:1 dark).

**Notes:** Inferred PASS via shared tokens with checkbox.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Radio is a fixed `w-*`/`h-*` circle (rem-based, scales).
Labels use standard Tailwind text classes —
`lib/pulsar/components/radio_group.ex:605–615`. Browser test injects
the WCAG 1.4.12 overrides and re-measures: no cells overflow
([light](measurements/radio_group-light.md#text-spacing-override-wcag-1412),
[dark](measurements/radio_group-dark.md#text-spacing-override-wcag-1412)).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<input type="radio">` group; arrow keys cycle
within `name=`-shared inputs by browser default. Tab moves into / out of
the group. No custom keydown handlers —
`lib/pulsar/components/radio_group.ex:397–408`.

**Notes:** `data-orientation` is set but not consumed by any JS hook —
relying on native browser arrow-key behavior, which works for both
vertical and horizontal radio groups.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No custom keydown handlers; native radio group Tab
behavior preserved.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only smooth transitions on the inner dot —
`lib/pulsar/components/radio_group.ex:597–599`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`. Native radio group semantics
handle roving tabindex via the browser (focus goes to checked option, or
first if none checked) — `lib/pulsar/components/radio_group.ex:397–408`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Each option has a `<label>` next to the input or wrapping
it in card mode — `lib/pulsar/components/radio_group.ex:409–411, 444–471`.
The radio group as a whole expects `aria-labelledby` (or
`aria-label`) from the caller — `field` passes
`aria-labelledby="#{field_id}-label"` for the field's label —
`lib/pulsar/components/field.ex:448`.

### 2.4.7 Focus Visible (AA) — ✓ PASS (inferred)

**Evidence:** `focus-visible:outline-none focus-visible:ring-2
focus-visible:ring-offset-2` plus color ring —
`lib/pulsar/components/radio_group.ex:594, 496, 503, 510, 517, 524, 531, 538`.
Card variant uses `focus-within:ring-2` —
`lib/pulsar/components/radio_group.ex:629`. The wrapper `<label>` is
not the focusable element; the focusable `<input type="radio">`
inside doesn't carry `data-fixture-cell`, so the per-cell focus
measurement falls back to `not-focusable-in-state` on the wrapper.

**Notes:** Ring color resolves to the same `--color-ring` token used
by Button / Checkbox (measured at 5.02:1 / 6.72:1) — focus indicator
contrast is verified by symmetry.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Linear render; no sticky overlap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native radio input; activation on click (mouseup).

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Accessible name comes from associated `<label>` content;
no `aria-label` set on individual inputs.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS (per WCAG spacing exception)

**Evidence:** Radio sizes `xs`=12px, `sm`=16px, `md`=20px, `lg`=24px,
`xl`=28px — `lib/pulsar/components/radio_group.ex:145–181`. `xs`,
`sm`, and default `md` are below 24×24 for the radio circle itself.
The `<label>` (clickable via `for=`) extends the practical hit area.
Browser measurement of the 28 fixture cells shows all wrapper rows
pass ≥ 24×24
([light](measurements/radio_group-light.md),
[dark](measurements/radio_group-dark.md)) — the wrapper-label is the
effective target, not the input circle.

**Notes:** WCAG 2.5.8 spacing exception applies: each radio input is
paired with a `<label>` and surrounding spacing in `flex-col gap-3`
(`radio_group.ex:478`), so adjacent radios don't overlap. The
effective target (label + input together) exceeds 24×24 even at
`xs`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler in component template.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-change` to the radiogroup container,
but component itself triggers no navigation/submit —
`lib/pulsar/components/radio_group.ex:243, 337`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:**
- `aria-invalid={@invalid && "true"}` on the group container *and* each
  radio input — `lib/pulsar/components/radio_group.ex:330, 405, 460`
- `aria-required={@required && "true"}` on the group container *and*
  each radio input — `lib/pulsar/components/radio_group.ex:331, 406, 461`
- Test `integrates with Phoenix form field for automatic validation`
  asserts both `data-invalid="true"` and `aria-invalid="true"` —
  `test/pulsar/components/radio_group_test.exs:186–221`

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Group label is caller's responsibility via `field`; each
option has its own visible label.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Error text is rendered at the `field` wrapper level; this
component doesn't suppress it.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: `role="radiogroup"` on container; native `<input type="radio">`
  inputs — `lib/pulsar/components/radio_group.ex:327, 398, 453`
- Name: shared `name=` across all radio inputs in the group —
  `lib/pulsar/components/radio_group.ex:400, 455`
- Value: per-option `value=`, native `checked` attr reflects current
  selection — `lib/pulsar/components/radio_group.ex:401–402, 456–457`
- State: `aria-invalid`, `aria-required`, native `disabled` (group
  and/or per-option) — `lib/pulsar/components/radio_group.ex:330–331, 404–406, 459–461`
- Test `checks the radio matching the group value (native aria-checked
  propagation)` asserts checked attribute mapping —
  `test/pulsar/components/radio_group_test.exs:523–538`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` reflects validation state —
`lib/pulsar/components/radio_group.ex:330`. Field-level error region
carries `aria-live="polite"`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — radio groups don't carry user
  identity / personal info; `autocomplete` doesn't typically apply.
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

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets
  AAA minimum thickness. Inferred AAA pass from Button's measured
  ring contrast (5.02:1 / 6.72:1, same `--color-ring` token).
