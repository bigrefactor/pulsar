# Modal · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/modal.ex`](../../lib/pulsar/components/modal.ex)
**Tests:** [`test/pulsar/components/modal_test.exs`](../../test/pulsar/components/modal_test.exs)
**Audited:** 2026-06-03 (code-only + browser axe gate)

Focus-trapped, dismissible overlay dialog built on the native HTML `<dialog>`
element. The `.PulsarModal` colocated hook opens it with `showModal()` — the
browser provides `role="dialog"`, the modal focus trap, Escape handling, and
focus restoration to the opener — and adds scroll lock, backdrop-click
dismissal, and the `dismissable={false}` lock. `title` is wired as the dialog's
`aria-labelledby` and a `:description` slot as its `aria-describedby`.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The native `<dialog>` exposes a `dialog` role; `title` renders a
`<h2>` referenced by `aria-labelledby`, and the `:description` slot renders a
`<p>` referenced by `aria-describedby` — `lib/pulsar/components/modal.ex:252–253`
(wiring), `:262–265` (heading/description). Unit tests assert the id wiring —
`test/pulsar/components/modal_test.exs`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Surfaces use the same semantic-token matrix as Card/Popover:
`elevated` pairs `bg-surface-1` with the inherited foreground; `outline`/`solid`
add a `border-{color}` / soft `bg-{color}/10` tint — `lib/pulsar/components/modal.ex:92–127`.
Title and body inherit `text-foreground`; the description uses `text-foreground`
(not `text-muted-foreground`) so it clears 4.5:1 on every variant×color surface,
including the colored solid tints. The axe gate scans the `/components/modal`
fixture cells in light and dark with zero violations.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The dialog is `w-[calc(100%-2rem)]` (a 1rem gutter each side) capped
by a `max-w-*` per size, and `max-h-[85vh] overflow-y-auto`, so it never forces
horizontal scrolling at 320px and long content scrolls inside the panel —
`lib/pulsar/components/modal.ex:83–85` (`@panel_base_classes`), `:72–77` (`@size_config`).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** `elevated` delineates the panel from the page with `shadow-modal`;
`outline`/`solid` add a 2px `border-{color}` / `border-border-strong` —
`lib/pulsar/components/modal.ex:92–127`. These panel boundaries are rendered in
the `/components/modal` fixture cells and pass the axe gate (same audited token
matrix as [`card.md`](card.md)). The dimmed backdrop is `bg-foreground/50`; this
is verified by code inspection, not the axe gate — the fixtures render the
`<dialog>` with the `open` attribute (the established pattern for visible-in-flow
cells), which produces no `::backdrop` pseudo-element and does not enter the top
layer, so axe never evaluates the backdrop.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** The dialog opens on explicit activation (an `open/2` command on a
button), never on hover or focus; it is dismissable (Escape + backdrop click,
unless `dismissable={false}`) and persistent until dismissed —
`lib/pulsar/components/modal.ex:324–356` (hook open/cancel/click handling).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The dialog is opened/closed by `open/2`/`close/2` composed onto
keyboard-operable controls; the built-in close button is a native `<button>`;
Escape dismissal is native to the modal `<dialog>` —
`lib/pulsar/components/modal.ex:268–276` (close button), `:404–428` (helpers). The
keyboard fixture exercises open, Escape-to-close, and the non-dismissable lock —
`test/integration/a11y/keyboard_test.exs`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** A modal dialog intentionally contains focus while open (the
permitted modal pattern); focus is always releasable by keyboard — Escape closes
a dismissable dialog, and a `dismissable={false}` dialog is closed by activating
one of its footer action buttons, which return a `close/2` command. Either path
returns focus to the opener (native `<dialog>` behavior) —
`lib/pulsar/components/modal.ex:342–344` (Escape lock only when non-dismissable).
The keyboard fixture asserts Escape closes the dismissable dialog and restores
focus, and that the locked dialog stays open on Escape —
`test/integration/a11y/keyboard_test.exs`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** `showModal()` moves focus into the dialog on open (to `[autofocus]`
or the first focusable control) and restores it to the opener on close; no
positive `tabindex` is used — `lib/pulsar/components/modal.ex:324–330` (open),
`:332–334` (close). The keyboard fixture asserts focus lands inside on open and
returns to the opener on close — `test/integration/a11y/keyboard_test.exs`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The built-in close button carries `focus-visible:ring-2
focus-visible:ring-ring`; the dialog itself uses `focus:outline-none` only, and
caller-supplied controls keep their own focus rings —
`lib/pulsar/components/modal.ex:268–276` (close button), `:83` (`@panel_base_classes`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The dialog renders in the browser top layer (native `showModal()`),
above all page content and never clipped by `overflow:hidden` ancestors —
`lib/pulsar/components/modal.ex:324–326`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The close button activates on `click` (pointer-up); backdrop
dismissal fires on a `click` whose target is the dialog box outside the panel —
`lib/pulsar/components/modal.ex:346–356` (`handleClick`).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The built-in close button is a `sm` icon with `p-1` padding,
meeting the 24×24 floor; caller-supplied footer controls (e.g. Pulsar `Button`,
which meets 24×24) are the caller's responsibility —
`lib/pulsar/components/modal.ex:268–276`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing any control causes no context change; the dialog opens
only on explicit `open/2` activation — `lib/pulsar/components/modal.ex:404–410`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** The native `<dialog>` exposes the `dialog` role and is announced as
modal when opened with `showModal()`; `aria-labelledby`/`aria-describedby` supply
the accessible name and description, and callers can pass `aria-label` via
`{@rest}` when rendering no visible title — `lib/pulsar/components/modal.ex:244–253`.
Unit tests assert the role markup and aria wiring —
`test/pulsar/components/modal_test.exs`.

## Not applicable

- **1.1.1 Non-text Content (A)** — the only icon (the close glyph) is decorative; the button is named by `aria-label`. Body content is caller-supplied.
- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — DOM order (heading, description, body, footer) matches visual order.
- **1.3.3 Sensory Characteristics (A)** — no instructions relying on shape/position.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — open/closed and dismissability are not conveyed by color.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — no fixed `px` font sizes.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.12 Text Spacing (AA)** — no `!important` spacing; content is caller-supplied.
- **2.1.4 Character Key Shortcuts (A)** — only Escape (native), no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — the only motion is a sub-second scale/fade entrance on open (`animate-scale-in`), near-zeroed by the global reduced-motion rule; no continuous or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing; the entrance is a single scale/opacity transition.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — content is caller-supplied.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the caller supplies the title/description text.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.3 Label in Name (A)** — the close button's `aria-label` is its only name (no visible text label to contradict).
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

None. The axe gate is clean across the `/components/modal` fixture cells in light
and dark themes.
