# AlertDialog · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/alert_dialog.ex`](../../lib/pulsar/components/alert_dialog.ex)
**Tests:** [`test/pulsar/components/alert_dialog_test.exs`](../../test/pulsar/components/alert_dialog_test.exs)
**Audited:** 2026-06-04 (code-only + browser axe gate)

Constrained confirmation dialog for destructive actions, built on
[`modal/1`](modal.md): it renders a native `<dialog>` opened with `showModal()`,
so it inherits the modal focus trap, scroll lock, and focus restoration. It adds
a fixed Cancel/Confirm footer and the `alertdialog` role. The destructive
`on_confirm` command rides only on the Confirm button; Escape and Cancel dismiss
without running it, while backdrop clicks and the corner close button are removed
(`backdrop_close={false}`, `show_close_button={false}`) so the choice can't be
dismissed by accident — `lib/pulsar/components/alert_dialog.ex:162–177`. The
inherited dialog mechanics are audited in [`modal.md`](modal.md); this page covers
what AlertDialog adds or constrains.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The native `<dialog>` carries `role="alertdialog"`; `title` is wired
as `aria-labelledby` (through the modal) and the message body is wired as
`aria-describedby` via an explicit id on the message wrapper —
`lib/pulsar/components/alert_dialog.ex:158` (title), `:165–166` (role +
describedby), `:170` (message wrapper id). Unit tests assert the role and the
labelledby/describedby wiring — `test/pulsar/components/alert_dialog_test.exs`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** The dialog surface uses the same audited semantic-token matrix as
Modal (`variant`/`color` passthrough), and the title, message, and footer buttons
inherit `text-foreground` / the Pulsar `Button` foregrounds. The axe gate scans
the `/components/alert_dialog` fixture cells (every variant×color, every size)
in light and dark with zero violations.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Inherited from the modal panel: `w-[calc(100%-2rem)]` capped by a
`max-w-*` per size and `max-h-[85vh] overflow-y-auto`, so it never forces
horizontal scrolling at 320px — see [`modal.md`](modal.md).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The panel boundary (shadow for `elevated`, `border-{color}` for
`outline`/`solid`) and the Confirm/Cancel button surfaces are the same audited
token set as Modal and Button. These are rendered in the
`/components/alert_dialog` fixture cells and pass the axe gate.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** The dialog opens only on explicit activation (an `open/2` command on
a control), never on hover or focus, and is persistent until the user picks an
action or presses Escape — `lib/pulsar/components/alert_dialog.ex:187–211`
(open/close helpers).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The Cancel and Confirm controls are native Pulsar `Button`s, fully
keyboard-operable, and Escape dismissal is native to the modal `<dialog>` —
`lib/pulsar/components/alert_dialog.ex:172–177` (footer buttons), `:187–211`
(helpers).

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The dialog contains focus while open (the permitted modal pattern)
but is always releasable by keyboard: Escape closes it (it stays `dismissable`),
and the Cancel button returns a `close` command. Either path restores focus to the
opener (native `<dialog>` behavior) — `lib/pulsar/components/alert_dialog.ex:162`
(`dismissable={true}`), `:172–174` (Cancel).

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** `showModal()` moves focus into the dialog on open; the Cancel button
carries `autofocus`, so focus lands on the least-destructive action and an
accidental Enter can't trigger the destructive one. Focus restores to the opener
on close; no positive `tabindex` is used — `lib/pulsar/components/alert_dialog.ex:172`
(Cancel `autofocus`).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Both footer controls are Pulsar `Button`s, which carry
`focus-visible:ring-2 focus-visible:ring-ring` — `lib/pulsar/components/alert_dialog.ex:172–177`.
See [`button.md`](button.md).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The dialog renders in the browser top layer (native `showModal()`),
above all page content and never clipped by `overflow:hidden` ancestors — see
[`modal.md`](modal.md).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The Cancel and Confirm buttons activate on `click` (pointer-up), and
backdrop dismissal is disabled, so there is no down-event activation —
`lib/pulsar/components/alert_dialog.ex:163` (`backdrop_close={false}`), `:172–177`
(buttons).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The footer controls are Pulsar `Button`s, which meet the 24×24 floor
— `lib/pulsar/components/alert_dialog.ex:172–177`. See [`button.md`](button.md).

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing any control causes no context change; the dialog opens only
on explicit `open/2` activation — `lib/pulsar/components/alert_dialog.ex:187–199`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** The `<dialog>` exposes `role="alertdialog"` and is announced as modal
when opened with `showModal()`; `aria-labelledby` (title) and `aria-describedby`
(message) supply the accessible name and description —
`lib/pulsar/components/alert_dialog.ex:158` (title), `:165–170` (role, describedby,
message). Unit tests assert the role and aria wiring —
`test/pulsar/components/alert_dialog_test.exs`.

## Not applicable

- **1.1.1 Non-text Content (A)** — renders no icons or media; content is the caller's text.
- **1.2.1–1.2.5 Time-based Media (A/AA)** — no media.
- **1.3.2 Meaningful Sequence (A)** — DOM order (title, message, footer) matches visual order.
- **1.3.3 Sensory Characteristics (A)** — no instructions relying on shape/position.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — the destructive intent is conveyed by the button label, not color alone.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — no fixed `px` font sizes.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.12 Text Spacing (AA)** — no `!important` spacing; content is caller-supplied.
- **2.1.4 Character Key Shortcuts (A)** — only Escape (native), no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — the only motion is a sub-second scale/fade entrance, near-zeroed by the global reduced-motion rule.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links; the action buttons are labelled.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the caller supplies the title and button labels.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.3 Label in Name (A)** — the visible button text is the accessible name.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** / **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.2 On Input (A)** — not a form input.
- **3.2.3 Consistent Navigation (AA)** / **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1–3.3.4 / 3.3.7 / 3.3.8 (form/auth criteria)** — not a form input or authentication.
- **4.1.3 Status Messages (AA)** — emits no status messages.

## Browser a11y findings

None. The axe gate is clean across the `/components/alert_dialog` fixture cells in
light and dark themes.
