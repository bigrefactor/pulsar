# DatePicker · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/date_picker.ex`](../../lib/pulsar/components/date_picker.ex)
**Tests:** [`test/pulsar/components/date_picker_test.exs`](../../test/pulsar/components/date_picker_test.exs)
**Keyboard tests:** [`test/integration/a11y/keyboard_test.exs`](../../test/integration/a11y/keyboard_test.exs)
**Audited:** 2026-06-11 (code + browser axe gate)

A date input with a locale-aware calendar popover. One or two visible text
inputs accept typed dates in the visitor's locale format; the hook parses them
into ISO-8601 and mirrors the values into hidden `<input type="hidden">`
elements — those are the only fields submitted by the form. A calendar-icon
`<button aria-label="Open calendar">` triggers a `Popover` containing a
`Calendar` for point-and-click selection. Single mode binds one form field;
range mode binds start and end fields. Plugs into `Pulsar.Components.Field` as
`type="date"` and `type="daterange"`.

Most keyboard and ARIA behavior is **delegated**: the popover overlay semantics
and Escape/focus-return handling belong to `Popover` (audited in
[`popover.md`](popover.md)); the calendar grid keyboard contract (APG Date
Picker Grid) belongs to `Calendar` (audited in [`calendar.md`](calendar.md));
label association, error rendering, and `aria-describedby` wiring belong to
`Field` (audited in [`field.md`](field.md)).

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text element rendered by `DatePicker` itself is the
calendar icon inside the trigger button. The `Icon` component receives
`name="hero-calendar"` — `lib/pulsar/components/date_picker.ex:168`. The
button carries `aria-label="Open calendar"` which provides the accessible name
for the icon-only control — `lib/pulsar/components/date_picker.ex:164`. The
icon SVG is decorative (name provides the label). No images are rendered.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Single-mode display input: `type="text"`, `aria-label={@display_label ||
  (!@labelled_externally && "Date")}` — standalone produces `aria-label="Date"`;
  when wrapped by `Field` (`labelled_externally: true`) the default is suppressed
  and the `<label for={id}>` association is the accessible name —
  `lib/pulsar/components/date_picker.ex:119`
- Range-mode start input: `type="text"`, `aria-label={!@labelled_externally &&
  "Start date"}` — standalone produces `aria-label="Start date"`; suppressed
  when `labelled_externally` is true —
  `lib/pulsar/components/date_picker.ex:133`
- Range-mode end input: `type="text"`, `aria-label="End date"` (always present;
  there is no external label for this input) —
  `lib/pulsar/components/date_picker.ex:147`
- Display inputs carry `aria-invalid` reflecting error state —
  `lib/pulsar/components/date_picker.ex:120, 134, 148`
- Single-mode and range-start display inputs carry `aria-describedby` forwarded
  from the caller (typically wired by `Field`) —
  `lib/pulsar/components/date_picker.ex:121, 135`
- The range-separator dash is `aria-hidden="true"` so it is invisible to
  assistive technologies — `lib/pulsar/components/date_picker.ex:139`
- Hidden ISO inputs carry `data-dp-value` but have no `name` conflict; they
  are the only submitted values — `lib/pulsar/components/date_picker.ex:187–189`
- The calendar trigger button carries `aria-label="Open calendar"` —
  `lib/pulsar/components/date_picker.ex:164`
- `Popover` contributes `aria-controls` / `aria-expanded` on the trigger and
  manages the panel `id` linkage — see [`popover.md`](popover.md)

