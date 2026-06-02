# Popover · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/popover.ex`](../../lib/pulsar/components/popover.ex)
**Tests:** [`test/pulsar/components/popover_test.exs`](../../test/pulsar/components/popover_test.exs)
**Audited:** 2026-06-02 (code-only)

Anchored, dismissible, non-modal overlay built on the native HTML Popover API.
A trigger button (wired with `aria-controls`/`aria-expanded` by the
`.PulsarPopover` colocated hook) opens a `popover="auto"` panel anchored to it;
the browser handles light-dismiss (outside click + Escape); Escape returns focus to the trigger.
The panel imposes no role; callers pass `role="dialog"` and a name when needed.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The trigger's `aria-controls` points at the panel `id`, and the
hook keeps `aria-expanded` in sync as the panel opens and closes — see the
`mounted`/`onToggle` wiring in `lib/pulsar/components/popover.ex:233–275`. The keyboard
fixture asserts the expanded state on open/close — `test/integration/a11y/keyboard_test.exs`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Panel surfaces use the same semantic-token matrix as Card:
`elevated`/`outline` pair `bg-surface-1` with default foreground; `solid` uses a
`bg-{color}/10` tint that keeps content on the inherited foreground; borders use
`border-{color}` / `border-border-strong` — `lib/pulsar/components/popover.ex:88–125`.
These token pairs are the
browser-verified Card matrix — see [`card.md`](card.md). The axe gate scans the
`/components/popover` fixture triggers in light and dark.
The `ghost` variant is fully transparent — it inherits the ambient surface, so its content contrast is the caller's responsibility.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The panel is positioned by the hook with an 8px viewport margin and
both-axes shift-clamping, so it never forces horizontal scrolling at 320px; the
only width floor is `min-w-48` — `lib/pulsar/components/popover.ex:282–335`
(`position`), `:81` (`@panel_base_classes`).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** `elevated` delineates with `shadow-dropdown`; `outline`/`solid` with
a `border-{color}` (2px) — `lib/pulsar/components/popover.ex:88–125`. Same tokens as Card's audited matrix — [`card.md`](card.md).

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** The panel opens on **click/activation** of the trigger button (not
hover), is dismissable (Escape + outside click, native to `popover="auto"`), and
is persistent until dismissed — `lib/pulsar/components/popover.ex:218` (the panel's
`popover="auto"` attribute), `:262–275` (the hook's `toggle` handling).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The trigger is a native `<button>`; Enter/Space toggle the popover
via the browser's `popovertarget` invoker (stamped by the hook —
`lib/pulsar/components/popover.ex:238`); Escape closes natively. The keyboard
fixture exercises Enter-to-open and Escape-to-close — `test/integration/a11y/keyboard_test.exs`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Non-modal — Tab moves through panel content and back out to the
page; nothing holds focus. The keyboard fixture asserts Tab from inside the panel
leaves it — `test/integration/a11y/keyboard_test.exs`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** A closed panel is `display:none` (native `[popover]` rule), so its
content is out of the tab order until opened; no positive `tabindex` is used —
`lib/pulsar/components/popover.ex:216–227`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The panel sets `focus-visible:outline-none` on itself only; the
trigger and any focusable panel content keep their own focus rings (caller
responsibility) — `lib/pulsar/components/popover.ex:81` (`@panel_base_classes`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The panel renders in the browser top layer (native popover), so it
is never clipped by `overflow:hidden` ancestors; the hook flips it to the
opposite side when the requested side lacks room, keeping it off the trigger —
`lib/pulsar/components/popover.ex:282–335` (`position`).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The trigger activates on `click` (pointer-up); outside-click
dismissal is the browser's native light-dismiss — `lib/pulsar/components/popover.ex:218` (`popover="auto"`).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The trigger is caller-supplied (e.g. Pulsar `Button`, which meets
24×24); the primitive imposes no sub-24px target — caller responsibility.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the trigger causes no context change; the panel opens only
on activation — `lib/pulsar/components/popover.ex:216–227`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** The trigger is a native button exposing `aria-expanded` (synced on
toggle) and `aria-controls`; the panel imposes no role and accepts `role`/name via
attributes — `lib/pulsar/components/popover.ex:233–275` (hook `mounted`/`onToggle`), `:226` (panel
`{@rest}`). Unit tests assert the panel markup and passthrough —
`test/pulsar/components/popover_test.exs`.

## Not applicable

- **1.1.1 Non-text Content (A)** — the primitive renders no images/icons; content is caller-supplied.
- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — DOM order matches visual order; no reordering.
- **1.3.3 Sensory Characteristics (A)** — no instructions relying on shape/position.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — open/closed is exposed via `aria-expanded`, not color.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — no fixed `px` font sizes.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.12 Text Spacing (AA)** — no `!important` spacing; content is caller-supplied.
- **2.1.4 Character Key Shortcuts (A)** — only Escape (native), no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no moving/auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — content is caller-supplied.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — caller supplies any heading/label.
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
- **4.1.3 Status Messages (AA)** — emits no status messages.

## Browser a11y findings

None. The axe gate is clean across the `/components/popover` fixture cells in
light and dark themes.
