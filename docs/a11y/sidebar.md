# Sidebar · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/sidebar.ex`](../../lib/pulsar/components/sidebar.ex)
**Tests:** [`test/pulsar/components/sidebar_test.exs`](../../test/pulsar/components/sidebar_test.exs)
**Audited:** 2026-06-01 (code-only)

Responsive, collapsible navigation panel. Renders a `<nav>` landmark with
optional `header` / `footer` regions and a scrollable body. On large screens it
is an in-flow column; below the `lg` breakpoint it is an off-canvas drawer with
a tap-to-dismiss backdrop, focus trap, and Escape-to-close, driven by a colocated
hook. Navigation content (links, menu) is supplied by the caller through slots.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The sidebar renders no non-text content of its own; icons/images
are caller-supplied slot content — `lib/pulsar/components/sidebar.ex:289–298`.
The backdrop is purely decorative and marked `aria-hidden="true"` —
`lib/pulsar/components/sidebar.ex:303–304`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Root is a `<nav>` landmark with an accessible name — `lib/pulsar/components/sidebar.ex:275, 279`
- Header / body / footer render in distinct regions in DOM order — `:289–298`
- Tests assert the landmark and the three slots render — `test/pulsar/components/sidebar_test.exs:11–26, 39–54`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Slots render header → body → footer top-to-bottom via `flex-col`,
matching visual order — `lib/pulsar/components/sidebar.ex:288–298`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Collapse state and side are conveyed by `data-*` attributes and
layout, not by sensory characteristics — `lib/pulsar/components/sidebar.ex:280–283`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color encodes visual emphasis only; the open/collapsed state is
exposed via `data-state` and focus movement, not color —
`lib/pulsar/components/sidebar.ex:282, 371–382`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Each variant/color pairs a semantic background with its matching
`-foreground` (solid) or `text-foreground` on a surface (outline/ghost/elevated)
— `lib/pulsar/components/sidebar.ex:131–165`. Slot text inherits the panel
foreground. Browser measurement of all 35 fixture cells per theme: every cell
passes, min text contrast 5.89:1 (light, `solid-secondary`) / 7.06:1 (dark,
`solid-secondary`) ([light](measurements/sidebar-light.md),
[dark](measurements/sidebar-dark.md)). The axe gate is clean in both themes.

**Notes:** Caller-supplied text that overrides the inherited color is the
caller's responsibility.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** No fixed `px` font sizes; padding and width use `rem`-based Tailwind
utilities — `lib/pulsar/components/sidebar.ex:79–87, 275–301`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Below `lg` the panel becomes a fixed off-canvas drawer overlay
rather than consuming inline width, so main content reflows to full width —
`lib/pulsar/components/sidebar.ex:93–105`. The body scrolls vertically
(`overflow-y-auto`) — `:293`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS (decorative borders are out of scope)

**Evidence:**
- The neutral separating border routes through `border-border-strong` (≥3:1) in
  both `solid` and `outline` — `lib/pulsar/components/sidebar.ex:133, 142`
- Colored `outline` borders use the saturated brand/status color —
  `lib/pulsar/components/sidebar.ex:142–150`

Browser measurement of the bordered cells: all pass — `outline-neutral` and
`solid-neutral` 4.63:1 (light) via `border-border-strong`; colored borders 5.05–8.67:1
(light) / 6.22–9.81:1 (dark) ([light](measurements/sidebar-light.md),
[dark](measurements/sidebar-dark.md)).

**Notes:** For colored `solid` panels the filled background provides the
boundary and the same-hue border is decorative reinforcement; `ghost` has no
boundary by design and `elevated` delineates with `shadow-dropdown` —
`lib/pulsar/components/sidebar.ex:151–165`. Per WCAG 1.4.11 understanding,
decorative container outlines are out of scope; the one neutral case where the
border *is* the boundary uses `border-border-strong`.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed-height text containers and no `!important` spacing
overrides; the scrollable body absorbs increased spacing —
`lib/pulsar/components/sidebar.ex:293`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The panel is driven by the `toggle/2`, `show/2`, `hide/2` helpers
bound to a caller's `<button>` (native keyboard activation) —
`lib/pulsar/components/sidebar.ex:467–485`. As a drawer it closes on Escape —
`:390–392`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The drawer focus loop is escapable — Escape closes it and returns
focus to the opener — `lib/pulsar/components/sidebar.ex:378–382, 390–392`. The
trap is only active while the mobile drawer is open — `:388–395`.

