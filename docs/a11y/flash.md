# Flash · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/flash.ex`](../../lib/pulsar/components/flash.ex)
**Tests:** [`test/pulsar/components/flash_test.exs`](../../test/pulsar/components/flash_test.exs)
**Audited:** 2026-05-24 (code-only)

Toast-style notification with role/aria-live, dismissible close button,
auto-dismiss with pause-on-hover/focus, and a colocated JS hook
(`PulsarFlash`) managing the timer lifecycle.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Close-button icon `aria-hidden="true"` — `lib/pulsar/components/flash.ex:308`
- Close button has visible accessible name via `aria-label="Dismiss"` —
  `lib/pulsar/components/flash.ex:304`
- `start_icon` slot is caller-supplied; the wrapper div is purely
  presentational sizing — `lib/pulsar/components/flash.ex:292–294`

**Notes:** Decorative X SVG is hidden from AT and the button itself
carries the accessible name. Callers supplying icons in `start_icon`
are responsible for marking decorative ones `aria-hidden`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Container exposes `role={@role}` (`status` or `alert`) —
  `lib/pulsar/components/flash.ex:281`
- `aria-controls={@id}` ties the close button to the dismissible region —
  `lib/pulsar/components/flash.ex:305`
- Tests assert `role="status"` and `role="alert"` —
  `test/pulsar/components/flash_test.exs:25, 199, 212, 221`

**Notes:** Semantic role is programmatically determinable; the
button↔region relationship is explicit via `aria-controls`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Inner block follows start_icon in DOM order; close button
trails the content — `lib/pulsar/components/flash.ex:291–311`. No
`flex-direction: row-reverse` or absolute positioning of children.

**Notes:** DOM order matches visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Status communicated via role/aria-live + caller-supplied
`start_icon` + visible text content — `lib/pulsar/components/flash.ex:281–298`.
Flash group docs show icon pairing (`hero-x-circle` for error,
`hero-check-circle` for success) — `lib/pulsar/components/flash_group.ex:223–229`.

**Notes:** Not shape/color/position-only; text and icon convey type.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Caller supplies textual message in `inner_block` (required
slot) and may supply a `start_icon` — `lib/pulsar/components/flash.ex:217–225`.
ARIA role/live region also signals criticality non-visually —
`lib/pulsar/components/flash.ex:281–283`.

**Notes:** Color variants convey criticality redundantly with role
(`alert` vs `status`) and conventional icons; not color-only.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Colors come from semantic tokens via `@color_config`
(text/bg/border pairs across 3 variants × 7 colors × 2 themes) —
`lib/pulsar/components/flash.ex:107–143`. Token approach is sound but
ratios for each variant/color/theme combination require DevTools
measurement.

**Notes:** Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Tailwind text utilities (`text-sm`, `text-base`) use `rem`;
spacing (`p-2`, `p-3`, `p-4`, `gap-2`, `gap-3`) is rem-based —
`lib/pulsar/components/flash.ex:78–93`.

**Notes:** No fixed `px` font sizes; container is content-driven height,
not fixed.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Flash itself uses `flex items-start justify-between` with
no `min-width` — `lib/pulsar/components/flash.ex:97`. Width is governed
by the parent container (FlashGroup sets `max-w-sm w-full` —
`lib/pulsar/components/flash_group.ex:234–262`).

**Notes:** Inner content uses `min-w-0` to permit wrap —
`lib/pulsar/components/flash.ex:291, 295`. Reflows at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Focus ring on the container uses `focus-within:ring-2
ring-current ring-offset-2` — `lib/pulsar/components/flash.ex:100–101`.
Close button uses `focus:ring-2 focus:ring-current focus:ring-offset-2` —
`lib/pulsar/components/flash.ex:575`. Outline variant uses `border` (1px)
in the active color — `lib/pulsar/components/flash.ex:117–132`.

**Notes:** Semantic-token approach is sound; ratios need DevTools.
Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights on the container; padding is rem-based;
no `!important` on text spacing — `lib/pulsar/components/flash.ex:78–93,
96–104`.

**Notes:** Inherits line-height from page; container grows with content.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** Hover/focus on the flash pauses the auto-dismiss timer
(does not add or remove content) — `lib/pulsar/components/flash.ex:390–401,
412–419`. No tooltips or popovers.

**Notes:** Hover/focus behavior keeps content persistent, satisfying the
spirit of 1.4.13 (content remains visible until dismissed).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- Close button is a native `<button type="button">` —
  `lib/pulsar/components/flash.ex:300–302`
- `phx-click` triggers `JS.dispatch("pulsar:flash-dismiss", ...)` —
  `lib/pulsar/components/flash.ex:306`
- Hook listens for that event and runs `dismiss()` —
  `lib/pulsar/components/flash.ex:400, 430–436`

**Notes:** Native button supplies Space/Enter activation automatically.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No focus trap; only event listeners are `mouseenter`,
`mouseleave`, `focusin`, `focusout`, and the custom dismiss event —
`lib/pulsar/components/flash.ex:396–400`. No `keydown` handlers that
intercept Tab.

### 2.2.1 Timing Adjustable (A) — ✓ PASS

**Evidence:**
- `auto_dismiss` boolean attr; callers can disable —
  `lib/pulsar/components/flash.ex:170–173`
- `dismiss_after` integer attr; callers can extend (clamped 100ms–60s) —
  `lib/pulsar/components/flash.ex:175–178, 326–329`
- Manual dismiss always available via close button —
  `lib/pulsar/components/flash.ex:300–311`
- Hover/focus pauses timer; mouseleave/focusout resumes —
  `lib/pulsar/components/flash.ex:390–401, 412–427`