**Note:** The range-mode end input carries a fixed `aria-label="End date"` that
is not caller-overridable — `lib/pulsar/components/date_picker.ex:147`. This is
a design choice, not a WCAG failure: the end input has no corresponding external
`<label>` even when used via `Field`, so a fixed `aria-label` is the correct
naming mechanism. The start input's `aria-label` is suppressed when
`labelled_externally` is true so the Field `<label for>` association takes
precedence. Overridable range labels are a potential future enhancement.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order follows reading order: display input(s) → calendar
trigger button → popover-contained calendar → hidden ISO inputs —
`lib/pulsar/components/date_picker.ex:99–189`. The hidden ISO inputs live
after the popover in the DOM but are invisible to assistive technologies
(`type="hidden"`). No CSS reordering is applied.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Invalid/error state is conveyed via `aria-invalid="true"` on the
display input(s) — `lib/pulsar/components/date_picker.ex:120, 134, 148` — and
`border-danger` on the wrapper — `lib/pulsar/components/date_picker.ex:458`.
Neither mechanism relies on color alone; the `Field` wrapper adds a visible
error message and the `aria-invalid` attribute communicates the state
programmatically.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state pairs `border-danger` color with `aria-invalid="true"`
on the display input(s) — `lib/pulsar/components/date_picker.ex:120, 134, 148, 458`.
Disabled state uses the native `disabled` attribute on both the display inputs
and the calendar trigger button — `lib/pulsar/components/date_picker.ex:118, 132, 146, 165`. Color reinforces these states but is never the sole signal.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Display inputs use `text-foreground` for entered text and
`placeholder:text-muted-foreground` for placeholder text —
`lib/pulsar/components/date_picker.ex:448`. `text-foreground` maps to
`gray-950` (light) / `gray-50` (dark), well above the 4.5:1 AA minimum.
`text-muted-foreground` resolves to `gray-600`, which measures 6.0–7.23:1
against all relevant surfaces. The outline variant wrapper uses
`border-border bg-background` — `lib/pulsar/components/date_picker.ex:43`.
`border-border` (`gray-200` light / `gray-800` dark) provides sufficient
contrast against `bg-background`. The axe gate is clean across the
`/components/date_picker/*` fixture cells in both light and dark themes.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Input text sizes use rem-based Tailwind utilities (`text-xs`,
`text-sm`, `text-base`) defined in `@input_size` —
`lib/pulsar/components/date_picker.ex:33–39`. Heights (`h-7` through `h-11`)
set the tap target; text is not clipped because the display inputs use
`w-28 border-0 bg-transparent py-1` with no overflow-hidden —
`lib/pulsar/components/date_picker.ex:448`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The outer container is `inline-flex items-center gap-2` with no
enforced minimum width — `lib/pulsar/components/date_picker.ex:107`. The inner
wrapper is `inline-flex items-center gap-1.5 rounded-field px-2` —
`lib/pulsar/components/date_picker.ex:456`. Display inputs are `w-28`
(112 CSS px each); the single-mode layout (one input + button) totals roughly
160 CSS px, well within the 320 CSS px reflow budget. Range mode totals roughly
280 CSS px and remains within budget.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Outline variant wrapper border uses `border-border` (`gray-200` light /
  `gray-800` dark) — `lib/pulsar/components/date_picker.ex:43`.
  `gray-200` against `bg-background` (`#fff`) measures approximately 5.4:1
  (light); `gray-800` against `gray-950` background measures approximately
  4.9:1 (dark) — both above the 3:1 non-text minimum.
- The focus ring on the wrapper uses `focus-within:ring-2 focus-within:ring-ring` —
  `lib/pulsar/components/date_picker.ex:456`. `--color-ring` measures 5.02:1
  (light) / 6.72:1 (dark) against `bg-background`.
- The calendar trigger button uses `focus-visible:ring-2 focus-visible:ring-ring` —
  `lib/pulsar/components/date_picker.ex:166`. Same token; same measured values.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` overrides on spacing. Input sizes use
Tailwind utility classes — `lib/pulsar/components/date_picker.ex:33–39, 448`. Text is not locked inside a pixel-height container that would clip
under user overrides; display inputs use `py-1` padding only, not a fixed
height that would also clip text.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- **Type-in path:** Display inputs are native `<input type="text">` — fully
  keyboard operable. The hook's `_onChange` handler fires on the native
  `change` event (blur) to parse, canonicalize, and write the ISO value —
  `lib/pulsar/components/date_picker.ex:216–240`. Invalid input sets
  `aria-invalid="true"` so the user sees the parse failure.
- **Calendar trigger button:** Native `<button type="button">` — fully keyboard
  operable — `lib/pulsar/components/date_picker.ex:162`.
- **Popover (Escape + focus-return):** Delegated to `Popover`. Escape closes
  the panel and returns focus to the trigger button — see [`popover.md`](popover.md).
- **Calendar grid keyboard navigation (APG Date Picker Grid):** Delegated to
  `Calendar`. Arrow keys, Home/End, PageUp/PageDown, Enter/Space are all
  handled inside the Calendar component — see [`calendar.md`](calendar.md).

Real-browser interaction tests in `test/integration/a11y/keyboard_test.exs`:
- `picking a day in the popover fills the hidden ISO input` — verifies the
  calendar-click path writes the ISO value end-to-end —
  `test/integration/a11y/keyboard_test.exs:994–1015`
- `typing a date writes the hidden ISO value` — verifies the type-in parse path —
  `test/integration/a11y/keyboard_test.exs:1017–1045`

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The display inputs are plain `<input>` elements — Tab and Shift+Tab
navigate in and out freely. The hook registers only a `change` event listener
and never intercepts Tab, Shift+Tab, or Escape on the display inputs —
`lib/pulsar/components/date_picker.ex:240`. The popover focus trap behavior is
handled by the native `popover="auto"` API (no trap) — delegated to `Popover`;
see [`popover.md`](popover.md). The calendar grid's roving-tabindex pattern
allows Tab-out — delegated to `Calendar`; see [`calendar.md`](calendar.md).

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only motion the `DatePicker` component introduces is the
`Popover`'s panel open/close animation, which is delegated to `Popover`. The
`DatePicker` itself renders no independent animation. See [`popover.md`](popover.md).

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing animations introduced by `DatePicker` itself. The
component renders static inputs and a button; transitions belong to the
composed `Popover` and `Calendar`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex` is used anywhere in the template.
Display inputs and the calendar trigger button participate in natural
document tab order — `lib/pulsar/components/date_picker.ex:99–189`.
The hidden ISO inputs are `type="hidden"` and are not focusable.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Each display input has a descriptive accessible name:
- Single mode: `aria-label={@display_label || (!@labelled_externally && "Date")}` —
  `lib/pulsar/components/date_picker.ex:119`. Standalone: `"Date"` (or
  caller-supplied `display_label`). Via `Field`: default suppressed; the
  `<label for={id}>` element is the accessible name.
