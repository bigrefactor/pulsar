# Tooltip · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/tooltip.ex`](../../lib/pulsar/components/tooltip.ex)
**Tests:** [`test/pulsar/components/tooltip_test.exs`](../../test/pulsar/components/tooltip_test.exs)
**Audited:** 2026-06-03 (code-only)

Hover/focus label that describes its trigger. Built on the popover primitive in
hover mode (`trigger_mode="hover"`, rendered as a transparent `variant="ghost"`
shell): the `.PulsarPopover` colocated hook opens a `popover="manual"` panel
carrying `role="tooltip"` on pointer hover (after a short delay) and on keyboard
focus (immediately), and wires `aria-describedby` from the trigger to the panel so
the hint is announced as the trigger's description. It closes on leave, blur, or
Escape; the close is delayed by a short grace period so the pointer can travel
onto the (hoverable) hint. The surface is an opaque solid (neutral default plus
the semantic colors), each a fill paired with its readable foreground. Content is
plain, non-interactive text; a decorative caret (on by default) borrows the
panel's fill and points at the trigger.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content is the caret, which is decorative and
marked `aria-hidden="true"` — `lib/pulsar/components/tooltip.ex:191`. The hint
itself is caller-supplied text.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The panel carries `role="tooltip"` and the hook stamps
`aria-describedby` on the trigger pointing at the panel `id`, so the
trigger→hint relationship is programmatic — `lib/pulsar/components/tooltip.ex:186`,
`lib/pulsar/components/popover.ex:291` (hover-mode `setupHover`), `:455` (`updated`
re-sync). The keyboard fixture asserts the `aria-describedby` linkage —
`test/integration/a11y/keyboard_test.exs`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Each surface pairs an opaque fill with its readable foreground —
`bg-{color} text-{color}-foreground` — `lib/pulsar/components/tooltip.ex:65–73`.
These are the same `*-foreground` pairs Button uses (the browser-verified palette),
so the hint clears 4.5:1 on every color in both themes. The axe gate scans the
`/components/tooltip` fixture in light and dark.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** The hint uses `text-sm` (a `rem`-based size) and a `max-w-xs` cap, so
text scales with the user's font size and wraps rather than clipping —
`lib/pulsar/components/tooltip.ex:90`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The tooltip sizes to its content with no min-width floor (`min-w-0`)
and a `max-w-xs` cap, and the hook positions it with an 8px viewport margin and
both-axes shift-clamping, so it never forces horizontal scrolling at 320px —
`lib/pulsar/components/tooltip.ex:90`, `lib/pulsar/components/popover.ex:426–431`
(`position`).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The caret is not an independent UI control — it borrows the panel's
opaque fill (`bg-inherit`) and reads as part of the same surface, so it needs no
contrast of its own — `lib/pulsar/components/tooltip.ex:95`. The tooltip surface
itself is a filled shape against the page, not a bordered control.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** The hint satisfies all three requirements:

- **Dismissable:** Escape hides it (and keeps it dismissed until the trigger is
  left and re-entered) without moving the pointer —
  `lib/pulsar/components/popover.ex:314–318`.
- **Hoverable:** leaving the trigger starts a short close timer rather than hiding
  immediately, and `mouseenter` on the panel cancels it, so the pointer can move
  onto the hint — `lib/pulsar/components/popover.ex:307–310` (`_closeSoon`),
  `:327` (panel `mouseenter` → `_cancelClose`).
- **Persistent:** it stays open while hovered/focused with no timeout; it closes
  only on leave, blur, or Escape — `lib/pulsar/components/popover.ex:284–336`.

The keyboard fixture asserts focus-to-open and Escape-to-dismiss —
`test/integration/a11y/keyboard_test.exs`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The hint is reachable without a pointer: focusing the trigger opens
it immediately, and Escape dismisses it — `lib/pulsar/components/popover.ex:300–304`
(`_openNow` on `focusin`), `:308–312` (Escape). The keyboard fixture exercises
both — `test/integration/a11y/keyboard_test.exs`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The hint is non-interactive text and is not focusable; nothing holds
focus, and Tab moves on from the trigger normally —
`lib/pulsar/components/tooltip.ex:191`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** A closed panel is `display:none` (native `[popover]` rule) and its
text content is non-focusable, so it never enters the tab order; no positive
`tabindex` is used — `lib/pulsar/components/popover.ex:240–254`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The panel suppresses only its own ring (`focus-visible:outline-none`,
inherited from the popover base); the caller's trigger keeps its focus ring —
`lib/pulsar/components/popover.ex:92` (`@panel_base_classes`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The panel renders in the browser top layer (native popover), so it is
never clipped by `overflow:hidden` ancestors, and the hook flips it to the opposite
side when the requested side lacks room — `lib/pulsar/components/popover.ex:401–411`
(`position`). The trigger itself is never covered (the panel is offset from it).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The tooltip exposes no pointer-activated action — it only appears on
hover/focus and is supplementary; the described action lives on the caller's
trigger. No functionality is triggered on pointer-down.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The trigger is caller-supplied (e.g. Pulsar `Button`, which meets
24×24); the tooltip imposes no sub-24px target — caller responsibility.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the trigger reveals the hint, which is supplementary content
— not a change of context (no focus move, navigation, or content reorder) —
`lib/pulsar/components/popover.ex:300–304`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** The panel exposes `role="tooltip"`; the trigger exposes
`aria-describedby` pointing at it — `lib/pulsar/components/tooltip.ex:186`,
`lib/pulsar/components/popover.ex:285`. Unit tests assert the role and the
hover/manual wiring — `test/pulsar/components/tooltip_test.exs`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — DOM order matches visual order; no reordering.
- **1.3.3 Sensory Characteristics (A)** — no instructions relying on shape/position.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — the hint conveys meaning through text, not color.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.12 Text Spacing (AA)** — no `!important` spacing; short text inherits page spacing and wraps under `max-w-xs`.
- **2.1.4 Character Key Shortcuts (A)** — only Escape, no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit (the open/close delays are sub-second affordances, not a content time limit).
- **2.2.2 Pause, Stop, Hide (A)** — the only motion is a sub-second entrance fade on open (`animate-fade-in`), below the 5s threshold and near-zeroed by the global reduced-motion rule; no continuous or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing; the entrance is a single opacity fade.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — the hint is plain text, not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — caller supplies the trigger's name.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.3 Label in Name (A)** — caller supplies the trigger and its name.
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
- **4.1.3 Status Messages (AA)** — the hint is a description, not a status message (it isn't announced on a live region).

## Browser a11y findings

None. The axe gate is clean across the `/components/tooltip` fixture cells in
light and dark themes.
