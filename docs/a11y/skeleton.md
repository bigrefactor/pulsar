# Skeleton · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/skeleton.ex`](../../lib/pulsar/components/skeleton.ex)
**Tests:** [`test/pulsar/components/skeleton_test.exs`](../../test/pulsar/components/skeleton_test.exs)
**Audited:** 2026-06-04 (code-only + browser measurement)

Presentational loading placeholder. Renders muted, gently pulsing shapes — a text
line (or several), a circle, or a rectangular block — that stand in for content
while it loads. Shapes are decorative; an optional `label` wraps them in a polite
`role="status"` region. A `animate_text` mode pulses real inline text. The
component is non-interactive (no focusable elements).

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The placeholder shapes carry `aria-hidden="true"`
(`lib/pulsar/components/skeleton.ex:188, 191`) so they are exposed to assistive
tech as nothing rather than as meaningless graphics. When `label` is set the
shapes are wrapped in a `role="status" aria-busy="true" aria-label={label}`
region that provides the text alternative for the loading state
(`lib/pulsar/components/skeleton.ex:130`). In `animate_text` mode the inner text
is real content, exposed unless a label already announces the region
(`lib/pulsar/components/skeleton.ex:187`).

**Notes:** Without a `label`, a skeleton is purely decorative — the correct
treatment for a placeholder whose meaning ("loading") is better conveyed by a
surrounding region the caller controls.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** A single shape is one element; multi-line text is a flat flex
column of bars (`lib/pulsar/components/skeleton.ex:188–190`); the optional status
region is a single wrapper (`lib/pulsar/components/skeleton.ex:130`). No implied
structure to expose.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order matches visual order; stacked lines render top-to-bottom
in source order (`lib/pulsar/components/skeleton.ex:189`). No reordering CSS.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on the shape, size, or position of a
placeholder; the shapes carry no operable meaning.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** "Loading" is conveyed by the motion of the placeholder and, when
provided, the `role="status"` announcement (`lib/pulsar/components/skeleton.ex:130`)
— never by color alone. The muted fill (`lib/pulsar/components/skeleton.ex:61`)
is decorative.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** The placeholder shapes contain no text. The only text the component
renders is the `animate_text` content, which uses `text-foreground`
(`lib/pulsar/components/skeleton.ex:83`) — not `text-muted-foreground` — so it
clears the 4.5:1 minimum by a wide margin in both themes. Browser measurement of
the text-bearing cells (`animate-text`, `labelled`, `lines-3`): min **19.27:1
light** / **16.98:1 dark**
([light](measurements/skeleton-light.md), [dark](measurements/skeleton-dark.md)).

**Notes:** The muted shapes are decorative (`aria-hidden`); body-text contrast
does not apply to them (see 1.4.11).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All dimensions use `rem`-based Tailwind tokens (`h-4`, `w-*`,
circle `w-6 h-6`…`w-16 h-16`) — `lib/pulsar/components/skeleton.ex:65–79, 210`.
No fixed `px`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Widths are class-driven (default `w-full`), with no fixed-`px`
minimum; multi-line stacks use `flex flex-col`
(`lib/pulsar/components/skeleton.ex:183`). Placeholders reflow at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The placeholder shapes are decorative and marked `aria-hidden`
(`lib/pulsar/components/skeleton.ex:188, 191`); WCAG exempts decorative content
from the 3:1 non-text minimum. The component draws no borders, focus rings, or
icons that convey state.

**Notes:** `bg-muted` is intentionally low-contrast — a placeholder must read as
inactive. It carries no information, so the exemption applies.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed line-height or letter/word-spacing overrides; the
`animate_text` span inherits page text-spacing
(`lib/pulsar/components/skeleton.ex:187`).

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The pulse is a subtle 2s opacity oscillation (1 ↔ .85) defined by
`animate-pulse-subtle` (`lib/pulsar/components/skeleton.ex:61, 83`). The
library-wide `prefers-reduced-motion: reduce` rule zeroes the animation, giving
users a mechanism to stop it. The animation is also a transient loading
indicator that disappears when real content replaces the skeleton.

**Notes:** The oscillation never approaches transparency, so the placeholder is
not "blinking" in the distracting sense; reduced-motion users see a static
shape.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** The pulse completes one cycle every 2s (0.5 Hz) —
`lib/pulsar/components/skeleton.ex:61` — far below the 3-flashes-per-second
threshold, and it is an opacity fade rather than a flash.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Decorative shapes are `aria-hidden` with no role
(`lib/pulsar/components/skeleton.ex:188, 191`). When announcing, the wrapper
exposes `role="status"`, `aria-busy="true"`, and an `aria-label`
(`lib/pulsar/components/skeleton.ex:130`). `@rest` forwards `id`/`data-*`/ARIA
(`lib/pulsar/components/skeleton.ex:112, 191`).

**Notes:** Tests confirm the decorative default and the status wrapper —
`test/pulsar/components/skeleton_test.exs:100–117`.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** With `label`, the loading state is a status message:
`role="status" aria-busy="true"` announces it politely without moving focus
(`lib/pulsar/components/skeleton.ex:130`). Removing the skeleton (rendering the
real content) flips the region's busy state off.

**Notes:** Without `label` the skeleton is silent decoration — the caller's
surrounding region carries the status. This is documented in the moduledoc
(`lib/pulsar/components/skeleton.ex:40–46`).

## Not applicable

- **1.2.1–1.2.5 Time-based Media (A/AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — renders no text as images.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-revealed content.
- **2.1.1 Keyboard (A)** — non-interactive; nothing to operate.
- **2.1.2 No Keyboard Trap (A)** — no focusable content.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit (the pulse is not a time limit).
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — no focusable content.
- **2.4.4 Link Purpose (A)** — no links.
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

The axe-core browser gate reports no violations for the Skeleton fixture in
either theme. Measurement detail: [light](measurements/skeleton-light.md) ·
[dark](measurements/skeleton-dark.md).
