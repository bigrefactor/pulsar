# Spinner · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/spinner.ex`](../../lib/pulsar/components/spinner.ex)
**Fixture:** [`test/support/dev_app/live/spinner_live.ex`](../../test/support/dev_app/live/spinner_live.ex) (`/components/spinner`)
**Standard:** WCAG 2.2 Level AA
**Audited:** 2026-06-08

Non-interactive loading indicator. By default it exposes a `role="status"`
live region with a visually-hidden label so assistive technologies announce
loading; the animated graphic itself (ring, dots, or bars) is `aria-hidden`. A
`decorative` mode removes the element from the accessibility tree entirely, for
cases where a surrounding control or region already conveys the loading state.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The animated graphic carries `aria-hidden="true"` on every variant
— `lib/pulsar/components/spinner.ex:163, 176, 179` — so it is exposed to
assistive tech as nothing rather than as a meaningless image. The loading state
is instead conveyed as text via the visually-hidden (`sr-only`) label inside the
status region — `lib/pulsar/components/spinner.ex:182`. In `decorative` mode the
whole element is hidden (`aria-hidden="true"` on the wrapper, no status role,
no label) — `lib/pulsar/components/spinner.ex:151–152, 160, 182`.

**Notes:** Hiding the entire element in `decorative` mode is the correct
treatment for a redundant indicator whose meaning ("loading") is already carried
by a surrounding region the caller controls.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The default wrapper carries `role="status"`, which programmatically
marks the announcement as a live region — `lib/pulsar/components/spinner.ex:160`,
role resolved at `lib/pulsar/components/spinner.ex:151, 200–202`. The graphic and
its hidden label sit in a single flat `<span>` flow with no implied structure to
expose.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order is graphic → visually-hidden label —
`lib/pulsar/components/spinner.ex:160–182`. No reordering CSS; the hidden label
order has no visual effect.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on the shape, size, or position of the
spinner; it carries no operable meaning, and the loading state reaches AT through
the status-region text rather than the animation —
`lib/pulsar/components/spinner.ex:182`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** "Loading" is conveyed by the `role="status"` announcement and its
text label — `lib/pulsar/components/spinner.ex:160, 182` — never by color alone.
The color palette (`current` plus seven semantic colors) is decorative on top of
the announced text — `lib/pulsar/components/spinner.ex:45–54, 209`.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All dimensions use `rem`-based Tailwind tokens (ring `h-3 w-3`…`h-8
w-8`, dot `h-1 w-1`…`h-3 w-3`, bar height `h-3`…`h-8` and width `w-0.5`…`w-1.5`)
— `lib/pulsar/components/spinner.ex:56–104`. No fixed `px`; the visually-hidden
label is real text in normal flow — `lib/pulsar/components/spinner.ex:182`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The wrapper is a plain inline `<span>` carrying only the caller's
`@class`, with no fixed-`px` width or min-width —
`lib/pulsar/components/spinner.ex:160`. The graphic dimensions are small,
class-driven rem tokens — `lib/pulsar/components/spinner.ex:56–104` — so the
spinner reflows at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The graphic uses `currentColor` / `bg-current`, with color resolved
from semantic text tokens (`text-foreground`, `text-primary`, …) —
`lib/pulsar/components/spinner.ex:45–54, 169–173, 219, 231`. `current` (the
default) inherits the surrounding text color. Those semantic values map to tokens
meeting the ≥3:1 non-text minimum against the page background. Verified axe-clean
in light + dark via the fixture (no `color-contrast` violation).

**Notes:** The spinner conveys state through the announced text, so the graphic's
contrast is a perceptibility nicety rather than a meaning-bearing requirement;
the semantic tokens clear 3:1 regardless.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed line-height or letter/word-spacing overrides; the only
text node is the visually-hidden (`sr-only`) label, which inherits page
text-spacing — `lib/pulsar/components/spinner.ex:182`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The motion is essential — it *is* the loading indicator — so the
requirement is met by the WCAG essential-animation exception. Additionally, the
library-wide `prefers-reduced-motion: reduce` rule near-stops the animation, and
the dots/bars resting state is reset to a legible static form under reduced
motion (`pulsar-spinner-dots` / `pulsar-spinner-bars` —
`lib/pulsar/components/spinner.ex:216, 225`).

**Notes:** Reduced-motion users see a static, still-legible indicator rather than
the running animation.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** The ring rotation (`animate-spin` —
`lib/pulsar/components/spinner.ex:212`) and the dots/bars pulses are smooth,
sub-second-cycle animations, not flashes; nothing flashes more than three times
per second.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Default mode exposes `role="status"` on the wrapper —
`lib/pulsar/components/spinner.ex:160`, role resolved at
`lib/pulsar/components/spinner.ex:151, 200–202` — with an accessible name from the
visually-hidden label — `lib/pulsar/components/spinner.ex:182`. `decorative` mode
drops the role and label and sets `aria-hidden="true"`, removing the element from
the tree — `lib/pulsar/components/spinner.ex:151–152, 204–206`. `@rest` forwards
`id`/`data-*`/ARIA — `lib/pulsar/components/spinner.ex:138, 160`. The spinner has
no settable value or interactive state.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** The default `role="status"` region lets the loading state be
announced politely without moving focus —
`lib/pulsar/components/spinner.ex:160, 182`. `decorative` mode intentionally
suppresses the announcement when a surrounding region already carries it.

**Notes:** Documented in the moduledoc — `lib/pulsar/components/spinner.ex:5–8`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.3 Contrast (Minimum) (AA)** — no visible text is rendered (the label is visually hidden); the graphic is covered by 1.4.11.
- **1.4.5 Images of Text (AA)** — renders no text as images.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-revealed content.
- **2.1.1 Keyboard (A)** — non-interactive; nothing to operate.
- **2.1.2 No Keyboard Trap (A)** — no focusable content.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit (the animation is not a time limit).
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — no focusable content.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — not a heading or form label.
- **2.4.7 Focus Visible (AA)** — no focusable content.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — no focusable content.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no pointer activation.
- **2.5.3 Label in Name (A)** — no visible interactive label.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — no interactive target.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — no focusable content.
- **3.2.2 On Input (A)** — not a form input.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.

## Browser a11y findings

The axe-core browser gate reports no violations for the Spinner fixture on
`/components/spinner` in either theme
([`test/integration/a11y/axe_clean_test.exs`](../../test/integration/a11y/axe_clean_test.exs)).
