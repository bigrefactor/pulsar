# Field · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/field.ex`](../../lib/pulsar/components/field.ex)
**Tests:** [`test/pulsar/components/field_test.exs`](../../test/pulsar/components/field_test.exs)
**Audited:** 2026-05-24 (code-only)

Canonical form-input wrapper. Generates label / description / error
regions and wires `for`/`id`, `aria-labelledby`, `aria-describedby`, and
`aria-invalid` between the surrounding markup and the leaf input
component selected by `:type`.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Error icon `hero-exclamation-circle` rendered alongside
error text — `lib/pulsar/components/field.ex:318`. Icon is purely
decorative; the error message itself carries the meaning.

**Notes:** Pulsar's icon component renders `aria-hidden="true"` for
decorative icons by default.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Generates a unique `label_id`, `description_id`, and per-error
  `error_ids`, then composes `aria_describedby` from the union —
  `lib/pulsar/components/field.ex:504–525`
- Label uses `for` for normal inputs and `aria-labelledby` for radio
  groups — `lib/pulsar/components/field.ex:280–281, 448, 529–537`
- Inline labels for checkbox/switch wrap the input in a `<label for=…>` —
  `lib/pulsar/components/field.ex:377, 406`
- Tests assert `aria-labelledby` linkage for radio and
  `aria-describedby` composition —
  `test/pulsar/components/field_test.exs:669–736`

**Notes:** Comprehensive label/description/error linkage. Picks the
right association mechanism per input type.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order is label section → input → error region —
`lib/pulsar/components/field.ex:276–322`. Visual order matches DOM
order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Error state combines text message, icon, color change, and
`aria-invalid` — `lib/pulsar/components/field.ex:312–321`. Required state
is delegated to `Label` (asterisk + sr-only text).

### 1.3.5 Identify Input Purpose (AA) — ✓ PASS

**Evidence:** `autocomplete` attribute pass-through is supported via the
non-select/non-textarea branch — `lib/pulsar/components/field.ex:245, 466–467`.
Generic HTML attributes are forwarded via `{@rest}` and `{@html_attrs}`.

**Notes:** Caller passes `autocomplete="email"` etc.; field forwards it
to the underlying input.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state combines red color + icon + text + `aria-invalid` —
`lib/pulsar/components/field.ex:312–321`. Required indicator (delegated
to Label) uses asterisk + sr-only text.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Description colors use semantic tokens
(`text-gray-600 dark:text-gray-400`, danger variant, etc.) —
`lib/pulsar/components/field.ex:151–159`. Error message color is
`text-danger-600 dark:text-danger-400` —
`lib/pulsar/components/field.ex:182`. Browser measurement of 16 cells:
all field-fixture cells pass, min 19.27:1 (light) / 16.98:1 (dark)
([light](measurements/field-light.md),
[dark](measurements/field-dark.md)).

**Notes:** The per-cell measure suite covers the field-fixture cells
(all 16 pass). The help-text-on-tinted-form-background case is not a
tagged cell — the help text is rendered internally by the Field
component and only surfaces against the tinted background via the Form
fixture — so it is verified by the axe-core browser gate instead, which
now reports no color-contrast violations for either the Field or the
Form fixture in both themes.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All sizing uses Tailwind rem-based classes (`text-sm`,
`text-base`, etc.) — `lib/pulsar/components/field.ex:173–179, 182, 185`.
No fixed pixel heights at the wrapper level.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Wrapper uses `flex flex-col gap-2` — content-driven width,
no `min-width` — `lib/pulsar/components/field.ex:185`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS (delegated)

