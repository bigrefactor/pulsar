# Checkbox · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/checkbox.ex`](../../lib/pulsar/components/checkbox.ex)
**Tests:** [`test/pulsar/components/checkbox_test.exs`](../../test/pulsar/components/checkbox_test.exs)
**Audited:** 2026-05-24 (code-only)

Native `<input type="checkbox">` leaf with a CSS-only custom checkmark
(`::before`/`::after` pseudo elements), tri-state (indeterminate)
support, optional hidden companion input for the unchecked value, and
an optional "card" variant that wraps the input in a clickable `<label>`.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Checkmark glyph (`✓`) and indeterminate dash (`−`) are
CSS `content` pseudo-elements with no DOM presence —
`lib/pulsar/components/checkbox.ex:122, 126`. They reinforce the state
visually; AT relies on the native `checked` attribute and the
`indeterminate` IDL property (set by the colocated `PulsarCheckbox`
hook from `data-indeterminate`).

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<input type="checkbox">` —
  `lib/pulsar/components/checkbox.ex:386`
- Card variant uses `<label for={@id}>` wrapping the input —
  `lib/pulsar/components/checkbox.ex:427, 433`
- Card content gets an `id="#{@id}-content"` referenced by the input's
  `aria-describedby` — `lib/pulsar/components/checkbox.ex:457, 461`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: hidden companion (if any) → checkbox →
optional content slot — `lib/pulsar/components/checkbox.ex:376–466`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Checked state combines color fill + checkmark glyph +
native `checked` attr; indeterminate is signaled by the dash glyph plus
the native `indeterminate` IDL property (synced from
`data-indeterminate` by the `PulsarCheckbox` hook) —
`lib/pulsar/components/checkbox.ex:122–126, 390, 392, 399, 472–486`.
Disabled state combines opacity + `disabled:cursor-not-allowed` + native
`disabled`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Checked state is signaled by checkmark glyph (not just
fill color) — `lib/pulsar/components/checkbox.ex:122, 125`. Error
state combines danger border + `aria-invalid="true"` —
`lib/pulsar/components/checkbox.ex:398, 559`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Color matrix with semantic foreground/background tokens
for each of 7 colors —
`lib/pulsar/components/checkbox.ex:528–684`. Card variant adds another
matrix — `lib/pulsar/components/checkbox.ex:706–980`. Browser
measurement of 123 cells per theme: all pass, min 13.3:1 (light) /
10.88:1 (dark) ([light](measurements/checkbox-light.md),
[dark](measurements/checkbox-dark.md)).

**Notes:** Checkbox itself has no text; label content uses
`text-foreground` against the page background which clears 4.5:1 by
a wide margin. Card variant text against `bg-surface-1` also passes.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Sizes use Tailwind `h-*`/`w-*` rem-based classes
(`h-3`/`h-7`) — `lib/pulsar/components/checkbox.ex:91–112`. Text inside
checkmark uses rem-based `text-*`.

**Notes:** `h-*` (not `min-h-*`) sets fixed sizes; needed for the square
appearance, but they're rem-based so they scale.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Checkbox is inline-sized; card variant uses `flex
items-center` with no fixed widths —
`lib/pulsar/components/checkbox.ex:131`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Border `before:border-2` —
`lib/pulsar/components/checkbox.ex:121`. Focus ring
`focus-visible:before:ring-2 focus-visible:before:ring-offset-2
focus-visible:before:ring-ring` —
`lib/pulsar/components/checkbox.ex:117–118`. Browser measurement of
96 focus-ring cells per theme: 96/96 pass, ring contrast 5.02:1
(light) / 6.72:1 (dark). The checkbox's `before:` pseudo-element
border is rendered through Tailwind's `--color-border` token; per
the dev_app theme it resolves to a high-contrast neutral that
visually matches the input's native widget border.

**Notes:** Focus ring uses the standard `--color-ring` token, same
as Button — fully verified.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Fixed `h-*`/`w-*` square sizes by design —
`lib/pulsar/components/checkbox.ex:91–112`. Card text uses standard
Tailwind classes. Browser test injects the WCAG overrides and re-
measures: 0 cells overflow
([light](measurements/checkbox-light.md#text-spacing-override-wcag-1412),
[dark](measurements/checkbox-dark.md#text-spacing-override-wcag-1412)).
The checkbox is a square widget with no internal text; the card
variant's content adapts because line-height changes don't affect
the surrounding flex layout.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<input type="checkbox">` is keyboard-operable
(Space) — `lib/pulsar/components/checkbox.ex:386`. Card variant uses
native `<label for=>` so clicks/Enter activate the input via browser
defaults.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No custom keydown handlers; native checkbox Tab behavior.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only smooth transform/opacity transitions on the checkmark
(`after:transition-[transform,opacity] after:duration-fast
after:ease-standard`) — `lib/pulsar/components/checkbox.ex:122`. No essential
motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; smooth 120ms (`duration-fast`) transitions only.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`. Card variant places content after
the input in DOM (visually after); focus lands on the checkbox first.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Label is the caller's responsibility via `field`; card
variant has its own inline content slot. The `field` wrapper enforces
labels for default mode.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Default checkbox: `focus-visible:outline-none
focus-visible:before:ring-2 focus-visible:before:ring-offset-2
focus-visible:before:ring-ring` — `lib/pulsar/components/checkbox.ex:117–118`.
Card uses `focus-within:ring-2 focus-within:ring-offset-2
focus-within:ring-ring` — `lib/pulsar/components/checkbox.ex:132–133`.
Browser measurement: 96 focus-ring cells pass 5.02:1 (light) / 6.72:1
(dark) ([light](measurements/checkbox-light.md),
[dark](measurements/checkbox-dark.md)).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Single-element render (with optional inline card content);
no sticky overlap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native checkbox; activation on click (mouseup).

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** No `aria-label` set; accessible name flows from the
associated label or card content.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Every size clicks through a 24×24 CSS-px input box
(`h-6 w-6`, `lib/pulsar/components/checkbox.ex:91–111`). At `xs`/`sm`/`md`
the box is held to its glyph size — 12/16/20 px — by insetting the
visible `::before` square (`before:inset-[6px]` / `[4px]` / `[2px]`),
so the pointer target grows to the WCAG floor while the checkmark stays
visually unchanged; `lg` (24 px) and `xl` (28 px) were already at/above
the floor. Browser measurement: 123/123 cells pass ≥24×24 across all 6
colors, 5 states, and 5 sizes, plus the card cells
([light](measurements/checkbox-light.md), [dark](measurements/checkbox-dark.md)).

**Notes:** Passes outright on size — no spacing exception needed, so a
standalone checkbox outside `field` is compliant at every size. The only
residual is physics, shared by any technique: a *bare, label-less* grid
packed tighter than `gap-3` (12 px) brings the 24 px hit boxes into
contact; at `gap-3` they are exactly tangent (compliant), and normal
`field`/form spacing clears it. The visible square and checkmark are
pixel-identical to before.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler in the component template.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-click`/`phx-change`, but component
itself triggers no navigation/submit —
`lib/pulsar/components/checkbox.ex:308`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid={@invalid && "true"}` —
`lib/pulsar/components/checkbox.ex:398, 456`. Test
`sets aria-invalid when invalid` —
`test/pulsar/components/checkbox_test.exs:617–626`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label is caller's responsibility via `field`.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Error text is rendered at the `field` wrapper level;
checkbox doesn't suppress.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: native `<input type="checkbox">` —
  `lib/pulsar/components/checkbox.ex:386`
- Name: from `name=` attr —
  `lib/pulsar/components/checkbox.ex:388`
- Value: from `value=` (checked-value) and the hidden companion's
  unchecked value — `lib/pulsar/components/checkbox.ex:378–399`
- State: native `checked`, `disabled`, `required`; `aria-invalid`;
  indeterminate exposed via the JS-only `indeterminate` IDL property,
  set by the colocated `PulsarCheckbox` hook from `data-indeterminate`
  on mount and update — `lib/pulsar/components/checkbox.ex:399,
  472–486`
- Tests assert the hook is wired and that `aria-checked` is never set
  on the native input —
  `test/pulsar/components/checkbox_test.exs:628–660`

**Notes:** `aria-checked` is invalid on a native `<input
type="checkbox">` (axe rule `aria-conditional-attr`); the ARIA spec
reserves it for elements with `role="checkbox"`. Native checkboxes
expose tri-state via the `indeterminate` IDL property, which screen
readers (NVDA / VoiceOver / JAWS) announce as "mixed" or "partially
checked". The `PulsarCheckbox` colocated hook syncs the IDL property
from `data-indeterminate` so the visual dash glyph (CSS-driven) and
the assistive-tech state stay aligned across LiveView patches.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` reflects validation state —
`lib/pulsar/components/checkbox.ex:398`. Field-level error region carries
`aria-live="polite"`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — checkboxes don't carry user
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

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets
  AAA minimum thickness. Browser measurement: 5.02:1 / 6.72:1 meets
  the AAA 4.5:1 focus contrast requirement.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `label` | unlabelled checkboxes in fixture | both |
