# Command · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/command.ex`](../../lib/pulsar/components/command.ex)
**Tests:** [`test/pulsar/components/command_test.exs`](../../test/pulsar/components/command_test.exs)
**Keyboard tests:** [`test/integration/a11y/keyboard/command_test.exs`](../../test/integration/a11y/keyboard/command_test.exs)
**Audited:** 2026-08-14 (code review)

A searchable, keyboard-navigable option list. A `role="combobox"` query
input filters a `role="listbox"` of `role="group"`/`role="option"` rows with
a roving `aria-activedescendant` — real DOM focus never leaves the input.
The `.PulsarCommand` colocated hook owns arrow/Home/End navigation, dispatches
a real click on Enter, and runs the caller's `on_cancel` `%JS{}` on Escape
without `preventDefault` so an enclosing `<dialog>`/`[popover]` can still
close itself. The component holds no value of its own: selecting an option
runs the caller's `on_select` `%JS{}` and resets the query. A visually-hidden
`<label>` names the query field, and a polite `role="status"` region
announces the result count on every filter.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The optional per-option icon (`Icon.icon`) sits beside the
row's own visible label text, so it is decorative rather than the sole
carrier of meaning — `lib/pulsar/components/command.ex`, `render/1`. The
loading spinner (`Spinner.spinner :if={@loading} decorative`) is explicitly
marked `decorative` rather than exposing its own accessible name: the
component already carries a `role="status"` live region announcing the
result count, and a second announcing element (the spinner) would compete
with it — `render/1`. No other images render.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- The query field is `role="combobox"` with `aria-expanded="true"`,
  `aria-controls`, `aria-autocomplete="list"`, and `aria-activedescendant`
  wired to the active row — `render/1`
- The results container is `role="listbox"` — `render/1`
- Options group under `role="group" aria-labelledby="…-group-N"`, with a
  visible heading element carrying that id — `render/1`,
  `group_label/1`
- Each row is `role="option"` with a stable `id` the input's
  `aria-activedescendant` can target — `render/1`
- A real `<label for="…-input">` (visually hidden via `sr-only`) names the
  query field — `render/1`. Test
  test "the query field has an accessible name from a real label element".

**Two deliberate tradeoffs, documented so a future edit doesn't "fix" them
back into a worse state:**

1. **The empty-results row carries `role="option" aria-disabled="true"`** —
   `render/1`. A `role="listbox"` with zero owned `option`/`group` children
   fails axe-core's `aria-required-children` rule, so an empty result set
   still needs one `option` child to stay valid ARIA. The tradeoff: a screen
   reader announces "No results found" as a disabled option, mildly
   duplicating the polite `role="status"` count region that already
   announces "0 results" on the same re-render. This row carries no `id`
   and no `data-command-option`, so it can never become the
   `aria-activedescendant` target (only elements with an `id` reachable from
   `"#{@id}-option-#{index}"` are addressable) and the hook's `options()`
   selector — which only collects `[data-command-option]` elements — never
   sees it, so it is unreachable by keyboard.
2. **`group_results/1` groups with `Enum.chunk_by/2`, which only merges
   *consecutive* same-group runs.** Options sharing a group label but
   separated by a different group in the filtered/ranked order render as
   two separate `role="group"` blocks with duplicate `aria-labelledby`
   headings, rather than one merged group. This follows the documented
   first-appearance ordering (`options/1`, `default_filter/2`; test
   `test "group order follows first appearance and options stay flat"`)
   and preserves the filter's global ranking instead of silently
   reshuffling rows to merge same-named groups. A caller whose filter or
   input data interleaves group labels will see a group heading repeat.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order matches visual order: the query field precedes the
