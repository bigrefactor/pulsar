# Switch · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/switch.ex`](../../lib/pulsar/components/switch.ex)
**Tests:** [`test/pulsar/components/switch_test.exs`](../../test/pulsar/components/switch_test.exs)
**Audited:** 2026-05-27 (code-only)

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

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Off-state track uses `bg-border-strong` (solid),
  `border-border-strong` (outline + ghost) — both resolve to
  `--color-border-strong` = `gray-500` (light) / `gray-400` (dark),
  which clear 3:1 against `--color-background` (≈4.83:1 light,
  ≈7.5:1 dark) —
  `lib/pulsar/components/switch.ex:548–577`
- Checked-state track uses semantic color tokens at high opacity
  (`bg-{color}/90` solid, `bg-{color}/10 border-{color}` outline,
  `bg-{color}/15` ghost) — `lib/pulsar/components/switch.ex:131–209`
- Focus ring on the **visible track** (not the `sr-only` input) uses
  `peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-background`
  — `lib/pulsar/components/switch.ex:216–218`
- Thumb has shadow rings —
  `lib/pulsar/components/switch.ex:597–607`

The ring on the visible track resolves to the standard `--color-ring`
token at full opacity, matching Button (5.02:1 light / 6.72:1 dark).

**Notes:** Previous revisions sized the off-state track with `bg-muted/80`
(solid), `bg-muted/30` (ghost), and `border-border/70` (outline). All
three rendered as near-invisible pills against `bg-background` (≤1.7:1)
because `--color-muted` is intentionally a near-background token. The
current revision lifts the off-state boundary to `--color-border-strong`,
which is the canonical 3:1 boundary token (same one Bundle A
strengthened to gray-500 light / gray-400 dark for this purpose). The
measurement tooling reports off-track contrast against the page
background on the visible track div, not the `sr-only` input.

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

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Real input is `sr-only`. The visible track shows a real
keyboard-focus ring via
`peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2`
— `lib/pulsar/components/switch.ex:216–218`. Additional peer-focus
cues remain on the track (`peer-focus-visible:bg-*`,
`peer-focus-visible:border-*` —
`lib/pulsar/components/switch.ex:573, 585, 596`) and thumb
(`peer-focus-visible:scale-110` —
`lib/pulsar/components/switch.ex:255`).

Ring resolves to `--color-ring` (5.02:1 light / 6.72:1 dark) — passes
the 3:1 minimum.

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

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The visible track keeps its design width (`xs`=28px …
`xl`=64px), all already ≥24px wide. The wrapper sets a 24px floor
(`min-h-6`, `lib/pulsar/components/switch.ex:458`) with the pill centered
inside; the click target is an absolute overlay that is a sibling of the
track (not the track itself) and carries the `phx-click`
(`lib/pulsar/components/switch.ex:526–531`), so every size clicks through a
≥24×24 box without changing the pill. Browser measurement: 120/120 cells
pass ≥24×24 across all 6 colors, 5 states, and 5 sizes
([light](measurements/switch-light.md), [dark](measurements/switch-dark.md)).
(Previously this read 0/120 because the measurement cell sat on the
`sr-only` input at 0×0; the fixture now wraps the visible control.)

**Notes:** Passes outright on size — no spacing exception needed, so a
standalone switch outside `field` is compliant at every size. The visible
track and thumb are pixel-identical to before; only the wrapper's
clickable height grew to the 24px floor.

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
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — visible track now
  shows a real `peer-focus-visible` ring (5.02:1 light / 6.72:1 dark)
  plus the existing background swap and thumb scale-110. Passes AA
  3:1; light theme also passes AAA 4.5:1, dark theme passes AAA.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `button-name` | toggle button lacks accessible name | both |