**Evidence:** Field itself adds no borders/focus rings — those live on
the leaf components. Per-leaf measurements above:
- [input](input.md#1411-non-text-contrast-aa)
- [textarea](textarea.md#1411-non-text-contrast-aa)
- [select](select.md#1411-non-text-contrast-aa)
- [checkbox](checkbox.md#1411-non-text-contrast-aa)
- [radio_group](radio_group.md#1411-non-text-contrast-aa)
- [switch](switch.md#1411-non-text-contrast-aa)

**Notes:** Field is a layout/labeling wrapper; non-text contrast is
the leaf input's responsibility.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Inline label classes include `leading-none` —
`lib/pulsar/components/field.ex:637`. Browser test injects the WCAG
overrides: 0 cells overflow
([light](measurements/field-light.md#text-spacing-override-wcag-1412),
[dark](measurements/field-dark.md#text-spacing-override-wcag-1412)).
The inline-label `leading-none` is on a single-line label and
expands cleanly under 1.5× line-height because the parent layout
doesn't fix the wrapper height.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:**
- Auto-generates a humanized label from the field name when no label
  slot is provided — `lib/pulsar/components/field.ex:289, 554–562`
- Tests cover humanization (`:first_name` → "First name", etc.) —
  `test/pulsar/components/field_test.exs:117–138`

**Notes:** Field never renders unlabeled inputs (except checkbox/switch
without an inline label, where the label inversion is opt-in by passing
no slot — and the auto-generated label still renders inline). Quality
of caller-provided labels is the caller's responsibility.

### 2.4.7 Focus Visible (AA) — ✓ PASS (delegated)

**Evidence:** Focus rings live on the leaf input components — field
itself renders no focusable surface. Per-leaf measurements link from
the 1.4.11 entry above.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Field creates no sticky/overlapping content —
`lib/pulsar/components/field.ex:275–323`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler in field template —
`lib/pulsar/components/field.ex:275–323`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Field forwards `phx-change` to the underlying input via
`{@rest}`; the field itself triggers no context change on input —
`lib/pulsar/components/field.ex:249, 348, 370, 391, 421, 450, 487`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:**
- Errors are rendered as text inside `<p>` tags with unique IDs —
  `lib/pulsar/components/field.ex:313–320`
- `aria-invalid` is passed to every leaf via `invalid={@has_errors}` —
  `lib/pulsar/components/field.ex:346, 368, 389, 419, 447, 485`
- Container has `aria-live="polite"` —
  `lib/pulsar/components/field.ex:312`
- Test `error container has aria-live attribute for screen readers` —
  `test/pulsar/components/field_test.exs:159–170`
- Test `aria-invalid passed to all input types when errors present` —
  `test/pulsar/components/field_test.exs:738–757`

**Notes:** Errors are identified in text, announced via aria-live, and
linked to the input via `aria-describedby` + `aria-invalid`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Auto-generates label from field name; description slot
supports instructional text — `lib/pulsar/components/field.ex:252–259, 289`.
The label is always present (auto-generated when no slot).

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Field renders the error strings provided by the caller's
changeset (`Enum.with_index(@field_errors)`) —
`lib/pulsar/components/field.ex:313–320`. The component faithfully
displays caller-supplied suggestions; it doesn't suppress or filter.

**Notes:** Quality of suggestions is the caller's responsibility.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: native input element selected per `:type`, or `role="radiogroup"`
  on the RadioGroup container (delegated) —
  `lib/pulsar/components/field.ex:331–497`
- Name: label association via `for`/`id` or `aria-labelledby`; description
  via `aria-describedby` — `lib/pulsar/components/field.ex:280–281, 448`
- Value: `field_value` passed through from `Phoenix.HTML.FormField` —
  `lib/pulsar/components/field.ex:548–550`
- State: `aria-invalid`, `aria-required` (via leaf), `aria-describedby`
  pointing to description + error IDs —
  `lib/pulsar/components/field.ex:347, 369, 390, 420, 448, 486, 522–524`
- Tests assert `aria-describedby="…-description …-error-0"` composition —
  `test/pulsar/components/field_test.exs:687–736`

**Notes:** Field is the orchestrator — it pre-builds IDs and pushes them
into the right ARIA slots on each leaf.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** Error container has `aria-live="polite"` —
`lib/pulsar/components/field.ex:312`. New errors announce via AT without
moving focus.

**Notes:** `polite` is correct for validation feedback (less interruptive
than `assertive` / `role="alert"`); the tradeoff is acknowledged.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip/popover.
- **2.1.1 Keyboard (A)** — wrapper is non-interactive (keyboard handled
  by leaf inputs).
- **2.1.2 No Keyboard Trap (A)** — non-interactive wrapper.
- **2.1.4 Character Key Shortcuts (A)** — none registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no motion.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — non-focusable wrapper; leaf inputs handle
  focus order.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no custom click handler.
- **2.5.3 Label in Name (A)** — wrapper has no accessible name itself.
- **2.5.4 Motion Actuation (A)** — none.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — target sizes govern
  the leaf inputs.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not
  authentication.

## AAA wins (bonus)

- None directly applicable to a static wrapper.

## Browser a11y findings

The axe-core browser gate reports no violations for the Field (or Form)
fixture in either theme.
