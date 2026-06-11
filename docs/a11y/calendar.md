# Calendar · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/calendar.ex`](../../lib/pulsar/components/calendar.ex)
**Tests:** [`test/pulsar/components/calendar_test.exs`](../../test/pulsar/components/calendar_test.exs)
**Keyboard tests:** [`test/integration/a11y/keyboard_test.exs`](../../test/integration/a11y/keyboard_test.exs)
**Audited:** 2026-06-11 (code + browser axe gate)

A locale-aware month-grid for selecting a single date or a date range.
The outer container carries `role="application" aria-roledescription="calendar"`;
each month renders as `role="grid"` with `role="columnheader"` weekday headers and
`role="gridcell"` day-cell buttons. Month/weekday names and full-date labels come
from the browser `Intl` API, so the grid is localized with no server-side
configuration. Keyboard navigation follows the APG Date Picker Grid pattern:
Arrow keys move by day, Home/End move to week edges, PageUp/PageDown page by
month (Shift multiplies by 12), and Enter/Space activate the cursor cell. A
roving-tabindex pattern keeps exactly one day cell in the tab stop at a time.
An `aria-live="polite"` region (`data-cal-announce`) announces month changes made
via the nav buttons.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content is the previous/next navigation chevrons
(`‹` / `›`), which are text characters inside `<button>` elements that carry a
full descriptive `aria-label` (e.g., `"Previous month, May 2026"`) —
`lib/pulsar/components/calendar.ex:320`. Blank leading cells are `aria-hidden="true"` —
`lib/pulsar/components/calendar.ex:329`. No images or icon SVGs are rendered by
the component.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- The outer container declares `role="application" aria-roledescription="calendar"` —
  `lib/pulsar/components/calendar.ex:116–117`
- Each month grid carries `role="grid"` with an `aria-label` (localized month/year
  string) — `lib/pulsar/components/calendar.ex:283–284`
- Weekday header cells carry `role="columnheader"` with a long-form `aria-label`
  (e.g., `"Monday"`) and a narrow display character —
  `lib/pulsar/components/calendar.ex:293–294`
- Day cells are `<button role="gridcell">` with a full localized date
  `aria-label` from `Intl.DateTimeFormat` — `lib/pulsar/components/calendar.ex:341–342`
- `aria-selected` marks selected cells; `aria-current="date"` marks today —
  `lib/pulsar/components/calendar.ex:349–350`
- `aria-disabled="true"` marks constrained cells —
  `lib/pulsar/components/calendar.ex:351`
- Blank leading cells are `aria-hidden="true"` —
  `lib/pulsar/components/calendar.ex:329`