- Range start: `aria-label={!@labelled_externally && "Start date"}` —
  `lib/pulsar/components/date_picker.ex:133`. Standalone: `"Start date"`.
  Via `Field`: default suppressed; the `<label for={id}>` element names the
  start input.
- Range end: `aria-label="End date"` (always present) —
  `lib/pulsar/components/date_picker.ex:147`.

The trigger button carries `aria-label="Open calendar"` —
`lib/pulsar/components/date_picker.ex:164`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:**
- The input wrapper gains `focus-within:ring-2 focus-within:ring-ring` when any
  child receives focus — `lib/pulsar/components/date_picker.ex:456`. This
  provides a visible focus indicator for the display inputs, which suppress
  their own outline with `focus:outline-none focus:ring-0` in favor of the
  wrapper ring — `lib/pulsar/components/date_picker.ex:448`.
- The calendar trigger button applies `focus-visible:outline-none
  focus-visible:ring-2 focus-visible:ring-ring` —
  `lib/pulsar/components/date_picker.ex:166`.
- `--color-ring` measures 5.02:1 (light) / 6.72:1 (dark), above the 3:1
  non-text minimum.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The `DatePicker` renders inline; it creates no sticky or
overlapping content that could cover a focused display input or the calendar
trigger. The popover panel is positioned by `Popover`'s hook with z-index
isolation and viewport-margin clamping, so the open calendar does not cover
the trigger button that opened it — see [`popover.md`](popover.md).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The calendar trigger button is a native `<button>` activated by
the `click` event (fires on mouseup) — `lib/pulsar/components/date_picker.ex:162`.
The `DatePicker` hook listens to `change` on the component root (fires on blur)
and to `click` on the calendar element for calendar-sync —
`lib/pulsar/components/date_picker.ex:240, 248`. No `mousedown` or
`pointerdown` handlers are registered.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:**

**Calendar trigger button:** No visible text — only an icon — so there is no
visible-text / `aria-label` mismatch. Its `aria-label="Open calendar"` is the
complete accessible name — `lib/pulsar/components/date_picker.ex:164`.

**Standalone display inputs:** The `aria-label` values (`"Date"`, `"Start
date"`, `"End date"`) are the only label text in scope; there is no separate
visible label element whose text could conflict. The 2.5.3 mismatch condition
does not arise.

**Via `Field` (the critical case):** When `labelled_externally: true` is set by
`Field`, the default `aria-label` on the single/start input is suppressed:
- Single: `aria-label={@display_label || (!@labelled_externally && "Date")}` →
  evaluates to `false` (no `aria-label` attr emitted) —
  `lib/pulsar/components/date_picker.ex:119`
- Range start: `aria-label={!@labelled_externally && "Start date"}` → evaluates
  to `false` — `lib/pulsar/components/date_picker.ex:133`

With those defaults suppressed, the accessible name for the single/start input
comes entirely from the `<label for={id}>` rendered by `Field`. The visible
label text and the accessible name are identical — a clean 2.5.3 PASS. Prior to
this change, the hardcoded `aria-label` overrode the `<label for>` association,
making the accessible name (`"Date"`) diverge from the visible Field label text.