- Test asserts `auto_dismiss={false}` disables the timer —
  `test/pulsar/components/flash_test.exs:154–163`

**Notes:** Auto-dismiss is adjustable (turnable off and configurable
duration) and pausable via hover/focus, meeting 2.2.1 user-control
requirements.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Pause-on-hover via `mouseenter`/`mouseleave` and
pause-on-focus via `focusin`/`focusout` handlers —
`lib/pulsar/components/flash.ex:390–401, 412–427`. Dismiss button hides
the flash entirely on demand — `lib/pulsar/components/flash.ex:300–311,
430–436`.

**Notes:** The auto-updating content (the flash being removed) is both
pausable (hover/focus) and hideable (dismiss button).

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are CSS transitions on opacity/transform
during exit — `lib/pulsar/components/flash.ex:447–451` — and the
container's `transition-all duration-200` — `lib/pulsar/components/flash.ex:99`.
No flashing/blinking.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Only focusable child is the native close button rendered
after the content — `lib/pulsar/components/flash.ex:300–311`. No
positive `tabindex` values used.

### 2.4.7 Focus Visible (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:**
- Container uses `focus-within:ring-2 focus-within:ring-current
  focus-within:ring-offset-2` — `lib/pulsar/components/flash.ex:100–101`
- Close button uses `focus:outline-none focus:ring-2 focus:ring-current
  focus:ring-offset-2` — `lib/pulsar/components/flash.ex:575`

**Notes:** Close button uses `focus:` not `focus-visible:`, which means
the ring also appears on mouse focus — visually fine but worth a runtime
contrast check, especially `ring-current` on each color variant.
Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Flash itself doesn't create sticky/overlapping content
that obscures other focused elements; FlashGroup positions
(`fixed top-4 right-4` etc.) could overlap content but the close button
inside the flash is never obscured by the flash itself —
`lib/pulsar/components/flash_group.ex:232–263`.

**Notes:** Page-level concern when flash overlays critical inputs;
component-level passes.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native `<button>` fires on `click` (mouseup) —
`lib/pulsar/components/flash.ex:300–311`. Custom dismiss event listener
uses `click`-driven `phx-click`, not `mousedown` —
`lib/pulsar/components/flash.ex:306`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Close button has no visible text label (icon-only); the
`aria-label="Dismiss"` is the accessible name — no conflict possible —
`lib/pulsar/components/flash.ex:304`.

**Notes:** Icon-only button pattern; no visible text to mismatch.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Close-button sizes:
- `sm`: `h-4 w-4 p-0.5` = 16×16 CSS px —
  `lib/pulsar/components/flash.ex:89`
- `md`: `h-5 w-5 p-0.5` = 20×20 CSS px —
  `lib/pulsar/components/flash.ex:85`
- `lg`: `h-6 w-6 p-1` = 24×24 CSS px (at floor) —
  `lib/pulsar/components/flash.ex:80`

**Notes:** `sm` and `md` close buttons fall below the AA 24×24 floor by
the literal box; however, WCAG 2.5.8 allows the "spacing" exception
when surrounding inactive area provides a 24px-diameter clearance.
Tracked under browser audit to confirm whether the surrounding
flash padding (`p-2`/`p-3`) supplies sufficient inactive spacing.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler on the flash container or close button
triggers a context change. `focusin`/`focusout` only pause/resume the
auto-dismiss timer — `lib/pulsar/components/flash.ex:392–399`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Container role: `role={@role}` (`status` or `alert`) —
  `lib/pulsar/components/flash.ex:281`
- Container live region: `aria-live={get_aria_live(@live, @role)}` —
  `lib/pulsar/components/flash.ex:282`
- Container atomicity: `aria-atomic="true"` —
  `lib/pulsar/components/flash.ex:283`
- Close button is a native `<button type="button">` with
  `aria-label="Dismiss"` and `aria-controls={@id}` —
  `lib/pulsar/components/flash.ex:300–306`
- Tests assert `role`, `aria-live`, `aria-label="Dismiss"`,
  `type="button"` — `test/pulsar/components/flash_test.exs:25–28,
  101–112, 178–223`

**Notes:** Comprehensive name/role/value on both the message region
and the dismiss control.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:**
- `role="status"` (default) with `aria-live="polite"` for general
  updates; `role="alert"` with `aria-live="assertive"` for urgent
  messages — `lib/pulsar/components/flash.ex:192–202, 281–282, 581–583`
- `aria-atomic="true"` ensures the entire message is read on update —
  `lib/pulsar/components/flash.ex:283`
- Tests assert `aria-live="polite"` for status and `aria-live="assertive"`
  for alert — `test/pulsar/components/flash_test.exs:188, 201, 213, 222`

**Notes:** Status messages are programmatically determinable and
auto-announced; the role↔live-region mapping (`alert→assertive`,
`status→polite`) is sensible default behavior.

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
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts registered.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — not a heading or form label; close button label is covered under 4.1.2.
- **2.5.1 Pointer Gestures (A)** — no multipoint or path gestures.
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

- **2.2.3 No Timing (AAA)** — `auto_dismiss={false}` removes any timing
  constraint entirely; callers can opt into a no-timeout flash.
- **2.2.4 Interruptions (AAA)** — pause-on-hover and pause-on-focus
  (`lib/pulsar/components/flash.ex:390–401`) and the manual dismiss
  button let users defer or suppress the disappearing-content
  interruption.
- **2.5.5 Target Size (Enhanced) (AAA)** — not met by any size;
  largest close button is exactly 24×24 (lg). Below the AAA 44×44 target.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `color-contrast` | light: success solid; dark: primary/secondary solid | both | [PUL-32](https://linear.app/bigrefactor/issue/PUL-32/flash-fix-axe-color-contrast-violation) |