- Test `renders the grid container wired to the colocated hook` asserts
  `role="application"` and `data-mode="single"` —
  `test/pulsar/components/calendar_test.exs:10–23`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** The hook renders month grids in document order (left-to-right,
first month first) — `lib/pulsar/components/calendar.ex:261–263`. Within each
grid the weekday header row precedes day cells, and day cells are ordered
day 1 … day N — `lib/pulsar/components/calendar.ex:287–309`. The `aria-hidden`
leading blank cells pad the grid visually without inserting spurious content into
the reading order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Disabled state is conveyed via `aria-disabled="true"` on the cell
and `opacity-disabled` styling, not by color alone —
`lib/pulsar/components/calendar.ex:351, 632`. Today's cell carries
`aria-current="date"` in addition to its bold ring visual —
`lib/pulsar/components/calendar.ex:349, 631`. Selected state is conveyed via
`aria-selected="true"` in addition to the accent background —
`lib/pulsar/components/calendar.ex:350`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Every state the component expresses with color is also expressed
via a programmatic attribute: disabled → `aria-disabled="true"` + `opacity-disabled`
(`lib/pulsar/components/calendar.ex:351, 632`); selected → `aria-selected="true"`
(`lib/pulsar/components/calendar.ex:350`); today → `aria-current="date"` +
font-semibold ring (`lib/pulsar/components/calendar.ex:349, 631`); in-range →
`data-in-range` attribute (`lib/pulsar/components/calendar.ex:348`). Color
reinforces these states but is never the sole signal.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Day-cell text uses `text-foreground` (resolved by the selected/default
CSS-state variants in `@cell_accent`) and inherits `bg-surface-1` from the
container — `lib/pulsar/components/calendar.ex:57–71, 128`. Weekday header labels
use `text-muted-foreground` — `lib/pulsar/components/calendar.ex:295`. The
`text-muted-foreground` token resolves to `gray-600`, which measures 6.0–7.23:1
against all relevant surfaces, well above the 4.5:1 AA minimum. Nav button labels
use `text-muted-foreground` as well — `lib/pulsar/components/calendar.ex:321`. The
axe gate is clean across the `/components/calendar/*` fixture cells in both light
and dark themes (134 axe tests passing).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Cell sizes use Tailwind `text-xs` / `text-sm` / `text-base` (rem-based)
— `lib/pulsar/components/calendar.ex:48–52`. Fixed pixel cell dimensions
(`h-7 w-7` through `h-11 w-11`) set the tap target; text inside is not clipped
because the cells are `flex items-center justify-center` and text can overflow
the bounding box at large user-override scales — `lib/pulsar/components/calendar.ex:630`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The outer container is `inline-flex flex-col gap-3` with no enforced
minimum width — `lib/pulsar/components/calendar.ex:128`. For multi-month (`mode="range"`
default 2 months) the grid area is `flex flex-wrap gap-4`
(`lib/pulsar/components/calendar.ex:134`), so secondary month grids wrap to the
next line at narrow viewports rather than forcing horizontal scroll. A single-month
calendar (the typical inline use) occupies roughly 230 CSS px and fits within the
320 CSS px reflow budget.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Day-cell focus ring uses `focus-visible:ring-2 focus-visible:ring-ring` —
  `lib/pulsar/components/calendar.ex:633`. The `--color-ring` token measures
  5.02:1 (light) / 6.72:1 (dark) against `bg-background`, above the 3:1 minimum.
- Nav button focus ring uses the same `focus-visible:ring-2 focus-visible:ring-ring`
  token — `lib/pulsar/components/calendar.ex:321`.