**Notes:** Matches the WAI-ARIA modal-disclosure focus pattern (focus contained,
Escape exits).

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only finite, token-driven transitions are used
(`transition-transform`, `lg:transition-[width]`, `transition-opacity`) —
`lib/pulsar/components/sidebar.ex:102–105, 121–123`. Reduced motion is honored
globally: a single `@media (prefers-reduced-motion: reduce)` rule in the theme
near-zeroes all transition durations, so the panel and backdrop snap to their end
state without animation. No looping motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; only smooth slide/width/opacity transitions —
`lib/pulsar/components/sidebar.ex:102–105, 121–123`.

### 2.4.1 Bypass Blocks (A) — ✓ PASS

**Evidence:** The panel is a labeled `<nav>` landmark, so assistive tech can jump
to or past it via landmark navigation — `lib/pulsar/components/sidebar.ex:275, 279`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`; the root carries `tabindex="-1"` only as a
programmatic focus fallback, and the drawer focuses its first focusable child on
open — `lib/pulsar/components/sidebar.ex:278, 374, 402–405`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** The landmark has a descriptive, overridable `aria-label` —
`lib/pulsar/components/sidebar.ex:279`. Test asserts default and override —
`test/pulsar/components/sidebar_test.exs:11–26, 212–221`.

### 2.4.7 Focus Visible (AA) — ✓ PASS (inferred)

**Evidence:** The component does not suppress focus indicators on interactive
slot content; `focus-visible:outline-none` is scoped to the `tabindex="-1"` root
only — `lib/pulsar/components/sidebar.ex:96, 278`. Caller links/buttons keep
their own focus rings.

**Notes:** The root is only programmatically focusable (drawer fallback), so it
is not part of the tab sequence. The measurement run flags a `focus 1.25:1`
value on the `elevated` cells — that is the tool reading the panel's decorative
`shadow-dropdown` elevation, not a focus indicator on a tab stop; the root is
`tabindex="-1"` and the only focus indicators that matter are on the caller's
interactive content.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** While the drawer is open, focus is trapped inside the on-top panel
(`z-modal`) above the backdrop (`z-overlay`), so the focused element is never
obscured — `lib/pulsar/components/sidebar.ex:99, 117, 407–419`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The backdrop dismisses on `click` (pointer-up), which is
cancellable by moving off-target before release — `lib/pulsar/components/sidebar.ex:305`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The component's only pointer target is the full-viewport backdrop —
`lib/pulsar/components/sidebar.ex:303–306`. The toggle control is caller-supplied.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the panel or its content triggers no context change; state
changes happen only on explicit toggle/show/hide events —
`lib/pulsar/components/sidebar.ex:360–365`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- `<nav>` role with `aria-label` name — `lib/pulsar/components/sidebar.ex:275, 279`
- Open/collapsed and drawer state exposed via `data-state` / `data-mobile`,
  kept in sync by the hook (including `updated/0`) — `:282–283, 441–443`
- Tests assert the data-attribute contract — `test/pulsar/components/sidebar_test.exs:69–127`

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — not hover/focus-triggered content.
- **2.1.4 Character Key Shortcuts (A)** — no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — the sidebar renders no links of its own.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.3 Label in Name (A)** — the landmark is named via `aria-label`, not a visible text control.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
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
- **4.1.3 Status Messages (AA)** — drawer state is conveyed by focus movement, not a live-region status message.

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — the backdrop dismiss target is the full
  viewport, far exceeding 44×44.

## Browser a11y findings

None. The axe gate is clean across all fixture cells in light and dark themes.
