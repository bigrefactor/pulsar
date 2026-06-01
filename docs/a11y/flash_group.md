# FlashGroup · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/flash_group.ex`](../../lib/pulsar/components/flash_group.ex)
**Tests:** [`test/pulsar/components/flash_group_test.exs`](../../test/pulsar/components/flash_group_test.exs)
**Audited:** 2026-05-24 (code-only)

Fixed-position layout container that reads Phoenix.Flash messages, maps
each type to color/icon/role, and renders them as stacked
`Pulsar.Components.Flash` children with staggered entry animations. Has
no interactive controls of its own — all interaction lives in the child
flashes.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Icons supplied per flash via the `start_icon` slot,
sourced from Heroicons by type (`hero-x-circle`, `hero-check-circle`,
etc.) — `lib/pulsar/components/flash_group.ex:236–242, 460–462`. The
`Pulsar.Components.Icon.icon` component handles its own
`aria-hidden`/`aria-label`.

**Notes:** FlashGroup itself renders no images; delegates icon
accessibility to `Icon` and meaningful text to the message content.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Each flash gets `role={get_flash_role(type)}` — `alert` for error and
  warning, `status` for the rest — `lib/pulsar/components/flash_group.ex:229–233,
  444, 499–501`
- Messages render in a single `<div>` container with `flex flex-col`
  (or `flex-col-reverse` for bottom positions) — programmatic stacking
  matches visual stacking — `lib/pulsar/components/flash_group.ex:245–276`
- Tests assert correct `role="alert"` count for error/warning and
  `role="status"` count for info/success —
  `test/pulsar/components/flash_group_test.exs:226–253`

**Notes:** Each flash carries its own ARIA semantics; the container is a
plain stacking layout with no role of its own (acceptable — `region`
landmark would over-promise, and the live regions are on each child).

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:**
- Messages sorted by `flash_priority/1`: error → warning → info →
  success → other — `lib/pulsar/components/flash_group.ex:480–491`
- Top positions use `flex flex-col`; bottom positions use
  `flex flex-col-reverse` so the first-priority message visually appears
  closest to the screen edge — `lib/pulsar/components/flash_group.ex:246–275`
- Tests assert priority ordering is preserved across renders —
  `test/pulsar/components/flash_group_test.exs:570–640`

**Notes:** DOM order is deterministic by priority. `flex-col-reverse`
visually reverses but does NOT reorder the focus/reading sequence per
spec — bottom-positioned stacks keep highest-priority message at the
bottom (closest to screen edge), which matches user expectation for a
toast stack growing upward.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Type-to-icon mapping ensures every flash gets a
semantic icon paired with text — `lib/pulsar/components/flash_group.ex:236–242,
460–462`. Type-to-role mapping (`alert` vs `status`) provides a
non-visual criticality signal — `lib/pulsar/components/flash_group.ex:229–233`.

**Notes:** Status is conveyed via icon, text, role, and live region —
never by color alone or position alone.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Same as 1.3.3 — color is one of four redundant signals
(color, icon, role, text content) —
`lib/pulsar/components/flash_group.ex:220–242, 441–462`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Container uses `max-w-sm w-full` on all positions —
`lib/pulsar/components/flash_group.ex:247–275`. At 320 CSS px viewport,
`max-w-sm` (24rem = 384px) is capped by `w-full` to the viewport width.

**Notes:** `top-center` and `bottom-center` use
`left-1/2 -translate-x-1/2` which centers properly at all widths —
`lib/pulsar/components/flash_group.ex:247, 262`. Left and right
positions use `left-4`/`right-4` (1rem inset) and reflow gracefully.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** No focus indicators on the container itself (no
focusable element). Child flashes carry their own focus rings (see
`flash.md` 1.4.11). Container has no visible borders or non-text UI of
its own — `lib/pulsar/components/flash_group.ex:433–437`. Browser
measurement: 6 cells, no borders, no focus rings to evaluate
([light](measurements/flash_group-light.md),
[dark](measurements/flash_group-dark.md)).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights on the container; gap and inset are
rem-based (`gap-2`, `top-4`, `bottom-4`, etc.) —
`lib/pulsar/components/flash_group.ex:247–275`. No `!important` on
spacing.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** Container is `pointer-events-none` so it doesn't intercept
hover — `lib/pulsar/components/flash_group.ex:426–427`. Hover/focus
behavior on individual flashes is covered in `flash.md` 1.4.13.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Container has no interactive elements of its own —
`lib/pulsar/components/flash_group.ex:433–465`. Each child flash's
close button is keyboard-operable (covered in `flash.md` 2.1.1).

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Container has no focus handlers; child flashes don't
trap Tab — `lib/pulsar/components/flash_group.ex:433–465`,
`lib/pulsar/components/flash.ex:383–390`.

### 2.2.1 Timing Adjustable (A) — ✓ PASS

