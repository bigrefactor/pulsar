# Resizable · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/resizable.ex`](../../lib/pulsar/components/resizable.ex)
**Tests:** [`test/pulsar/components/resizable_test.exs`](../../test/pulsar/components/resizable_test.exs)
**Audited:** 2026-06-09 (code + browser axe gate)

Resizable splits a region into two panels divided by a draggable handle. The
handle is a WAI-ARIA window-splitter: a focusable `role="separator"` that resizes
the second panel by pointer drag or keyboard, with an optional collapse toggle.
It stays in document flow and does not trap focus.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The handle is `role="separator"` with `aria-controls` referencing
both panels it operates on and `aria-valuemin`/`aria-valuenow`/`aria-valuemax`
(plus `aria-valuetext` for a human-readable percentage) reflecting the controlled
panel's size. The hook keeps `aria-valuenow` and `aria-valuetext` in sync on every
resize and collapse event.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:106–114`
(separator markup: `role="separator"` at 106, `tabindex` at 108,
`aria-orientation` at 109, `aria-controls` at 110, `aria-label` at 111,
`aria-valuemin` at 112, `aria-valuenow` at 113, `aria-valuetext` at 114) and
`lib/pulsar/components/resizable.ex:288–289, 315–316`
(hook sync). Tests `renders a window-splitter separator handle` and
`reflects the controlled panel range on the separator` —
`test/pulsar/components/resizable_test.exs:28–41`.

### 1.3.4 Orientation (AA) — ✓ PASS

**Evidence:** A horizontal split exposes a vertical separator
(`aria-orientation="vertical"`) and a vertical split a horizontal one — the
separator orientation is inverted relative to the panel layout, per the APG
window-splitter pattern.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:109` (attribute
emission), `lib/pulsar/components/resizable.ex:331–332` (`separator_orientation/1`
helper). Test `inverts orientation: horizontal split uses a vertical separator` —
`test/pulsar/components/resizable_test.exs:43–46`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The separator is `tabindex="0"`. Arrow keys resize ±1%, Page
Up/Down ±10%, Home/End jump to min/max, and (when collapsible) Enter collapses or
expands the panel; double-click resets to the default. The collapse toggle is a
real `<button>`, operable by Enter/Space.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:108` (`tabindex="0"`),
`lib/pulsar/components/resizable.ex:241–264` (hook `onKeydown` handler, including
`"Enter"` at line 243, arrow/Page/Home/End at lines 252–258).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The handle shows a `focus-visible:ring-2 focus-visible:ring-ring
focus-visible:ring-offset-1` ring; the visual divider line shifts to `bg-primary`
on `group-focus-visible`. The collapse toggle also carries
`focus-visible:ring-2 focus-visible:ring-ring`.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:354–357`
(`handle_classes/1` — vertical), `lib/pulsar/components/resizable.ex:360–363`
(`handle_classes/1` — horizontal), `lib/pulsar/components/resizable.ex:391`
(toggle `focus-visible` ring).

### 2.5.7 Dragging Movements (AA) — ✓ PASS

**Evidence:** Every drag action has a non-drag equivalent: keyboard resize on the
focused separator (arrow keys, Page Up/Down, Home/End), plus the collapse toggle
`<button>` and Enter-to-toggle on the focused separator.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:121–132`
(collapse toggle `<button>`), `lib/pulsar/components/resizable.ex:241–264`
(keyboard resize in `onKeydown`).

### 2.5.8 Target Size (Minimum) (AA) — ✓ PASS

**Evidence:** The handle's grab zone is at least 24 px (`w-6` for horizontal
handles, `h-6` for vertical) with a thinner visual line centered inside it. The
comment at lines 351–352 documents this explicitly.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:347–349`
(`handle_wrapper_classes/1`, `h-6` at line 348 for vertical, `w-6` at line 349
for horizontal) and `lib/pulsar/components/resizable.ex:353–364`
(`handle_classes/1` — the `absolute inset-0` fill that makes the wrapper the
true click/pointer target).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Separator role + value attributes as above; the collapse toggle
carries `aria-expanded` (kept in sync by the hook across LiveView re-renders via
`setCollapsed`), `aria-controls`, and an `aria-label` derived from the second
panel's `label`.

**Evidence line numbers:** `lib/pulsar/components/resizable.ex:106` (role),
`lib/pulsar/components/resizable.ex:111` (separator `aria-label`),
`lib/pulsar/components/resizable.ex:124–127` (toggle `data-resizable-toggle`,
`tabindex="-1"`, `aria-expanded`, `aria-controls`),
`lib/pulsar/components/resizable.ex:128` (toggle `aria-label`),
`lib/pulsar/components/resizable.ex:282` (hook syncs `aria-expanded` on collapse).
Tests `renders an accessible chevron toggle when collapsible` and
`toggle is not a tab stop (the separator already is)` —
`test/pulsar/components/resizable_test.exs:94–112`.

## Not applicable

- **1.1.1 Non-text Content (A)** — the only non-text element is the decorative
  chevron icon inside the collapse toggle; it is presentational alongside the
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
  `border` / `border-strong` / `primary` tokens already verified elsewhere; the
  component renders no text of its own.
- **1.4.4 Resize Text (AA)** — no text rendered by the component.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.10 Reflow (AA)** — the group uses `w-full h-full` flex; no fixed
  minimum width is imposed on the container.
- **1.4.11 Non-text Contrast (AA)** — handle and divider line colors route
  through `border-border` / `border-border-strong` / `primary` tokens verified
  for 3:1 in the shared token audit.
- **1.4.12 Text Spacing (AA)** — no text rendered.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered
  supplementary content.
- **2.1.2 No Keyboard Trap (A)** — the separator is a single tab stop in
  document flow; no Tab/Shift+Tab handling is registered.
- **2.1.4 Character Key Shortcuts (A)** — arrow/Page/Home/End are navigation
  keys, not single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — only a sub-second collapse transition; no
  auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — the separator is a single `tabindex="0"` stop;
  the toggle is `tabindex="-1"` (not in tab order) and is reachable by Enter on
  the focused separator.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — separator `aria-label` is caller-supplied
  via the `label` slot attribute; the component renders it faithfully.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — linear in-flow
  render; the component creates no sticky or overlapping content.
- **2.5.1 Pointer Gestures (A)** — no path-based or multi-point gestures.
- **2.5.2 Pointer Cancellation (A)** — resize commits on `pointerup`/`lostpointercapture`, not `pointerdown`.
- **2.5.3 Label in Name (A)** — the toggle's accessible name matches its visible
  purpose (chevron icon with `aria-label`); no contradicting visible label.
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
  `lib/pulsar/components/resizable.ex:354, 360, 391`.

## Browser a11y findings

None. The axe gate at `/components/resizable/horizontal` and
`/components/resizable/vertical` is clean.