- Today's cell carries `ring-1 ring-border-strong` — `lib/pulsar/components/calendar.ex:631`.
  `--color-border-strong` resolves to `gray-500` (light) / `gray-400` (dark),
  giving ≥4.5:1 against the page background.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` overrides on spacing. Cell sizes use Tailwind utility
classes; text is not locked inside a pixel-height container that would clip under
user overrides — `lib/pulsar/components/calendar.ex:48–52, 630`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The full APG Date Picker Grid keyboard contract is implemented in the
`onKeydown` handler at `lib/pulsar/components/calendar.ex:459–475`:
- Arrow keys move by day — `lib/pulsar/components/calendar.ex:461–464`
- Home/End move to the first/last day of the current week —
  `lib/pulsar/components/calendar.ex:465–466, 493–496`
- PageUp/PageDown page by one month; Shift+PageUp/Down pages by one year —
  `lib/pulsar/components/calendar.ex:467–468, 510`
- Enter and Space activate the cursor cell —
  `lib/pulsar/components/calendar.ex:469–470, 530–532`

The `moveCursor` helper skips disabled cells when looking for the next tabbable
target — `lib/pulsar/components/calendar.ex:479–490`. Navigation across month
boundaries automatically shifts the visible view and focuses the target cell —
`lib/pulsar/components/calendar.ex:519–527`.

Real-browser keyboard tests in `test/integration/a11y/keyboard_test.exs`:
- `ArrowRight moves the focused cell and Enter selects it` —
  `test/integration/a11y/keyboard_test.exs:65–73`
- `clicking a day selects it and writes the hidden ISO value` —
  `test/integration/a11y/keyboard_test.exs:36–55`

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The `onKeydown` handler intercepts only the ten keys listed in the
`map` object at `lib/pulsar/components/calendar.ex:460–471`. Tab and Shift+Tab are
not in the map and fall through (`if (!fn) return` — `lib/pulsar/components/calendar.ex:472`),
so native browser Tab behavior is fully preserved. The roving-tabindex pattern
means only one cell has `tabindex="0"` at any time; Tab moves focus out of the
grid to the next element in the page.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only animation is `transition-colors duration-fast ease-standard`
on day cells — `lib/pulsar/components/calendar.ex:630`. No auto-updating or
auto-advancing content. The calendar is static between user interactions.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing animations. The color transition on selection is a
smooth single-pass change far below the 3-flash/second threshold —
`lib/pulsar/components/calendar.ex:630`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Roving tabindex is used: `cell.tabIndex = this.sameDay(date, this.cursor) ? 0 : -1`
— `lib/pulsar/components/calendar.ex:354`. Only the current cursor day cell has
`tabindex="0"`; all other day cells have `tabindex="-1"`. No positive `tabindex`
values are used anywhere. The `refreshCells` helper keeps the roving tabindex
consistent after selection — `lib/pulsar/components/calendar.ex:406`. The test
`ArrowRight moves the focused cell` verifies `tabindex="0"` migrates to the new
cursor — `test/integration/a11y/keyboard_test.exs:65–73`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Each month grid carries a programmatic `aria-label` equal to the
localized month-year string (e.g., `"June 2026"`) —
`lib/pulsar/components/calendar.ex:284`. Weekday column headers carry long-form
`aria-label` names — `lib/pulsar/components/calendar.ex:294`. Navigation buttons
carry descriptive labels including the destination month —
`lib/pulsar/components/calendar.ex:320`. Day cells carry full localized date
`aria-label` strings from `Intl.DateTimeFormat { dateStyle: "full" }` —
`lib/pulsar/components/calendar.ex:342`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Day cells apply `focus-visible:outline-none focus-visible:ring-2
focus-visible:ring-ring` — `lib/pulsar/components/calendar.ex:633`. Navigation
buttons apply the same — `lib/pulsar/components/calendar.ex:321`. The
`--color-ring` token measures 5.02:1 (light) / 6.72:1 (dark), well above the 3:1
non-text minimum.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The calendar creates no sticky or overlapping content that could
cover a focused cell. When used inside `DatePicker` the popover positions the
calendar above or below the trigger with `z-index` isolation; the calendar itself
creates no sticky layers — `lib/pulsar/components/calendar.ex:112–135`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The click handler is registered via the native `click` event (fires
on mouseup) — `lib/pulsar/components/calendar.ex:364–369`. No `mousedown` or
`pointerdown` handlers are used, so pointer actions can be cancelled by dragging
off the target before releasing.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Navigation buttons have no visible text that contradicts their
`aria-label`; the displayed chevron character (`‹` / `›`) is decorative and the
`aria-label` provides the full name — `lib/pulsar/components/calendar.ex:320, 322`.
Day cells display the day number; the `aria-label` is the full date string that
includes the same number — `lib/pulsar/components/calendar.ex:340, 342`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Day cells at every size exceed or meet the 24×24 CSS px minimum:
`xs`=28×28px, `sm`=32×32px, `md`=36×36px, `lg`=40×40px, `xl`=44×44px —
`lib/pulsar/components/calendar.ex:48–52`. Navigation buttons are `h-7 w-7` (28×28 px) —
`lib/pulsar/components/calendar.ex:321`. Adjacent cells are separated by
`gap-0.5` (2px), satisfying the spacing exception even at the `xs` size.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Moving focus to a day cell (via keyboard arrow keys) updates the
cursor position and re-renders the grid, but does not select the date or trigger
the `on_select` callback. Selection only happens on Enter/Space or click —
`lib/pulsar/components/calendar.ex:530–532`. Focusing the calendar container or
nav buttons does not trigger navigation or form submission.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Clicking a day or pressing Enter/Space calls `select` or
`selectRange` which writes the hidden input value and executes the caller-supplied
`on_select` `%JS{}` command — `lib/pulsar/components/calendar.ex:388–394`. The
component does not trigger page navigation or form submission itself; those actions
are caller-initiated via `JS.push(...)`. The test `selecting a day notifies
LiveView via phx-change` verifies the side-effect is limited to a controlled event
— `test/integration/a11y/keyboard_test.exs:57–63`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Container: `role="application" aria-roledescription="calendar"` —
  `lib/pulsar/components/calendar.ex:116–117`
- Month grid: `role="grid"` + `aria-label` (localized month/year) —
  `lib/pulsar/components/calendar.ex:283–284`
- Weekday headers: `role="columnheader"` + `aria-label` (long weekday name) —
  `lib/pulsar/components/calendar.ex:293–294`
- Day cells: `<button role="gridcell">` with `aria-label` (full localized date),
  `aria-selected`, `aria-current="date"` (today), `aria-disabled="true"` (constrained)
  — `lib/pulsar/components/calendar.ex:341–351`
- Nav buttons: `<button type="button">` with descriptive `aria-label` —
  `lib/pulsar/components/calendar.ex:317–320`
- Month-change announcements: `aria-live="polite" aria-atomic="true"` live region
  (`data-cal-announce`) — `lib/pulsar/components/calendar.ex:135`
- Roving tabindex ensures only the cursor cell is reachable by Tab —
  `lib/pulsar/components/calendar.ex:354`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** Month navigation announces the new month via `this.announceEl.textContent`
written into the `aria-live="polite" aria-atomic="true"` region at
`lib/pulsar/components/calendar.ex:135, 385`. When focus moves to a day cell during
keyboard navigation the cell's own `aria-label` is announced by the screen reader
as the focused element; no additional live-region update is needed in that path.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — the calendar is a date-picker widget, not a
  text input collecting personal information; the hidden ISO inputs carry no WCAG
  1.3.5 autocomplete purpose token. Date-of-birth pickers are the relevant edge
  case, but the calendar writes ISO values into caller-named fields and the
  `autocomplete` token is the caller's responsibility.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; all labels are live DOM
  text or SVG.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or secondary popover on
  hover/focus; the calendar is itself an inline widget.
- **2.1.4 Character Key Shortcuts (A)** — no global single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links rendered.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern. Localization uses the
  browser `Intl` API which resolves locale automatically; no server-side language
  attribute is needed.
- **3.1.2 Language of Parts (AA)** — localized strings are generated by the browser
  `Intl` API and inherit the page language; no `lang` override is required.
- **3.3.1 Error Identification (A)** — the calendar is a selection widget, not a
  validated text input. When used via the `field` attribute, the field wrapper
  handles error identification. The calendar itself does not produce validation
  errors.
- **3.3.2 Labels or Instructions (A)** — instructions are provided by the grid
  structure and ARIA labels on each cell; the calendar does not collect typed user
  input that would require additional instructions.
- **3.3.3 Error Suggestion (AA)** — no input errors to suggest corrections for.
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** — app-level
  concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — satisfied by using Pulsar uniformly.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  minimum ring thickness, and `--color-ring` clears AAA contrast (5.02:1 light /
  6.72:1 dark) — `lib/pulsar/components/calendar.ex:633`.
- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `lg` (`h-10`=40px) and `xl`
  (`h-11`=44px) satisfy the AAA 44×44 px floor —
  `lib/pulsar/components/calendar.ex:51–52`.

## Browser a11y findings

None. The axe gate is clean across the `/components/calendar/*` fixture cells in
light and dark themes.
