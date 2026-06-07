# Steps · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/steps.ex`](../../lib/pulsar/components/steps.ex)
**Tests:** [`test/pulsar/components/steps_test.exs`](../../test/pulsar/components/steps_test.exs)
**Audited:** 2026-06-07 (code + browser axe gate)

A non-interactive progress indicator: an `<ol aria-label="Progress">` of steps,
each an `<li>` carrying a marker and a label/description. The host owns the flow
and passes `current` (the 1-based active index); each step's state — done,
current, upcoming — is derived from it, and a step may override its state
directly (error, loading, disabled). The current step's `<li>` carries
`aria-current="step"`. Inside each marker the glyph (check, x-mark, spinner, dot,
or number) is decorative; a visible per-state `sr-only` status line (Completed /
Current step / Upcoming / Error / Loading / Disabled) carries the meaning for
assistive tech. The current step is emphasized per `variant` (solid fill, ghost
tint, outline ring) paired with a semantic `color`; upcoming and disabled markers
use `text-muted-foreground`. The component renders no focusable controls and runs
no JavaScript.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Every marker glyph is non-text and explicitly decorative: the
check/x-mark icons render through the Icon component (`aria-hidden` by default),
the loading spinner is an `aria-hidden="true"` span, and the connector line
between steps is an `aria-hidden="true"` span —
`lib/pulsar/components/steps.ex:244, 246–256`. Meaning is carried by the visible
`label` and a per-state `sr-only` status line, not by the glyph —
`lib/pulsar/components/steps.ex:259–260`. Test
`sr-only status text is present for screen readers` —
`test/pulsar/components/steps_test.exs:72`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The steps are an ordered `<ol>` list with an accessible name via
`aria-label`, each step an `<li>`; the current step is marked with
`aria-current="step"` — `lib/pulsar/components/steps.ex:242–243`. Tests
`renders an ordered list labeled by aria_label` and
`marks the current step with aria-current=step` —
`test/pulsar/components/steps_test.exs:10, 36`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Items render in authored slot order (`Enum.with_index(1)`), so DOM
order matches both the numbered visual order and the progress sequence —
`lib/pulsar/components/steps.ex:210–212, 243`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** State is never conveyed by color alone. Each state has a distinct
glyph/shape — a checkmark for done, an x-mark for error, a spinner for loading,
the step number (or a dot) for upcoming — and the `<li>` carries an `sr-only`
status line plus, for the active step, `aria-current="step"` —
`lib/pulsar/components/steps.ex:243, 246–260`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Done/current markers pair a semantic fill with its readable
foreground (`bg-{color} text-{color}-foreground`) or accent text on the
background (outline/ghost); upcoming and disabled markers and labels use
`text-muted-foreground` (measured 6.0–7.23:1 on all surfaces) —
`lib/pulsar/components/steps.ex:319–324, 339–343`. Per-cell measurements record
the rendered text at ~19:1 (light) / ~17:1 (dark) across every variant × color ×
size cell plus the state-vocabulary and vertical cells —
[`measurements/steps-light.md`](measurements/steps-light.md),
[`measurements/steps-dark.md`](measurements/steps-dark.md). Disabled steps
deliberately stay AA-legible (`text-muted-foreground`, not a sub-floor grey):
this is a presentational indicator, not a disabled form control, so it does not
rely on the WCAG disabled-control contrast exemption — test
`disabled step is de-emphasized but keeps legible text` —
`test/pulsar/components/steps_test.exs:120`. The axe gate scans the
`/components/steps/{solid,outline,ghost}` fixtures in light and dark with no
violations.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Marker and label sizes use rem-based Tailwind text utilities
(`text-xs`–`text-lg`) — `lib/pulsar/components/steps.ex:99–105, 128–134`. Text
scales with the user's font size.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The list is a `flex` row (or `flex flex-col` when vertical) with no
fixed width, and the label column uses `min-w-0` so content shrinks rather than
forcing horizontal scrolling — `lib/pulsar/components/steps.ex:345–347, 258`. The
reflow measurement at 320 CSS px reports no overflowing cells —
[`measurements/steps-light.md`](measurements/steps-light.md).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Marker glyphs that carry state (the check ✓ and x-mark ✗) render on
their filled marker at the same ≥4.5:1 contrast as the marker foreground, well
above the 3:1 non-text minimum; connector and inactive marker borders route
through `border-border` / the semantic accent `border-{color}` (≥3:1) —
`lib/pulsar/components/steps.ex:323–324, 356`. The axe gate finds no non-text
contrast violations across the fixtures in light and dark.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Labels and descriptions impose no fixed line height or
`!important` spacing; with the WCAG text-spacing override applied
(line-height 1.5, letter-spacing 0.12em, word-spacing 0.16em) no cell overflows —
[`measurements/steps-light.md`](measurements/steps-light.md).

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.3 Sensory Characteristics (A)** — state is conveyed by glyph + `sr-only` text, not by shape/position alone.
- **1.3.4 Orientation (AA)** — no orientation lock; supports both horizontal and vertical.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — labels are text; glyphs are inline SVG / shapes.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered content.
- **2.1.1 Keyboard (A)** — non-interactive indicator; no focusable controls.
- **2.1.2 No Keyboard Trap (A)** — nothing focusable to trap.
- **2.1.4 Character Key Shortcuts (A)** — no key shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — the loading spinner is decorative (`aria-hidden`) and honors `motion-reduce:animate-none`; no auto-updating content the user must track.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — no focusable controls.
- **2.4.4 Link Purpose (In Context) (A)** — no links (presentational indicator).
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — step labels and the list `aria-label` are caller-supplied and rendered faithfully.
- **2.4.7 Focus Visible (AA)** — no focusable controls.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — no focusable controls.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no pointer activation.
- **2.5.3 Label in Name (A)** — no interactive controls with accessible names.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no dragging.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — no interactive targets.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — nothing focusable changes context.
- **3.2.2 On Input (A)** — no form inputs.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — an errored step is a flow-status indicator, not a form-field error.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.2 Name, Role, Value (A)** — native `<ol>`/`<li>` semantics with `aria-label` and `aria-current="step"`; no custom widget roles, states, or values to expose.
- **4.1.3 Status Messages (AA)** — the indicator is presentational; the host owns any live announcement of progress changes.

## Reduced motion

The only animation is the loading spinner, which carries
`motion-reduce:animate-none` so it freezes to a static ring for users who request
reduced motion; the marker transitions also carry `motion-reduce:transition-none`
— `lib/pulsar/components/steps.ex:139, 251`.

## Browser a11y findings

None. The axe gate is clean across the `/components/steps/{solid,outline,ghost}`
fixture cells in light and dark themes.
