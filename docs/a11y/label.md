# Label · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/label.ex`](../../lib/pulsar/components/label.ex)
**Tests:** [`test/pulsar/components/label_test.exs`](../../test/pulsar/components/label_test.exs)
**Audited:** 2026-05-24 (code-only)

Typography component that renders a `<label>` with size variants, error
state, required indicator (visible asterisk + screen-reader-only text),
and a required `for` attribute that associates the label with an input.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<label for={@for}>` association; `for` attr is `required: true` —
  `lib/pulsar/components/label.ex:120, 144`
- Required indicator pairs a visible `*` (`aria-hidden="true"`) with an
  `sr-only` span carrying the localizable text —
  `lib/pulsar/components/label.ex:159–160`
- Test `for attribute` and `data-required` cited —
  `test/pulsar/components/label_test.exs:33–55`

**Notes:** Label-to-input association is enforced by the API (required
attr). Required state is exposed redundantly: visually (asterisk) and to
AT (sr-only text + `data-required` for CSS hooks).

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Required state is announced via sr-only text, not "the red
asterisk" — `lib/pulsar/components/label.ex:159–160`.

**Notes:** Asterisk is purely visual reinforcement; AT users get the
explicit text.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Required indicator uses both the asterisk glyph and an
sr-only text label, not color alone — `lib/pulsar/components/label.ex:159–160`.
Error state pairs `text-danger` color with the visible asterisk and the
sr-only "(required)" announcement.

**Notes:** Error styling (color change) is meant to coordinate with the
field's error message; the label itself doesn't carry the only signal.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Default color `text-foreground dark:text-dark-foreground`;
error color `text-danger dark:text-dark-danger` —
`lib/pulsar/components/label.ex:184, 188`. Semantic-token sourcing is sound.
Browser measurement of 8 fixture cells (default, required, error,
required-error × sizes xs-xl): min 4.56:1 (light, danger color) /
6.14:1 (dark) ([light](measurements/label-light.md),
[dark](measurements/label-dark.md)). All pass 4.5:1.

**Notes:** [PUL-35](https://linear.app/bigrefactor/issue/PUL-35/label-fix-axe-color-contrast-violation)
tracks an axe-detected `color-contrast` issue on the danger label
variant when surfaced inside a form on a tinted background; the
component-on-page-bg measurement here passes.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Tailwind text classes (`text-xs` through `text-xl`) use
`rem`; no fixed `px` sizes — `lib/pulsar/components/label.ex:91–110`.

**Notes:** Default `font-medium` and `cursor-pointer` do not constrain
scalability.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** No fixed widths or `min-width` on the label —
`lib/pulsar/components/label.ex:114, 142–162`. Label is inline-level by
default.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights on the label. Default Tailwind text
classes inherit line-height which exceeds 1.5× on typical settings —
`lib/pulsar/components/label.ex:114`. Browser test injects the WCAG
overrides and re-measures: 0 cells overflow
([light](measurements/label-light.md#text-spacing-override-wcag-1412),
[dark](measurements/label-dark.md#text-spacing-override-wcag-1412)).

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** `inner_block` slot is `required: true` —
`lib/pulsar/components/label.ex:139`. The component cannot render without
visible label text.

**Notes:** Quality of label text is the caller's responsibility; the
component enforces presence.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Accessible name comes from `inner_block` (visible text);
no `aria-label` attribute on the component — `lib/pulsar/components/label.ex:142–162`.

**Notes:** Visible text and accessible name are identical by
construction.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Native `<label>` element with required `for` association —
`lib/pulsar/components/label.ex:120, 143–144`. Test
`renders role="label" via native element` is implied by element check —
`test/pulsar/components/label_test.exs:18`.

**Notes:** Role is implicit from the native `<label>`. No custom ARIA is
needed.

## Not applicable

- **1.1.1 Non-text Content (A)** — pure text component (asterisk is
  decorative + `aria-hidden`).
- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — single-element render in DOM order.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not an input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.11 Non-text Contrast (AA)** — no non-text UI (borders/focus
  rings).
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus popovers.
- **2.1.1 Keyboard (A)** — non-interactive (label is not focusable;
  clicking it focuses the associated input via native browser behavior).
- **2.1.2 No Keyboard Trap (A)** — non-interactive.
- **2.1.4 Character Key Shortcuts (A)** — none registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no motion.
- **2.3.1 Three Flashes or Below Threshold (A)** — only color transition;
  no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — non-focusable.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.7 Focus Visible (AA)** — non-focusable.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — non-focusable.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no custom click handler.
- **2.5.4 Motion Actuation (A)** — none.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — clicking the label
  focuses the associated input; target size is governed by the input,
  not the label.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — non-focusable.
- **3.2.2 On Input (A)** — not an input.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — Label exposes `error` styling but
  the error text itself is rendered by `field`.
- **3.3.2 Labels or Instructions (A)** — this *is* the label primitive;
  presence is governed by callers (`field` enforces it).
- **3.3.3 Error Suggestion (AA)** — error text is rendered by `field`.
- **3.3.4 Error Prevention (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not an input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.3 Status Messages (AA)** — label is static, not a status region.

## AAA wins (bonus)

- None directly applicable to a static label primitive.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `color-contrast` | danger label | dark | [PUL-35](https://linear.app/bigrefactor/issue/PUL-35/label-fix-axe-color-contrast-violation) |