**Evidence:** Group-level controls expose all timing knobs to callers:
`auto_dismiss` boolean, `dismiss_after` integer, `dismissible` boolean —
`lib/pulsar/components/flash_group.ex:307–321`. Per-child behavior
covered in `flash.md` 2.2.1.

**Notes:** Callers can disable auto-dismiss globally
(`auto_dismiss={false}`) at the group level.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Stagger animation completes in `index * stagger_delay`
ms then settles; no continuous motion — `lib/pulsar/components/flash_group.ex:555–560`.
Hide via dismiss covered in `flash.md` 2.2.2.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are CSS `transition` on opacity/translate
in `phx-mounted` JS hooks — `lib/pulsar/components/flash_group.ex:450–458`.
No flashing/blinking.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:**
- Messages render in deterministic priority order in the DOM —
  `lib/pulsar/components/flash_group.ex:480–491`
- No positive `tabindex` values used — only the close buttons inside
  child flashes are focusable, in DOM order —
  `lib/pulsar/components/flash_group.ex:438–464`
- Tests assert consistent DOM order across renders —
  `test/pulsar/components/flash_group_test.exs:598–640`

**Notes:** Bottom-positioned groups use `flex-col-reverse` for visual
stack-growth direction but DOM order (and therefore tab/focus order)
stays priority-first. Visual mismatch only matters when sighted
keyboard users tab the closes — they'll see focus jump bottom-to-top in
those positions. Documented stack behavior, not a bug.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Container has no focusable elements of its own —
`lib/pulsar/components/flash_group.ex:433–465`. Focus visibility on
child close buttons covered in `flash.md` 2.4.7.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — caller responsibility

**Evidence:** Container is `fixed` at one of six edge positions with
`z-50` default — `lib/pulsar/components/flash_group.ex:335–339, 245–276,
563–571`. `pointer-events-none` on the container —
`lib/pulsar/components/flash_group.ex:426–427` — means clicks pass
through, but focus visibility under the flash stack is still a
visual-overlap concern when focused page elements sit at the same edge.

Manual browser verification: with the fixture's default
`bottom-right` placement and a stacked toast (`max-w-sm` ≈ 384px),
focused buttons in the bottom-right corner of the viewport are
obscured by an active flash. The `max-w-sm` width keeps the
affected area small but doesn't eliminate the overlap.

**Notes:** WCAG 2.4.11 (Minimum) allows the user to scroll the focused
element into view; toast notifications that auto-dismiss within a few
seconds are a recognized acceptable pattern (per WCAG 2.4.11
Understanding). For long-lived toasts (`role="alert"` flashes, or any flash
with `auto_dismiss={false}`) and focusable controls at the same edge, a
caller-level fix is required
(e.g. `scroll-margin-bottom` on focusable elements or relocating the
flash group). Not a component-internal gap.

**Decision:** documented as caller responsibility — no component-internal
change. The component's usage docs now carry a "Long-lived toasts and
focus" note covering the `auto_dismiss={false}` + edge-control case (pick a
`position` away from the controls, or add a matching `scroll-margin`).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Container has no click handlers; child flash dismiss is
covered in `flash.md` 2.5.2 —
`lib/pulsar/components/flash_group.ex:433–465`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Container has no interactive targets —
`lib/pulsar/components/flash_group.ex:433–465`. Child close-button
target sizing is covered in `flash.md` 2.5.8.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handlers on the container —
`lib/pulsar/components/flash_group.ex:433–465`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Container is a plain `<div>` with no implicit interactive
role — `lib/pulsar/components/flash_group.ex:433–437`. Each child flash
carries `role`, `aria-live`, `aria-atomic`, and the dismiss button
carries `aria-label` and `aria-controls` (see `flash.md` 4.1.2).

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** Each rendered flash gets a `role` (`alert` or `status`)
and matching `aria-live` from `get_flash_role/1` and the child Flash
component — `lib/pulsar/components/flash_group.ex:229–233, 444,
499–501`; tests assert alert vs status by type —
`test/pulsar/components/flash_group_test.exs:226–253`.

**Notes:** New flashes appended via `phx-mounted` JS show transition
mount into a live region, so screen readers announce as they arrive.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.3 Contrast (Minimum) (AA)** — container has no text of its own; child text-contrast covered in `flash.md`.
- **1.4.4 Resize Text (AA)** — container has no text of its own.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts registered.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — no headings or labels.
- **2.5.1 Pointer Gestures (A)** — no multipoint or path gestures.
- **2.5.3 Label in Name (A)** — no labeled targets at this level.
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

## AAA wins (bonus)

- **2.4.12 Focus Not Obscured (Enhanced) (AAA, new in 2.2)** — same
  posture as 2.4.11; toast positioning at viewport edges + `max-w-sm`
  cap limits the obscured area to the corner. AAA forbids *any*
  obscuring; toast pattern inherently overlaps content, so this is
  noted-but-unmet by design.
- **2.5.5 Target Size (Enhanced) (AAA)** — N/A at container level; no
  targets.
