# Resizable · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/resizable.ex`](../../lib/pulsar/components/resizable.ex)
**Tests:** [`test/pulsar/components/resizable_test.exs`](../../test/pulsar/components/resizable_test.exs)
**Audited:** 2026-06-09 (code + browser axe gate)

Resizable splits a region into two panels divided by a draggable handle. The
handle is a WAI-ARIA window-splitter: a focusable `role="separator"` that resizes
the second panel by pointer drag or keyboard. Collapse is per-panel and opt-in
(`collapsible` on the `<:panel>` slot); either side may be collapsible (mutually
exclusive or both). When a panel is collapsible, a pill centered on the handle
holds one focusable `<button>` per collapsible panel — each independently
keyboard-operable (Tab to focus, Enter/Space to toggle). The component stays in
document flow and does not trap focus.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The handle is `role="separator"` with `aria-controls` referencing
both panels it operates on and `aria-valuemin`/`aria-valuenow`/`aria-valuemax`
(plus `aria-valuetext` for a human-readable percentage) reflecting the controlled
panel's size. The hook keeps `aria-valuenow` and `aria-valuetext` in sync on every
resize and collapse event.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:130–139`
(separator markup: `role="separator"` at 130, `tabindex` at 132,
`aria-orientation` at 133, `aria-controls` at 134, `aria-label` at 135,
`aria-valuemin` at 136, `aria-valuenow` at 137, `aria-valuetext` at 138) and
`lib/pulsar/components/resizable.ex:365–368`
(hook sync: comment + `setAttribute("aria-valuenow")`). Tests `renders a
window-splitter separator handle` and `reflects the controlled panel range on
the separator` — `test/pulsar/components/resizable_test.exs:28–41`.

### 1.3.4 Orientation (AA) — ✓ PASS

**Evidence:** A horizontal split exposes a vertical separator
(`aria-orientation="vertical"`) and a vertical split a horizontal one — the
separator orientation is inverted relative to the panel layout, per the APG
window-splitter pattern.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:133` (attribute
emission), `lib/pulsar/components/resizable.ex:411–412` (`separator_orientation/1`
helper). Test `inverts orientation: horizontal split uses a vertical separator` —
`test/pulsar/components/resizable_test.exs:43–46`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The separator is `tabindex="0"`. Arrow keys resize ±1%, Page
Up/Down ±10%, Home/End jump to min/max; double-click resets to the default. The
`Enter`-on-separator collapse path has been removed — collapse/expand is
exclusively via the focusable pill buttons and drag-to-edge. Each per-panel
chevron is a real `<button>` (`type="button"`) in the tab order — no
`tabindex="-1"` — so Tab reaches it and Enter/Space triggers `toggleCollapse`.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:132` (`tabindex="0"`
on separator), `lib/pulsar/components/resizable.ex:146–167` (pill buttons —
`type="button"`, no negative tabindex), `lib/pulsar/components/resizable.ex:292–312`
(hook `onKeydown`: arrow/Page/Home/End at lines 301–306; no `"Enter"` case —
Enter is handled natively by the focused button),
`lib/pulsar/components/resizable.ex:322–331` (`toggleCollapse`). Tests
`toggles are real focusable buttons (no negative tabindex)` —
`test/pulsar/components/resizable_test.exs:139–143`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The handle shows a `focus-visible:ring-2 focus-visible:ring-ring
focus-visible:ring-offset-1` ring; the visual divider line shifts to `bg-primary`
on `group-focus-visible`. Each chevron button also carries
`focus-visible:ring-2 focus-visible:ring-ring` (inset).

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:434–438`
(`handle_classes/1` — vertical, `focus-visible:ring-2` at line 436),
`lib/pulsar/components/resizable.ex:440–444`
(`handle_classes/1` — horizontal, `focus-visible:ring-2` at line 442),
`lib/pulsar/components/resizable.ex:479`
(toggle `focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring`).

### 2.5.7 Dragging Movements (AA) — ✓ PASS

**Evidence:** Every drag action has a non-drag equivalent: keyboard resize on the
focused separator (arrow keys, Page Up/Down, Home/End), and collapse/expand via
the pill `<button>`(s) — one focusable chevron button per collapsible panel,
each triggering `toggleCollapse` on click.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:145–168`
(collapse pill with per-panel buttons), `lib/pulsar/components/resizable.ex:292–312`
(keyboard resize in `onKeydown`), `lib/pulsar/components/resizable.ex:322–331`
(`toggleCollapse`).

### 2.5.8 Target Size (Minimum) (AA) — ✓ PASS

**Evidence:** The handle's grab zone is at least 24 px (`h-6` for vertical
handles, `w-6` for horizontal) with a thinner visual line centered inside it. Each
chevron button is `size-6` (24 × 24 px) — documented in the comment at lines
471–473 and applied by `toggle_button_classes/2`.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:428–429`
(`handle_wrapper_classes/1`, `h-6` at line 428 for vertical, `w-6` at line 429
for horizontal), `lib/pulsar/components/resizable.ex:434–444`
(`handle_classes/1` — the `absolute inset-0` fill that makes the wrapper the
true pointer target), `lib/pulsar/components/resizable.ex:471–482`
(`toggle_button_classes/2` comment + `size-6` at line 477).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Separator role + value attributes as above. Each collapse toggle is
a `<button>` with:

