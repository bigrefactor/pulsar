# Drawer · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/drawer.ex`](../../lib/pulsar/components/drawer.ex)
**Tests:** [`test/pulsar/components/drawer_test.exs`](../../test/pulsar/components/drawer_test.exs)
**Audited:** 2026-06-09 (code-only + browser axe gate)

Edge-anchored, focus-trapped overlay panel built on [`modal/1`](modal.md): it
renders a native `<dialog>` opened with `showModal()`, so it inherits the modal
focus trap, scroll lock, Escape handling, focus restoration, backdrop, the
`title`→`aria-labelledby` / `:description`→`aria-describedby` wiring, the corner
close button, and the audited semantic-token contrast matrix — all forwarded
unchanged through the modal wrapper — `lib/pulsar/components/drawer.ex:197–216`.
What Drawer adds is the edge geometry (anchor + fill per side) and a directional
slide-in animation — `lib/pulsar/components/drawer.ex:72–94` (side/height config),
`:80–85` (slide-in utilities). The inherited dialog mechanics are audited in
[`modal.md`](modal.md); this page covers what Drawer adds or constrains.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Inherited from the modal wrapper — `title` renders the `<h2>`
referenced by `aria-labelledby` and the `:description` slot renders the `<p>`
referenced by `aria-describedby`; Drawer forwards both straight through —
`lib/pulsar/components/drawer.ex:199` (title), `:213` (`:description`), `:197–216`
(modal wrapper). See [`modal.md`](modal.md) §1.3.1.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** The panel surface uses the same audited semantic-token matrix as
Modal (`variant`/`color` passthrough); the title and body inherit
`text-foreground` and the description uses `text-muted-foreground`, which measures
6.0–7.23:1 across every variant×color surface — `lib/pulsar/components/drawer.ex:200–202`
(variant/color/size forwarded). The token map is unchanged from Modal — see
[`modal.md`](modal.md) §1.4.3 for the measured table. The axe gate scans the
`/components/drawer` fixture cells in light and dark with zero violations.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Left/right drawers cap their width via the inherited modal
`max-w-*` per size and fill the available height (`w-full`), so they never force
horizontal scrolling at 320px — `lib/pulsar/components/drawer.ex:73–74`
(`w-full` + `h-dvh`). Top/bottom drawers fill the viewport width (`w-full
max-w-none`) and cap their height on a `vh` scale (`max-h-[30vh]`…`max-h-[85vh]`)
— `:75–76`, `:89–94` (`@height_config`). Long content scrolls inside the panel via
the inherited `overflow-y-auto` — see [`modal.md`](modal.md) §1.4.10.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The panel boundary (shadow for `elevated`, `border-{color}` /
`border-border-strong` for `outline`/`solid`) is the same audited token set as
Modal, forwarded unchanged — `lib/pulsar/components/drawer.ex:200–201`. These
boundaries are rendered in the `/components/drawer` fixture cells and pass the axe
gate. See [`modal.md`](modal.md) §1.4.11.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** Inherited — the drawer opens on explicit `open/2` activation
(a command on a control), never on hover or focus, and is persistent until
dismissed — `lib/pulsar/components/drawer.ex:229` (`open/1`), `:235` (`open/2`).
See [`modal.md`](modal.md) §1.4.13.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Inherited — opened/closed by `open/2`/`close/2` composed onto
keyboard-operable controls; the built-in close button is a native `<button>` and
Escape dismissal is native to the modal `<dialog>` —
`lib/pulsar/components/drawer.ex:229–247` (helpers delegate to Modal). See
[`modal.md`](modal.md) §2.1.1.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Inherited — the modal `<dialog>` contains focus while open (the
permitted modal pattern) but is always releasable by keyboard; Escape closes a
`dismissable` drawer and either path returns focus to the opener —
`lib/pulsar/components/drawer.ex:203` (`dismissable` forwarded). See
[`modal.md`](modal.md) §2.1.2.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Inherited — `showModal()` moves focus into the dialog on open and
restores it to the opener on close; no positive `tabindex` is used —
`lib/pulsar/components/drawer.ex:197–216` (modal wrapper). See
[`modal.md`](modal.md) §2.4.3.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Inherited — the built-in close button carries
`focus-visible:ring-2 focus-visible:ring-ring` and the dialog itself uses
`focus:outline-none` only — `lib/pulsar/components/drawer.ex:205` (close button
forwarded). See [`modal.md`](modal.md) §2.4.7.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Inherited — the dialog renders in the browser top layer (native
`showModal()`), above all page content and never clipped by `overflow:hidden`
ancestors. See [`modal.md`](modal.md) §2.4.11.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Inherited — the close button activates on `click` (pointer-up) and
backdrop dismissal fires on a `click`; no down-event activation —
`lib/pulsar/components/drawer.ex:204` (`backdrop_close` forwarded). See
[`modal.md`](modal.md) §2.5.2.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Inherited — the built-in close button is a `sm` icon with `p-1`
padding, meeting the 24×24 floor; caller-supplied footer controls are the caller's
responsibility — `lib/pulsar/components/drawer.ex:205` (close button forwarded),
`:215` (`:footer`). See [`modal.md`](modal.md) §2.5.8.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Inherited — focusing any control causes no context change; the
drawer opens only on explicit `open/2` activation —
`lib/pulsar/components/drawer.ex:229–235`. See [`modal.md`](modal.md) §3.2.1.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Inherited — the native `<dialog>` exposes the `dialog` role and is
announced as modal when opened with `showModal()`; `aria-labelledby` /
`aria-describedby` supply the accessible name and description, and callers can
pass `aria-label` via `{@rest}` when rendering no visible title —
`lib/pulsar/components/drawer.ex:211` (`{@rest}` passthrough), `:157–160` (`:rest`
with `aria-label`). See [`modal.md`](modal.md) §4.1.2.

## Not applicable

- **1.1.1 Non-text Content (A)** — the only icon (the inherited close glyph) is decorative; the button is named by `aria-label`. Body content is caller-supplied.
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
- **2.2.2 Pause, Stop, Hide (A)** — the only motion is a sub-second directional slide-in on open (`@side_animation`, transform-only), near-zeroed by the global reduced-motion rule; there is no close animation and no continuous or auto-updating content — `lib/pulsar/components/drawer.ex:80–85`.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing; the entrance is a single transform/opacity transition.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — content is caller-supplied.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the caller supplies the title/description text.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures (the slide-in is decorative, not gesture-driven).
- **2.5.3 Label in Name (A)** — the close button's `aria-label` is its only name (no visible text label to contradict).
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag; the drawer is opened/closed by control activation, not by dragging the edge.
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

None. The axe gate is clean across the `/components/drawer` fixture cells in light
and dark themes.