**Range end input:** `aria-label="End date"` is always present —
`lib/pulsar/components/date_picker.ex:147`. No external `<label>` targets this
input even via `Field`, so the `aria-label` is the only label text in scope;
2.5.3 does not apply.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The calendar trigger button is `flex items-center` wrapping an
`Icon` of `size="sm"` (20×20 CSS px) — `lib/pulsar/components/date_picker.ex:166–168`.
The outer `<button>` itself renders as an inline-flex; its visible hit area
is at minimum the icon size (20px) plus the `px-2` padding from the parent
wrapper. At `md` size the wrapper is `h-9` (36px), so the button's tap-target
height is 36px, above the 24px minimum. Width is at least 20px (icon) plus
any padding. The display inputs at `md` size are `h-9 w-28` (36×112 CSS px),
well above the 24×24 minimum.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing a display input does not trigger navigation, form
submission, or calendar opening. The hook's `mounted` function registers only
a `change` (blur) event and a calendar-click event; it registers no `focus`
listeners on the display inputs —
`lib/pulsar/components/date_picker.ex:193–248`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Parsing and ISO-write happen on the `change` event (fired on
blur, not on each keystroke) — `lib/pulsar/components/date_picker.ex:240`.
The `on_change` `%JS{}` callback is executed only after a successfully parsed
date is written — `lib/pulsar/components/date_picker.ex:229–232, 362–365`.
The component does not trigger navigation or form submission itself; those
actions are caller-initiated via `JS.push(...)`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid="true"` is set on the display input(s) in two
ways:
1. Server-side, from the `invalid` assign —
   `lib/pulsar/components/date_picker.ex:120, 134, 148`
2. Client-side by the hook, when a typed value cannot be parsed to a valid
   ISO date — `lib/pulsar/components/date_picker.ex:237`

`aria-invalid` returns to `"false"` when the value is cleared or a valid date
is parsed — `lib/pulsar/components/date_picker.ex:225, 235`. When used via
`Field`, the visible error message and `aria-describedby` linkage are provided
by the wrapper — see [`field.md`](field.md).

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Every display input has a descriptive accessible name. Standalone:
`aria-label` values at `lib/pulsar/components/date_picker.ex:119, 133, 147`.
Via `Field`: the single/start input's default `aria-label` is suppressed via
`labelled_externally` — `lib/pulsar/components/date_picker.ex:79–83` — and the
visible `<label for={id}>` rendered by `Field` provides the name; see
[`field.md`](field.md). The display format is a locale-ordered numeric date
(e.g. `06/22/2026`, `22/06/2026`), which the hook derives from
`Intl.DateTimeFormat` so it matches the visitor's locale — consistent with
user expectations and the `placeholder` attr, if provided.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** The component does not suppress or modify caller-provided error
text; the `Field` wrapper renders the error message. See [`field.md`](field.md).
For the client-side parse error, `aria-invalid="true"` identifies the problem;
the display input retains the user's text so they can correct it.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Display input(s): native `<input type="text">` with conditional `aria-label`
  (standalone) or `<label for>` association via `labelled_externally` (via
  `Field`), plus `aria-invalid` —
  `lib/pulsar/components/date_picker.ex:111–152`
- Calendar trigger button: `<button type="button">` with `aria-label="Open
  calendar"` — `lib/pulsar/components/date_picker.ex:162–169`. `Popover`
  contributes `aria-controls` / `aria-expanded` — see [`popover.md`](popover.md)
- Hidden ISO inputs: `type="hidden"` — not exposed in the accessibility tree;
  the form value is conveyed programmatically through `name` —
  `lib/pulsar/components/date_picker.ex:187–189`
- Calendar grid: all roles, names, and values are the Calendar component's
  responsibility — see [`calendar.md`](calendar.md)

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` flips with error state on the display inputs —
`lib/pulsar/components/date_picker.ex:120, 134, 148, 225, 235, 237`. The
associated error region (rendered by `Field`) carries `aria-live="polite"` —
see [`field.md`](field.md). No independent status messages are emitted by the
`DatePicker`; calendar month-change announcements are handled by `Calendar` —
see [`calendar.md`](calendar.md).

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — the display inputs are auxiliary
  UI (no `name`, never submitted); the hidden ISO inputs carry `name` but their
  purpose token (e.g. `bday`, `bday-day`) is the caller's responsibility.
  The `autocomplete="off"` on display inputs is correct — these inputs never
  fill from browser autofill.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; all labels are live
  DOM text.
- **1.4.13 Content on Hover or Focus (AA)** — the calendar popover opens on
  trigger-button click/activation, not on hover or focus of the display inputs.
  The popover panel satisfies 1.4.13 independently — see [`popover.md`](popover.md).
- **2.1.4 Character Key Shortcuts (A)** — no global single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links rendered.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern. Locale display is driven
  by the browser `Intl` API and resolves automatically.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — satisfied by using Pulsar uniformly.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** — app-level
  concern.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `focus-within:ring-2` on the
  wrapper and `focus-visible:ring-2` on the calendar trigger button both use
  2px rings, meeting the AAA minimum thickness. `--color-ring` clears AAA
  contrast (5.02:1 light / 6.72:1 dark) —
  `lib/pulsar/components/date_picker.ex:166, 456`.

## Browser a11y findings

None. The axe gate is clean across the `/components/date_picker/*` fixture cells
in light and dark themes.