- `aria-expanded` — set to `"true"` in markup (line 150/161) and kept in sync by
  `updateToggle` (line 340) on every `setCollapsed` call, including across LiveView
  re-renders via `updated()` (line 200).
- `aria-controls` → its own panel id (start button at line 151, end button at
  line 162).
- `aria-label` derived from the panel's `label` slot attribute (line 152/163).

`aria-valuenow` on the separator now has two documented out-of-`[min,max]`
states: `0` when the end panel is collapsed, and up to `100` when the start panel
is collapsed. Both are permitted by the APG window-splitter collapse exception
(comment at lines 365–367, `setAttribute` at line 368).

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:130` (role),
`lib/pulsar/components/resizable.ex:135` (separator `aria-label`),
`lib/pulsar/components/resizable.ex:146–167` (both toggle buttons with
`aria-expanded`/`aria-controls`/`aria-label`),
`lib/pulsar/components/resizable.ex:332–343` (`setCollapsed` + `updateToggle`,
`aria-expanded` sync at line 340),
`lib/pulsar/components/resizable.ex:200–216` (`updated()` re-asserts collapsed
state on LiveView patch),
`lib/pulsar/components/resizable.ex:365–368` (valuenow out-of-range comment +
setAttribute). Tests `marking the end panel collapsible renders one end toggle`,
`marking both panels collapsible renders two toggles, one per side`,
`toggles are real focusable buttons (no negative tabindex)`, `toggles start
expanded` — `test/pulsar/components/resizable_test.exs:107–148`.

## Not applicable

- **1.1.1 Non-text Content (A)** — the only non-text element is the decorative
  chevron icon inside each collapse toggle; it is presentational alongside the
  toggle's own `aria-label`.
- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — panels render in slot order; no visual
  reordering.
- **1.3.3 Sensory Characteristics (A)** — resize state is communicated
  programmatically via `aria-valuenow`/`aria-expanded`, not by shape or position
  alone.
- **1.3.5 Identify Input Purpose (AA)** — not a form input collecting user info.
- **1.4.1 Use of Color (A)** — handle focus/hover shifts are also exposed via
  the `focus-visible` ring and `aria-*` state, not by color alone.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.3 Contrast (Minimum) (AA)** — the handle line and toggle draw from
  `border-strong` / `foreground` / `primary` tokens already verified elsewhere;
  the component renders no text of its own.
- **1.4.4 Resize Text (AA)** — no text rendered by the component.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.10 Reflow (AA)** — the group uses `w-full h-full` flex; no fixed
  minimum width is imposed on the container.
- **1.4.11 Non-text Contrast (AA)** — the resting divider line is
  `border-strong` (gray-500, ≈3.9:1 on the panel surfaces), darkening to
  `foreground` on hover and `primary` on focus — every state clears the 3:1
  non-text floor, so the resize affordance is identifiable at rest, not only on
  interaction. Evidence: `lib/pulsar/components/resizable.ex:447–455`
  (`line_classes/1`).
- **1.4.12 Text Spacing (AA)** — no text rendered.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered
  supplementary content.
- **2.1.2 No Keyboard Trap (A)** — the separator is a single tab stop in
  document flow; the pill buttons are additional tab stops but no Tab/Shift+Tab
  handling is registered to intercept focus.
- **2.1.4 Character Key Shortcuts (A)** — arrow/Page/Home/End are navigation
  keys, not single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — only a sub-second collapse transition; no
  auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — the separator (`tabindex="0"`) and each pill
  button are natural tab stops in document order; no artificial reordering.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — separator `aria-label` is caller-supplied
  via the `label` slot attribute; the component renders it faithfully.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — linear in-flow
  render; the component creates no sticky or overlapping content.
- **2.5.1 Pointer Gestures (A)** — no path-based or multi-point gestures.
- **2.5.2 Pointer Cancellation (A)** — resize commits on `pointerup`/`lostpointercapture`, not `pointerdown`.
- **2.5.3 Label in Name (A)** — each toggle's accessible name matches its
  visible purpose (chevron icon with `aria-label`); no contradicting visible
  label.
- **2.5.4 Motion Actuation (A)** — no device-motion functionality.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — focusing the separator does not resize; only explicit
  keystrokes do.
- **3.2.2 On Input (A)** — resizing does not trigger navigation or form
  submission.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.3 Status Messages (AA)** — `aria-valuenow`/`aria-valuetext` on the live
  separator communicate state in-place; no separate live region is needed.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  minimum thickness, and the `--color-ring` token clears AAA contrast —
  `lib/pulsar/components/resizable.ex:436, 442, 479`.

## Browser a11y findings

None. The axe gate at `/components/resizable/horizontal` and
`/components/resizable/vertical` is clean.