listbox, group headings precede their rows, and rows render in the filtered
result order — `render/1`. Sequential row `id`s (`…-option-0`,
`…-option-1`, …) run across group boundaries in that same order —
`render/1`; test "option ids stay sequential across groups".

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Disabled rows are conveyed via `aria-disabled="true"` plus
`opacity-50` styling, not color alone — `render/1`,
`disabled_classes/1`. The active row is conveyed via `aria-selected="true"`
plus the color accent, not the accent alone — `render/1`,
`row_classes/2`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Every color-carrying state also carries a non-color signal:
disabled → `aria-disabled="true"` + `opacity-50`
(`disabled_classes/1`); active row → `aria-selected="true"` +
`data-active="true"` in addition to the `data-[active=true]:bg-{color}/10`
accent (`row_classes/2`, `render/1`). Group headings are
distinguished by position and typography (`text-xs font-medium`), not color.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Row text uses `text-foreground`; group headings, the
description line, and the shortcut `<kbd>` use `text-muted-foreground` —
`render/1`, `row_classes/2`. The `text-muted-foreground`
token measures 6.0–7.23:1 against all Pulsar surfaces including `/10`
tints, well above the 4.5:1 minimum (established house-wide; see
[`calendar.md`](calendar.md)). The active-row accent recolors text to
`text-{color}` on a `bg-{color}/10` tint for each of the seven colors
(`@accent`, consumed by `row_classes/2`) — the identical
tint pattern Alert's `ghost` variant already measures passing across all
seven colors in both themes (min 5.88:1 light / 8.16:1 dark, `info` being
the worst case) — `lib/pulsar/components/alert.ex`, `color_classes/2`.

**Notes:** The `/components/command` fixture varies `variant` (solid,
outline, ghost, elevated) but not `color`, so the axe-core browser gate's
scan of that fixture exercises only the default `primary` active-row
accent, not all seven colors. The other six colors are verified by
code-level token parity with Alert's already-measured `ghost` variant
above, not by a dedicated per-color axe pass of Command itself.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All row sizes use Tailwind's rem-based `text-xs`/`text-sm`/
`text-base` scale, and row height is driven by padding + line-height rather
than a fixed pixel container — `row_classes/2`,
`surface_classes/4` (`@row_size`). Text is not clipped by a
fixed-height box at larger user-agent text scales.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The root is `flex flex-col` with no enforced minimum width —
`surface_classes/4`. Long row labels truncate via `truncate`
rather than forcing horizontal scroll — `render/1`. The results
container scrolls vertically only (`overflow-y-auto`) —
`render/1`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The query input keeps `focus-visible:outline-none` (removing
the native outline), but its wrapper carries the replacement ring —
`class="flex items-center gap-2 focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-2"`
— `render/1`. This is the house convention for text-input focus rings:
`Input`'s base container classes put the ring on the wrapper the same way
(`focus-within:ring-2 focus-within:ring-offset-2` plus a per-color
`focus-within:ring-{color}`/`focus-within:ring-ring` for neutral) —
`lib/pulsar/components/input.ex`, `input/1`. `--color-ring` measures
5.02:1 (light) / 6.72:1 (dark) against the page background (established
house-wide; see [`calendar.md`](calendar.md)), well above the 3:1
non-text minimum. Test "the query field's wrapper carries a visible focus
ring".

