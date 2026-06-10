# Progress · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/progress.ex`](../../lib/pulsar/components/progress.ex)
**Fixture:** [`test/support/dev_app/live/progress_live.ex`](../../test/support/dev_app/live/progress_live.ex) (`/components/progress`)
**Standard:** WCAG 2.2 Level AA
**Audited:** 2026-06-10

Non-interactive progress indicator. The root is a `role="progressbar"` with
`aria-valuemin`/`aria-valuemax` and, when determinate, `aria-valuenow`; an
indeterminate linear bar omits `aria-valuenow`, which is the ARIA signal for
indeterminate. The progress meaning is carried by the accessible name (`label`
or `aria-label`) and the value attributes, never by color or animation alone.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The bar/ring graphics convey their meaning programmatically through
the `progressbar` role and its value attributes
(`lib/pulsar/components/progress.ex:156–159`),
not as images. The radial SVG is presentational inside the named progressbar; the
visible percentage text is `aria-hidden` (`lib/pulsar/components/progress.ex:171`
for the linear bar, `lib/pulsar/components/progress.ex:217` for the radial ring)
so it is not announced twice.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** `role="progressbar"` plus `aria-valuemin="0"`,
`aria-valuemax={max}`, and (determinate) `aria-valuenow`
(`lib/pulsar/components/progress.ex:156–159`) expose the progress relationship to
assistive tech. Indeterminate omits `aria-valuenow`
(`lib/pulsar/components/progress.ex:159`, resolved to `nil` at
`lib/pulsar/components/progress.ex:252`).

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on the shape, size, or position of the
indicator; state reaches AT through the role + value attributes and the
accessible name, not the bar's appearance.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Progress is conveyed by the `progressbar` value and the accessible
name (`lib/pulsar/components/progress.ex:156–160`); the semantic color palette
(`lib/pulsar/components/progress.ex:70–78` fill colors,
`lib/pulsar/components/progress.ex:82–90` ring colors) is decorative on top of
that role/value.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Fill colors are the semantic tokens used across the library; the
optional value text uses `text-muted-foreground` (measured 6.0–7.23:1 on all
surfaces) at `lib/pulsar/components/progress.ex:172`, and the radial center value
uses `text-foreground` at `lib/pulsar/components/progress.ex:218`. Verified by
the axe gate against the `/components/progress` fixture.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The fill uses full-strength semantic colors against a `bg-muted`
track (`lib/pulsar/components/progress.ex:180`); the radial ring uses
full-strength semantic stroke color against an `opacity-20` track ring
(`lib/pulsar/components/progress.ex:202`), giving a discernible boundary between
filled and unfilled regions.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The indeterminate animation is a decorative `animate-pulse` opacity
loop (`lib/pulsar/components/progress.ex:190`) on an element whose meaning is
carried by the (animation-independent) `progressbar` role. Under
`prefers-reduced-motion: reduce` the global theme rule stops it; because it
animates opacity (not transform/position) it settles fully visible, so the
indicator never disappears.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Role `progressbar` at `lib/pulsar/components/progress.ex:156`, name
from `label`/`aria-label` at `lib/pulsar/components/progress.ex:160`, and value
from `aria-valuenow` (or absent for indeterminate) at
`lib/pulsar/components/progress.ex:159`.

## Non-applicable criteria

Operable criteria requiring focus/keyboard (2.1.x, 2.4.x, 2.5.x) are **N/A** —
the component is non-interactive (no focusable elements, no keyboard handling).
Time-based-media and parsing criteria are **N/A**.

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — single flat element; DOM order has no semantic bearing.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — no user-visible text beyond the optional percentage label (rem-based tokens); no fixed-px text containers.
- **1.4.5 Images of Text (AA)** — renders no text as images.
- **1.4.10 Reflow (AA)** — linear bar is `w-full`; radial ring uses rem-based size tokens; both reflow at 320 CSS px.
- **1.4.12 Text Spacing (AA)** — no fixed line-height overrides; optional text inherits page spacing.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-revealed content.
- **2.1.1 Keyboard (A)** — non-interactive; nothing to operate.
- **2.1.2 No Keyboard Trap (A)** — no focusable content.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.3.1 Three Flashes or Below Threshold (A)** — `animate-pulse` is a slow opacity fade, well below the 3 flashes/sec threshold.
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
- **4.1.3 Status Messages (AA)** — the progressbar role communicates state through value attributes, not a live-region status message; the component emits no `role="status"` or `role="alert"`.

## Browser a11y findings

The axe-core browser gate reports no violations for the Progress fixture on
`/components/progress` in either theme
([`test/integration/a11y/axe_clean_test.exs`](../../test/integration/a11y/axe_clean_test.exs)).
