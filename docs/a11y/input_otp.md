# Input OTP · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/input_otp.ex`](../../lib/pulsar/components/input_otp.ex)
**Tests:** [`test/pulsar/components/input_otp_test.exs`](../../test/pulsar/components/input_otp_test.exs)
**Audited:** 2026-06-07 (code + browser axe gate)

A single `<input autocomplete="one-time-code" inputmode="numeric">` holding the
whole code, presented as a row of single-character slots. The input is the only
focusable, labeled control; the slot row is `aria-hidden`. `aria-invalid`
reflects error state; the label and `aria-describedby` are supplied by the
`field` wrapper. Variants are outline (bordered), solid (filled), and ghost
(underline); the active slot shows a `ring-ring` focus indicator and a caret.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content is the caret animation element and the
slot char spans, both of which are inside the `aria-hidden="true"` slot row —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`, `otp_cell/1`. No meaningful
icon-only or image content is rendered by the component. The separator dash
rendered between groups is also `aria-hidden="true"` — `otp_cell/1`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- The real `<input>` carries `type="text"`, `autocomplete="one-time-code"`, and
  `inputmode` — `lib/pulsar/components/input_otp.ex`, `input_otp/1`
- `aria-invalid` reflects error state — `input_otp/1`
- The decorative slot row is `aria-hidden="true"` so assistive technologies see
  only the real input — `input_otp/1`
- `test "renders one real input with one-time-code autofill and the hook"`
- `test "renders one painted slot per length, all aria-hidden"`

**Notes:** Label association is the responsibility of the `field` wrapper
(see [`field.md`](field.md)); this leaf accepts `id` and exposes it for `for=`
linkage — `lib/pulsar/components/input_otp.ex`, `input_otp/1` (`attr :id`).

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: hidden real input (absolute-positioned overlay) →
`aria-hidden` slot row — `lib/pulsar/components/input_otp.ex`, `input_otp/1`. The
real input is the only perceivable element for assistive technologies; the slot
row is decorative and hidden from the accessibility tree.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Invalid/error state is conveyed via `aria-invalid="true"` on the
real input (not color alone) — `lib/pulsar/components/input_otp.ex`, `input_otp/1`. The
`field` wrapper adds a visible error message. Disabled state combines
`opacity-disabled` on slots and the native `disabled` attribute on the input —
`input_otp/1`, `otp_cell/1`.

### 1.3.5 Identify Input Purpose (AA) — ✓ PASS

**Evidence:** `autocomplete="one-time-code"` is hardcoded on the real input —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`. This is the WCAG-recognized token for
OTP / verification-code inputs and maps directly to the WCAG 1.3.5 purpose list.
Test asserts this value — `test "renders one real input with one-time-code autofill and the hook"`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state pairs color change on slot borders with
`aria-invalid="true"` on the real input — `lib/pulsar/components/input_otp.ex`, `input_otp/1`.
The `field` wrapper supplies a text error message alongside the color signal.
Disabled state pairs `opacity-disabled` with the native `disabled` attribute —
`input_otp/1`, `otp_cell/1`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Entered characters and the caret indicator use `text-foreground`
via `@slot_base` — `lib/pulsar/components/input_otp.ex`, `slot_classes/3`. The mask dot
(`•`) inherits the same token. `text-foreground` maps to `gray-950` (light) /
`gray-50` (dark), measured well above 4.5:1 against `bg-background` in the
browser axe gate. The axe gate is clean across all fixture cells.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Slot sizes use rem-based Tailwind text utilities — `text-sm`,
`text-base`, `text-xl`, `text-2xl`, `text-3xl` — and fixed-pixel slot
dimensions (`h-8 w-8` through `h-16 w-14`) that scale the slot box, not the
text container height exclusively — `lib/pulsar/components/input_otp.ex`, `slot_classes/3`.
The real input uses `h-full w-full` (inherits from the wrapper), so text
content is never clipped.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The slot row is `flex flex-wrap`, so a code too wide for the
viewport breaks onto another row instead of overflowing —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`. With `groups` set, each group
renders as its own non-wrapping row (`data-otp-group`) — `otp_cell/1` — so the
break lands at a separator and never splits a group. No `min-width` or fixed
container width is imposed on the outer `inline-flex` container, which
shrink-to-fits the available width.

Slots themselves keep the width their `size` gives them; the per-size
slots-per-row capacity at 320 CSS px is documented under "Fitting a long code"
in the module doc, so callers can size a long code before it reaches a
viewport.

**Gate:** `test/integration/a11y/reflow_test.exs` measures the three
`/components/input_otp/*` routes at 320 × 640, each in both themes. It raises
on `document.documentElement.scrollWidth` alone — the per-cell widths it
prints are diagnostics inside that check, not assertions of their own — so a
cell fails the gate only when its overflow reaches the page. Every fixture
cell used to sit in an `overflow-x-auto` wrapper, which contains horizontal
overflow before it gets there: the `xl` sizes cell already rendered 396 px
wide at a 320 px viewport and the gate still passed. Dropping those wrappers
(`test/support/dev_app/live/input_otp_live.ex`) is what armed the gate, and
the `length={10} groups={[5, 5]}` cell added alongside them is what it now
catches — with `flex-wrap` removed, all six route × theme tests fail at
`documentElement.scrollWidth` 552.

Where the row *breaks* is measured separately, in
`test/integration/a11y/input_otp_reflow_test.exs`, test "a ten-slot grouped
code puts one group per row, separator included" — a code that wraps mid-group
or strands a separator on its own row is no wider than one that breaks
cleanly, so the width gate cannot tell them apart.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Outline and ghost variants use `border-border-strong` for slot borders —
  `lib/pulsar/components/input_otp.ex`, `slot_classes/3`
- The active slot ring uses `ring-ring` (neutral color) —
  `slot_classes/3`
- `--color-ring` measured 5.02:1 (light) / 6.72:1 (dark) — above the 3:1
  non-text minimum (same token used by Button, Input, and Tabs)
- `--color-border-strong` resolves to `gray-500` (light) / `gray-400` (dark),
  giving slot edges ≥4.5:1 against the page background

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` overrides on spacing; slot sizes use fixed `h-*`
/ `w-*` Tailwind utilities that allow text to overflow rather than clip —
`lib/pulsar/components/input_otp.ex`, `slot_classes/3`. The real input uses `h-full` so
any user-overridden line-height is absorbed by the slot box.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The real `<input>` is natively keyboard-operable — typing,
Tab/Shift+Tab, and clipboard paste all work without custom key handlers —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`. The `.PulsarInputOtp` hook
listens only to `input`, `focus`, `blur`, `keyup`, `click`, and `select`
events for painting the slot display; it never intercepts or cancels Tab or
Shift+Tab — `input_otp/1` (colocated hook `boot`).

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No `keydown` handler is registered by the hook. Native Tab
behavior is fully preserved — the user can Tab into and out of the input
without restriction — `lib/pulsar/components/input_otp.ex`, `input_otp/1`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only animation is the caret blink (`animate-pulse`) and the
slot transition (`transition-[box-shadow,border-color,background-color]
duration-150`) — `lib/pulsar/components/input_otp.ex`, `slot_classes/3`,
`otp_cell/1`. Both respect `motion-reduce:animate-none` on the caret —
`otp_cell/1`. No auto-updating or auto-advancing content.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing animations. The caret pulse and color transitions are
smooth and sub-threshold — `lib/pulsar/components/input_otp.ex`, `slot_classes/3`,
`otp_cell/1`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex` is used. The real `<input>` participates
in natural document tab order — `lib/pulsar/components/input_otp.ex`, `input_otp/1`.
The slot row is `aria-hidden` and not focusable.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Label is the caller's responsibility via the `field` wrapper (see
[`field.md`](field.md)); the leaf accepts `id` for `for=` / `aria-labelledby`
linkage — `lib/pulsar/components/input_otp.ex`, `input_otp/1` (`attr :id`).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The active slot gains a `ring-2 ring-ring` indicator controlled
by the `data-[active=true]:ring-2 data-[active=true]:ring-ring` CSS variant —
`lib/pulsar/components/input_otp.ex`, `slot_classes/3`. The `--color-ring` token measures
5.02:1 (light) / 6.72:1 (dark), above the 3:1 non-text minimum. The real
`<input>` has `outline-none` but the painted slot row provides the visible
focus cue.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Single in-flow render; the component creates no sticky or
overlapping content that could cover the focused input —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The component registers no `mousedown` or `pointerdown`
listeners. The hook uses the native `click` event (fires on mouseup) for
`paint` resyncs — `lib/pulsar/components/input_otp.ex`, `input_otp/1`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** The input does not set its own `aria-label`; its accessible name
flows from the associated `<label>` element (via `field`) or a caller-supplied
`aria-label` in `:rest` — `lib/pulsar/components/input_otp.ex`, `input_otp/1`
(`attr :rest`).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The smallest slot size is `xs` = `h-8 w-8` (32×32 CSS px) —
`lib/pulsar/components/input_otp.ex`, `slot_classes/3`. All sizes exceed the 24×24 minimum:
`xs`=32px, `sm`=36px, `md`=48×44px, `lg`=56×48px, `xl`=64×56px. Slots are
separated by `gap-1` through `gap-3` so adjacent targets do not overlap —
`input_otp/1`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the input does not trigger navigation or form
submission; it only fires the `paint` repaint of the slot display —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Entering a character updates the slot display and, once all
characters are entered, executes the caller-supplied `on_complete` `%JS{}`
command — `lib/pulsar/components/input_otp.ex`, `input_otp/1` (colocated hook
`maybeComplete`). The component does not trigger navigation or form
submission on its own; those actions are caller-initiated via `JS.push(...)`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid="true"` / `"false"` is written to the real input
based on the `invalid` assign — `lib/pulsar/components/input_otp.ex`, `input_otp/1`. The
`field` wrapper supplies the visible error message text and links it via
`aria-describedby`. See [`field.md`](field.md) for the full error-identification
chain. `test "sets aria-invalid from invalid"`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label and instructions are the responsibility of the `field`
wrapper (see [`field.md`](field.md)). The leaf accepts `id` for `for=` /
`aria-labelledby` linkage — `lib/pulsar/components/input_otp.ex`, `input_otp/1`
(`attr :id`). When used standalone, callers supply `aria-label` via `:rest` —
`input_otp/1` (`attr :rest`).

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** The component does not suppress or modify caller-provided error
text; error message rendering is the `field` wrapper's responsibility. See
[`field.md`](field.md).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: implicit from native `<input type="text">` —
  `lib/pulsar/components/input_otp.ex`, `input_otp/1`
- Name: from `name=` attr (Phoenix form integration) or caller-supplied —
  `input_otp/1`
- Value: from `value=` attr (bound to the field value) —
  `input_otp/1`
- State: `aria-invalid`, native `required`/`disabled`/`autofocus` —
  `input_otp/1`
- The decorative slot row is `aria-hidden="true"` so it exposes no spurious
  role or name to assistive technologies —
  `input_otp/1`
- `test "derives id/name/value from a Phoenix field"`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` flips with error state —
`lib/pulsar/components/input_otp.ex`, `input_otp/1`. The associated error region
(rendered by `field`) carries `aria-live="polite"`. See [`field.md`](field.md).

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; slot chars are live DOM text.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or popover on hover/focus.
- **2.1.4 Character Key Shortcuts (A)** — no single-character global shortcuts registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** — while this component is used in authentication flows, the criterion targets cognitive-function tests (puzzles, image transcription); a one-time-code copy-paste from SMS/email is explicitly permitted by WCAG and the component does not introduce a cognitive test.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the
  AAA minimum thickness, and the `--color-ring` token clears AAA contrast
  (5.02:1 light / 6.72:1 dark) — `lib/pulsar/components/input_otp.ex`,
  `slot_classes/3`.
- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `md` (`h-12`=48px) and
  above exceed the AAA 44×44 floor — `slot_classes/3`.

## Browser a11y findings

None. The axe gate is clean across the `/components/input_otp/*` fixture cells in
light and dark themes.
