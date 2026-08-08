# Form · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/form.ex`](../../lib/pulsar/components/form.ex)
**Tests:** [`test/pulsar/components/form_test.exs`](../../test/pulsar/components/form_test.exs)
**Audited:** 2026-08-05 (code-only)

Wrapper around `Phoenix.Component.form/1` that moves keyboard focus to the
first invalid field after a failed submit, and optionally renders a legend
explaining the required-field asterisk.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Renders a native `<form>` element via
`Phoenix.Component.form/1` — `lib/pulsar/components/form.ex`, `form/1`;
field relationships are owned by the `field` component (see [field](field.md)).

**Notes:** The component adds no structural markup beyond the optional
legend paragraph.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** The optional legend pairs the `text-danger` asterisk with
the text "indicates a required field" — colour is never the sole carrier
— `lib/pulsar/components/form.ex`, `form/1`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Legend text uses `text-muted-foreground`
(`lib/pulsar/components/form.ex`, `form/1`), which measures 6.0–7.23:1
across all surfaces. The axe-core browser gate reports no `color-contrast`
violation for the form fixture in either theme.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** After a failed submit the colocated `PulsarForm` hook
focuses the first `[aria-invalid="true"]` descendant —
`lib/pulsar/components/form.ex`, `form/1` (hook, deferred `.focus()`).
`test "focus moves to the first invalid field after a failed submit"`
— `test/integration/a11y/form_test.exs`.

**Notes:** Routine `phx-change` validation does not move focus; only
submit does — the hook only sets its internal flag on the native
`submit` event (`form/1`). The legend is not focusable and does not
enter the tab order.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** The optional `required_legend` renders "* indicates a
required field" at the start of the form, per technique H90 —
`lib/pulsar/components/form.ex`, `form/1`.

**Notes:** Opt-in, because the component cannot detect whether any child
field is required. The entire legend paragraph — asterisk and text — is
marked `aria-hidden="true"` (`form/1`), so AT users never hear it; they
receive required state instead from each field's `required` /
`aria-required` attribute, which `field` sets for every control type it
renders: `input`, `textarea`, `select`, `checkbox`, `radio`, `switch`,
`otp`, and — via `DatePicker`'s `aria-required` — `date`/`daterange` (see
[label](label.md) 1.3.1/1.3.3).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Native `<form>` element via `Phoenix.Component.form/1`; no
ARIA role overrides — `lib/pulsar/components/form.ex`, `form/1`.

**Notes:** `phx-hook=".PulsarForm"` attaches behavior only; it adds no
ARIA semantics.

## Not applicable

- **1.1.1 Non-text Content (A)** — no images or icons.
- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — single legend paragraph, then
  caller-provided children in DOM order.
- **1.3.3 Sensory Characteristics (A)** — no instruction depends on
  shape, colour, or position; see [label](label.md) 1.3.3 for the
  required-field reasoning this component defers to.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — inputs are caller-provided
  children, not rendered by `form`.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — the legend is secondary, conditional text;
  the form's substantive text content belongs to its caller-provided
  children, whose resize behavior is `field`'s concern (see
  [field](field.md) 1.4.4).
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.10 Reflow (AA)** — `form` renders no fixed-width container of its
  own; reflow of its content is governed by the caller-provided children
  (see [field](field.md) 1.4.10).
- **1.4.11 Non-text Contrast (AA)** — `form` renders no non-text UI of
  its own (borders, focus rings); those belong to the child fields (see
  [field](field.md) 1.4.11).
- **1.4.12 Text Spacing (AA)** — the legend is secondary, conditional
  text; substantive text-spacing concerns belong to the caller-provided
  children (see [field](field.md) 1.4.12).
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus popovers.
- **2.1.1 Keyboard (A)** — the form itself is not focusable; children own
  their own keyboard behavior.
- **2.1.2 No Keyboard Trap (A)** — no trap; the hook only redirects focus
  once, to a real descendant.
- **2.1.4 Character Key Shortcuts (A)** — none registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no motion.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the legend is not a heading or a
  field label; field labels are owned by `field`.
- **2.4.7 Focus Visible (AA)** — focus rings belong to the focused child
  control, not to `form`.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — no overlay
  behavior.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no custom pointer handler.
- **2.5.3 Label in Name (A)** — `form` has no accessible name of its own.
- **2.5.4 Motion Actuation (A)** — none.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — no interactive
  targets rendered by `form` itself.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern; `required_legend_text`
  is an overridable attr for i18n.
- **3.2.1 On Focus (A)** — the focus-on-error hook only fires on
  `submit`, not on receiving focus.
- **3.2.2 On Input (A)** — no `phx-change`-triggered context change
  originates in `form` itself.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — error text is rendered by `field`,
  not `form`.
- **3.3.3 Error Suggestion (AA)** — error text is rendered by `field`.
- **3.3.4 Error Prevention (AA)** — caller's responsibility.
- **3.3.7 Redundant Entry (A, new in 2.2)** — no multi-step flow owned by
  `form`.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not
  authentication.
- **4.1.3 Status Messages (AA)** — validation status is rendered by
  `field`, not `form`.

## AAA wins (bonus)

- None directly applicable to a form wrapper that renders no visible
  content of its own beyond the optional legend.

## Browser a11y findings

The axe-core browser gate reports no violations for the Form fixture in
either theme.