**Notes:** The active-row highlight (`data-[active=true]:bg-{color}/10`,
`@accent`) is a separate, correctly-scoped indicator: it marks *which row
is current*, not *whether the input has focus* (see 2.4.3 — real DOM
focus never leaves the input, so the two concerns don't overlap). Its
contrast is covered under 1.4.3 above.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` overrides; text uses rem-based utilities.
Row height grows with content (padding + line-height, not a fixed pixel
box), so user text-spacing overrides don't clip row text —
`row_classes/2`. The `truncate` class on long labels is a
deliberate overflow-ellipsis design choice, not a spacing-override bug —
`render/1`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The `.PulsarCommand` hook's `handleKeydown` implements the
full contract inside `render/1`:
- `ArrowDown`/`ArrowUp` move the active row, wrapping at both ends —
  `render/1`
- `Home`/`End` jump to the first/last enabled row — `render/1`
- `Enter` dispatches a real `click()` on the active row, so the row's own
  `phx-click` (and the caller's `on_select`) run exactly as they would for
  a mouse click — `render/1`
- `Escape` runs the caller's `on_cancel` — `render/1`
- Disabled rows are excluded from the navigable set by the hook's
  `options()` selector (`[data-command-option]:not([aria-disabled="true"])`)
  — `render/1`

Real-browser keyboard tests in `test/integration/a11y/keyboard/command_test.exs`:
test "ArrowDown moves the active row, and Enter selects it",
test "ArrowDown skips the disabled row",
test "ArrowUp from the first row wraps to the last enabled row",
test "End jumps to the last enabled row and Home returns to the first",
test "Enter with no movement selects the first row".

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** `handleKeydown`'s `switch` only branches on `ArrowDown`,
`ArrowUp`, `Home`, `End`, `Enter`, and `Escape` — `render/1`. Tab and
Shift+Tab match no case and fall through untouched, so native Tab
behavior is preserved; the query input is a single tab stop and rows are
never independently focusable. `Escape` deliberately does not call
`preventDefault`, so an enclosing `<dialog>`/`[popover]` still gets to
close itself on the same keypress — `render/1`. Test
test "runs the cancel callback" —
`test/integration/a11y/keyboard/command_test.exs`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only animation is the loading spinner's `animate-spin`,
shown only while `@loading` is true and exempt as an essential-to-function
loading indicator — `render/1`. No auto-advancing or auto-updating
content otherwise.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing content; the spinner's rotation and the row
accent's `bg`/`text` swap are smooth, sub-3Hz transitions.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** The hook's `activate` helper never calls `.focus()` on a row; it
only toggles `data-active`/`aria-selected` and updates the input's
`aria-activedescendant`, then scrolls the row into view —
`render/1`. Real DOM focus stays on the query input for the
entire keyboard interaction. No positive `tabindex` is used anywhere.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Group headings render `option.group` as visible text tied to
the group via `aria-labelledby` — `render/1`,
`group_label/1`. The query field's accessible name comes from
a real, descriptive `<label>` (`@label`, default `"Search"`, documented as
i18n-overridable) — `render/1`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** See 1.4.11: the query input's wrapper carries
`focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-2`
— `render/1` — so tabbing to (or otherwise focusing) the input renders a
visible ring around it, matching the `Input` component's own focus-ring
convention (`lib/pulsar/components/input.ex`, `input/1`). Because focus
never leaves the input during keyboard use (2.4.3), this single ring is
the only focus event a sighted keyboard user needs signaled, and it now
renders on every focus. Test "the query field's wrapper carries a visible
focus ring".

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Command creates no sticky or fixed-position content of its
own — `surface_classes/4`, `render/1`. When embedded in a
Popover or Modal, the host component owns z-index isolation; Command
itself never layers content over its own input.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Row selection is wired via `phx-click`, which LiveView binds
to the native `click` event (fires on mouseup) — `render/1`. No
`mousedown`/`pointerdown` handler is used, so a pointer press can be
cancelled by dragging off the row before release.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Option rows carry no `aria-label`; their accessible name is
computed from their own visible text nodes (label, optional description,
optional shortcut) — `render/1`. The query field's accessible
name comes from its associated `<label>` text (`@label`), not a
conflicting `aria-label`; there is no visible text on the input itself to
contradict — `render/1`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Row height is padding + line-height from Tailwind's default
scale (`@row_size`, consumed by `row_classes/2`): `xs`
(`py-1` on `text-xs`, 8px + 16px = 24px), `sm` (`py-1` on `text-sm`,
8px + 20px = 28px), `md` (`py-1.5` on `text-sm`, 12px + 20px = 32px), `lg`
(`py-2` on `text-base`, 16px + 24px = 40px), `xl` (`py-2.5` on `text-base`,
20px + 24px = 44px). Every size meets or exceeds the 24×24 CSS px minimum;
row width spans the full container, so only height is at issue.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Moving the active row via arrow keys only updates
`data-active`/`aria-activedescendant`; it never runs `on_select` or pushes
a selection event — `render/1`. Selection happens only on `Enter`
(a synthetic click on the active row) or a real click.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Typing pushes the `"query"` event, which only re-filters the
result set (`handle_event/3`) — it never selects, submits, or navigates.
Choosing a row is a distinct, caller-initiated action that runs the
caller's own `on_select` `%JS{}` before the component resets its query —
`handle_event/3`, `render/1`. Test
test "a row's click runs the caller's JS, then the component's own reset".

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** A real `<label for="…-input">` names the query field
(default text `"Search"`, i18n-overridable via `@label`) —
`render/1`. Test
test "the query field has an accessible name from a real label element".
The `@placeholder` attribute supplies supplementary instruction text.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Query field: `role="combobox"`, `aria-expanded="true"`, `aria-controls`,
  `aria-autocomplete="list"`, `aria-activedescendant` — `render/1`
- Listbox: `role="listbox"`, `aria-busy={to_string(@loading)}` —
  `render/1`
- Groups: `role="group"`, `aria-labelledby` — `render/1`
- Options: `role="option"`, `aria-selected`, `aria-disabled` —
  `render/1`

`aria-busy` is written with `to_string(@loading)`, which always renders a
literal `aria-busy="true"` or `aria-busy="false"` attribute value —
`render/1`. This sidesteps a real bug class that shipped elsewhere in the
library: a HEEx boolean attr (`aria-busy={@loading}`) renders as a *bare*
attribute for `true` and is *omitted entirely* for `false`, never
`="true"`/`="false"`. That earlier bug survived a full axe-core browser
scan, because axe only inspects the resting DOM state — the bare-vs-absent
distinction on an already-`false` render is indistinguishable from the
ARIA default. Command's dynamic `aria-busy` correctness is instead verified
by a real interaction test,
`test "marks its own listbox busy in flight, keeps prior rows, and shows a spinner"`
(`test/pulsar/dev_app/command_live_test.exs`), which asserts the literal
`aria-busy="true"` string mid-flight — not by the axe gate.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** A `role="status" aria-live="polite"` region announces the
result count on every render via `result_announcement/3` —
`render/1`. Test "the result count is announced politely".

## Not applicable

- **1.2.1–1.2.5 (media criteria, A/AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — the query field is a filter over
  the caller's option list, not a text input collecting personal user
  information; `autocomplete="off"` is deliberate, since Command supplies
  its own suggestion list (the listbox) rather than the browser's —
  `render/1`.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; icons are inline
  SVG via `Icon.icon`.
- **1.4.13 Content on Hover or Focus (AA)** — Command itself opens no
  hover/focus-triggered secondary content; it is an inline widget. A
  caller wrapping it in Popover/Tooltip inherits that component's own audit.
- **2.1.4 Character Key Shortcuts (A)** — no global single-character
  shortcuts; every intercepted key is a named navigation/action key.
- **2.2.1 Timing Adjustable (A)** — the debounce delay (`@debounce`,
  default 0 sync / 250ms async) is an implementation detail of when a
  keystroke is pushed to the server, not a user-facing time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — Command renders no `<a>`
  elements; rows are `role="option"` divs.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern; all rendered
  strings are caller-supplied and inherit the page language.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — satisfied by using Pulsar
  uniformly (library-wide claim, not tracked per-component).
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — Command is a selection/filter
  widget, not a validated text input; it produces no validation errors of
  its own.
- **3.3.3 Error Suggestion (AA)** — no input errors to suggest corrections
  for.
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level
  concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** —
  app-level concern.

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — the `xl` row size (`py-2.5` on
  `text-base` ≈ 44px tall) meets the AAA 44×44 px floor —
  `row_classes/2`.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — the query input's wrapper
  ring is `ring-2` (2px), meeting the AAA minimum ring thickness, and
  `--color-ring` clears AAA contrast (5.02:1 light / 6.72:1 dark) —
  `render/1`.

## Browser a11y findings

The `/components/command` fixture is registered in `@fixture_groups`
(`test/support/dev_app/components.ex`), so it participates in CI's
axe-core browser gate. Fix round 1 (see below) added a `focus-within`
ring to the query input's wrapper; the axe-core gate was re-run in full
after that change and found no violations for the Command fixture in
either theme. Note, though, that axe-core would not have caught the
original missing-ring defect on its own even before the fix — it checks
ARIA validity and the computed contrast of elements that exist, not
whether a focused element renders any visible focus indicator at all.
The regression coverage for that specific defect is the unit test "the
query field's wrapper carries a visible focus ring"
(`test/pulsar/components/command_test.exs`), not the axe gate.
