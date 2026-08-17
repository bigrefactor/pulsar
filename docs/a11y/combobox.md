# Combobox · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/combobox.ex`](../../lib/pulsar/components/combobox.ex)
**Tests:** [`test/pulsar/components/combobox_test.exs`](../../test/pulsar/components/combobox_test.exs)
**Keyboard tests:** [`test/integration/a11y/keyboard/combobox_test.exs`](../../test/integration/a11y/keyboard/combobox_test.exs)
**Audited:** 2026-08-17 (code + browser axe gate + keyboard interaction tests)

A text input that filters a list of options as you type. The
`role="combobox"` query input owns real DOM focus for the entire
interaction; a `role="listbox"` panel opens under it in a
`popover="manual"` panel, positioned by `Pulsar.Components.Popover`. The
`.PulsarCombobox` colocated hook owns filtering, arrow navigation, picking,
and (in `multiple` mode) badge removal; the component itself holds the
selected value(s) and reconciles them with the bound field. A polite
`role="status"` region announces the result count — and, in `multiple`
mode, the selected count — on every render.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The optional per-option icon (`Icon.icon`) sits beside the
row's own visible label text, so it reinforces meaning rather than
carrying it alone — `lib/pulsar/components/combobox.ex`, `render/1`. The
loading spinner (`Spinner.spinner decorative`) is explicitly marked
`decorative`; the polite `role="status"` region already announces the
result count on the same render, so a second announcing element would
compete with it — `render/1`. The clear button's `hero-x-mark` and the
chevron button's `hero-chevron-down` are decorative glyphs inside a real
`<button>` that carries its own `aria-label` (`@clear_label`,
`@open_label`) — `render/1` — so the icon adds nothing to the accessible
name and isn't the sole carrier of the button's purpose.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- The query field is `role="combobox"` with `aria-expanded`,
  `aria-controls`, `aria-autocomplete="list"` — `render/1`. The hook
  maintains `aria-expanded` and `aria-activedescendant` client-side (see
  2.1.1).
- The results container is `role="listbox"`, with
  `aria-multiselectable="true"` in `multiple` mode — `render/1`.
- Options group under `role="group" aria-labelledby="…-group-N"`, with a
  visible heading element carrying that id — `render/1`,
  `group_label/1`.
- Each row is `role="option"` with a stable `id`
  (`"#{@id}-option-#{index}"`) the input's `aria-activedescendant` can
  target — `render/1`.
- A real `<label for="…">` (visually hidden via `sr-only` unless
  `@labelled_externally`, which Field sets when it supplies its own label)
  names the query field — `render/1`. Test
  test "the input has an accessible name from a real label element".

**Two deliberate tradeoffs, carried over from the sibling `command`
component and documented here so a future edit doesn't "fix" them back
into a worse state:**

1. **The empty-results row carries `role="option" aria-disabled="true"`**
   — `render/1`. This is the same axe-core `aria-required-children`
   accommodation `command` makes; see [`command.md`](command.md) for the
   full reasoning. This row carries no `id` and no `data-combobox-option`,
   so it is never addressable as `aria-activedescendant` and the hook's
   `options()` selector (which only collects `[data-combobox-option]`
   elements) never sees it — unreachable by keyboard, same as Command's
   equivalent row. Test "renders the empty state as a single unreachable
   option row".
2. **`group_results/1` groups with `Enum.chunk_by/2`, which only merges
   *consecutive* same-group runs.** Options sharing a group label but
   separated by a different group in the filtered/ranked order render as
   two separate `role="group"` blocks with duplicate `aria-labelledby`
   headings, rather than one merged group. This follows the same
   first-appearance ordering `options/1` establishes at normalization time
   (test "flattens the nested group shape and keeps first-appearance
   order") and preserves the filter's ranking instead of silently
   reshuffling rows to merge same-named groups. A caller whose `filter`
   interleaves group labels across the ranked result set will see a group
   heading repeat.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order matches visual order: badges precede the input,
which precedes the spinner/clear/chevron controls, which precede the
listbox panel — `render/1`. Sequential row `id`s (`…-option-0`,
`…-option-1`, …) run across group boundaries in filtered-result order —
`render/1`. Test "option rows carry sequential ids and option roles".

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Disabled rows are conveyed via `aria-disabled="true"` plus
`opacity-50` styling, not color alone — `render/1`, `disabled_classes/1`.
The selected row is conveyed via `aria-selected="true"` plus a check icon
(`hero-check`), not the accent color alone — `render/1`. The active row is
conveyed via `data-active="true"` plus the color accent, not the accent
alone — `render/1`, `row_classes/2`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Every color-carrying state also carries a non-color signal:
disabled → `aria-disabled="true"` + `opacity-50` (`disabled_classes/1`);
selected → `aria-selected="true"` + a check icon (`render/1`); active row →
`data-active="true"` in addition to the `data-[active=true]:bg-{color}/10`
accent (`row_classes/2`, `render/1`). Group headings are distinguished by
position and typography (`text-xs font-medium`), not color.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Row text uses `text-foreground`; group headings, option
descriptions, the placeholder, and the clear/chevron icons use
`text-muted-foreground` — `render/1`, `row_classes/2`. The
`text-muted-foreground` token measures 6.0–7.23:1 against all Pulsar
surfaces including `/10` tints, well above the 4.5:1 minimum (established
house-wide; see [`calendar.md`](calendar.md)). The active-row accent
recolors text to `text-{color}` on a `bg-{color}/10` tint for each of the
seven colors (`@accent`, consumed by `row_classes/2`) — the identical
tint pattern Alert's `ghost` variant already measures passing across all
seven colors in both themes (min 5.88:1 light / 8.16:1 dark, `info` being
the worst case) — `lib/pulsar/components/alert.ex`, `color_classes/2`.

**Notes:** The `/components/combobox` fixture varies `variant` (outline,
solid, ghost) plus separate cells for a selected value, `multiple`, a
grouped list, and an async source, but not `color`, so the axe-core
browser gate's scan of that fixture exercises only the default `primary`
active-row accent, not all seven colors. The other six colors are
verified by code-level token parity with Alert's already-measured `ghost`
variant above, not by a dedicated per-color axe pass of Combobox itself.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All input and row sizes use Tailwind's rem-based
`text-xs`/`text-sm`/`text-base` scale, driven by `@input_size` and
`@row_size` — `input_classes/1`, `row_classes/2`. Row height is driven by
padding + line-height rather than a fixed pixel container. Text is not
clipped by a fixed-height box at larger user-agent text scales.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The field wrapper is `flex flex-wrap` — badges and the input
wrap onto additional lines rather than forcing horizontal scroll —
`wrapper_classes/3`. Row labels truncate via `truncate` rather than
overflowing — `render/1`. The listbox panel scrolls vertically only
(`max-h-64 overflow-y-auto`, set on the `Popover.popover` it renders
inside) — `render/1`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The `outline` variant's wrapper border uses `border-border`
against `bg-background` — `lib/pulsar/components/combobox.ex`,
`wrapper_classes/3` (`@wrapper_variant`). This is the identical class pair
`date_picker`'s outline wrapper uses and has already measured: `gray-200`
against `#fff` ≈5.4:1 (light), `gray-800` against `gray-950` ≈4.9:1
(dark), both above the 3:1 non-text minimum — see
[`date_picker.md`](date_picker.md). The `solid` variant (`bg-surface-2`,
no border) and `ghost` variant (`bg-transparent`, no border) carry no
at-rest boundary of their own, matching the same choice `input`'s `solid`
and `ghost` variants already make (see [`input.md`](input.md)) — for a
text field, the focus-within ring below is the operative indicator, not
an at-rest border, and library-wide precedent treats that as sufficient
for these two variants.

The wrapper carries `focus-within:ring-2 focus-within:ring-ring` in every
variant — `wrapper_classes/3`. `--color-ring` measures 5.02:1 (light) /
6.72:1 (dark) against the page background (established house-wide; see
[`calendar.md`](calendar.md)).

**Notes:** The active-row highlight
(`data-[active=true]:bg-{color}/10`, `@accent`) and the clear/chevron
button icons (`text-muted-foreground`, well above 3:1 per 1.4.3 above) are
separate, correctly-scoped indicators, not substitutes for the field
boundary.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` overrides; sizes are rem-based utilities.
Row height and the wrapper's `py-1`/`px-2` padding grow with content
rather than clipping under user text-spacing overrides —
`wrapper_classes/3`, `row_classes/2`. The `truncate` class on long labels
is a deliberate overflow-ellipsis design choice, not a spacing-override
bug — `render/1`.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** Unlike `command` (an always-inline listbox), Combobox opens
its listbox as a real `popover="manual"` panel
(`Pulsar.Components.Popover`), triggered on **focus**, not hover —
`render/1` (`openList()` runs from the input's `focus` listener). The
panel is dismissable by keyboard (Escape) and by clicking outside
(`_onDocPointer`, added only while open) — `render/1`. It is persistent:
nothing closes it merely because the pointer moves over it, and it stays
open across re-renders (`updated()` re-asserts `aria-expanded` from the
hook's own `this.open` state rather than trusting the server's always-closed
markup) — `render/1`. Manual `popover` mode delegates all open/close
control to Combobox's own hook rather than the browser's native
`popover="auto"` light-dismiss, so these three requirements
(dismissable, hoverable, persistent) are Combobox's own responsibility,
not inherited from Popover's `click`-mode behavior documented in
[`popover.md`](popover.md).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The `.PulsarCombobox` hook's `handleKeydown` implements the
full contract, inside `render/1`:

| Key | Closed | Open |
|---|---|---|
| Type a character | opens the list, filters | filters (debounced query push) |
| `ArrowDown` / `ArrowUp` | opens the list | moves the active row, wrapping at both ends |
| `Enter` | not intercepted — falls through so an enclosing form still submits | picks the active row (synthetic `pick()`) |
| `Escape` | — | closes the list, restoring the resting display |
| `Tab` | — | closes the list (never picks) and moves focus natively |
| `Backspace` (multiple, query empty) | removes the last badge | removes the last badge |
| `Home` / `End` | unhandled | unhandled |

- `ArrowDown`/`ArrowUp` wrap at both ends and skip disabled rows, because
  `options()` filters to `[data-combobox-option]:not([aria-disabled="true"])`
  — `render/1`.
- **Enter falls through when the list is closed**, deliberately: the
  `case "Enter"` branch is a no-op unless `this.open`, so a closed
  Combobox inside a `<form>` lets the native Enter-submits-the-form
  behavior happen instead of being swallowed — `render/1`.
- **Escape does not call `preventDefault`**, so an enclosing
  `<dialog>`/`[popover]` still gets to close itself on the same keypress
  — `render/1`.
- **Tab closes the list and never picks.** `handleKeydown`'s `"Tab"` case
  only calls `closeList()`; picking happens only via `Enter` (while open)
  or a click — `render/1`.
- **Backspace on an empty query removes the last badge** in `multiple`
  mode only, and only when the input's own value is already empty (so it
  never fights native text deletion) — `render/1`.
- **`Home`/`End` are deliberately unhandled**: the query field is an
  editable combobox, so those keys (and Shift+Home/Shift+End selection)
  stay with the caret, matching Command's same choice
  (`lib/pulsar/components/command.ex`, `render/1`).

Real-browser keyboard tests in `test/integration/a11y/keyboard/combobox_test.exs`:
test "opens the list and filters to matches",
test "ArrowDown moves the active row and Enter picks it",
test "ArrowDown skips the disabled row",
test "Enter with no movement picks the first row",
test "Escape closes the list and restores the resting label",
test "Backspace on an empty query removes the last badge",
test "the chevron opens the list without typing",
test "the clear button empties the value".

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** `handleKeydown`'s `switch` only branches on `ArrowDown`,
`ArrowUp`, `Enter`, `Escape`, `Tab`, and `Backspace` — `render/1`. Every
other key (including Shift+Tab) falls through untouched. `Tab` itself is
never `preventDefault`-ed; it only triggers `closeList()` as a side
effect before native focus movement proceeds — `render/1`. Badge remove
buttons and the clear button are real `<button>` elements and ordinary
tab stops; the chevron toggle carries `tabindex="-1"` so it never
interrupts the tab sequence — `render/1`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only animation is the loading spinner's `animate-spin`,
shown only while `@loading` is true and exempt as an essential-to-function
loading indicator — `render/1`. No auto-advancing or auto-updating content
otherwise.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing content; the spinner's rotation and the active
row's `bg`/`text` accent swap are smooth, sub-3Hz transitions.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** The hook's `activate` helper never calls `.focus()` on a
row; it only toggles `data-active`/`aria-activedescendant` and scrolls the
row into view — `render/1`. Real DOM focus stays on the query input for
arrow-key navigation. The only other focusable elements — badge remove
buttons (present only in `multiple` mode, before the input) and the clear
button (after the input) — appear in the same order as they render
visually; the chevron toggle is excluded from the tab sequence via
`tabindex="-1"` — `render/1`. No positive `tabindex` is used anywhere.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Group headings render `option.group` as visible text tied to
the group via `aria-labelledby` — `render/1`, `group_label/1`. The query
field's accessible name comes from a real, descriptive `<label>` (`@label`,
default `"Search"`, documented as i18n-overridable) — `render/1`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** See 1.4.11: the wrapper carries `focus-within:ring-2
focus-within:ring-ring` in every variant — `wrapper_classes/3` — so
focusing the input renders a visible ring around the whole field. Because
focus never leaves the input during arrow-key navigation (2.4.3), this
single ring is the only focus event a sighted keyboard user needs
signaled for the listbox interaction, and the clear/badge-remove buttons
carry the library's standard `focus-visible:outline-none
focus-visible:ring-2 focus-visible:ring-ring` for their own focus state —
`render/1`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Combobox creates no sticky or fixed-position content of its
own — `render/1`. The listbox panel is positioned by Popover, which owns
z-index isolation for its own panel.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Row picking, the clear button, and the chevron toggle are
all wired through a single `click` listener on the root element
(`handleClick`, bound via `addEventListener("click", …)`, which fires on
mouseup) — `render/1`. No `mousedown`/`pointerdown` handler drives any of
these actions, so a pointer press can be cancelled by dragging off the
target before release. (The root's `pointerdown` listener added while open
exists only to detect *outside* clicks that should close the list — it
never fires an action of its own.)

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Option rows carry no `aria-label`; their accessible name
comes from their own visible text nodes (icon aside, label, optional
description) — `render/1`. The clear and chevron buttons carry
`aria-label` (`@clear_label`, `@open_label`) but render no visible text of
their own (icon-only), so there is no visible label text to contradict —
`render/1`. The query field's accessible name comes from its associated
`<label>` text (`@label`), not a conflicting `aria-label` — `render/1`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The clear and chevron buttons both carry `min-h-6 min-w-6`
(24×24 CSS px) — `render/1` — the same house rule already established for
Badge's addon buttons, Alert's close button, and Flash's close button
(see [`badge.md`](badge.md), [`alert.md`](alert.md), [`flash.md`](flash.md)).
Badge's own remove buttons (rendered per selected value in
`multiple` mode) inherit the same 24×24 floor from Badge's own audit — see
[`badge.md`](badge.md) — rather than being re-derived here. Row height
across every `@row_size` meets or exceeds 24px (`xs` 24px through `xl`
44px, matching Command's identical `@row_size` scale — see
[`command.md`](command.md)); row width spans the full container, so only
height is at issue.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the input opens the listbox (`openList()`,
`_onFocus` listener) but this only reveals suggestions — it selects no
value, submits nothing, and moves focus nowhere else — `render/1`.
Moving the active row via arrow keys likewise only updates
`data-active`/`aria-activedescendant`; it never runs `on_change` or pushes
a selection event. Selection happens only on `Enter` (while open) or a
real click, both explicit user actions distinct from focus itself.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Typing pushes the `"query"` event, which only re-filters the
result set (`handle_event/3`) — it never selects, submits, or navigates.
Choosing a row is a distinct, user-initiated action (`pick()`) that writes
the hidden field/select and runs the caller's own `on_change` `%JS{}` —
`render/1`, `handle_event/3`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid={(@invalid && "true") || "false"}` always
renders a literal `"true"`/`"false"` string on the query input —
`render/1`. Test "marks invalid and required state on the input". As with
`select`/`input`, error text itself renders at the `field` wrapper level,
not inside Combobox.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** A real `<label for="…">` names the query field (default
text `"Search"`, i18n-overridable via `@label`) — `render/1`. Test "the
input has an accessible name from a real label element". `@placeholder`
supplies supplementary instruction text.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Combobox doesn't suppress error text of its own; rendering
happens at the `field` wrapper level, same as `select` (see
[`select.md`](select.md)).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Query field: `role="combobox"`, `aria-expanded`, `aria-controls`,
  `aria-autocomplete="list"`, `aria-invalid`, `aria-required` — `render/1`
- Listbox: `role="listbox"`, `aria-multiselectable`, `aria-busy={to_string(@loading)}`
  — `render/1`
- Groups: `role="group"`, `aria-labelledby` — `render/1`
- Options: `role="option"`, `aria-selected`, `aria-disabled` — `render/1`

**`aria-selected` reflects the selected value, never the active row.**
`aria-selected={to_string(to_string(option.value) in @selected)}` is
computed purely from `@selected` — `render/1`. The active row is conveyed
separately, by `aria-activedescendant` (maintained by the hook's
`syncActiveDescendant` method) plus `data-active` (rendered server-side,
`render/1`) — never by `aria-selected`. This is anchored on MDN's listbox
rule: *"All selected options have `aria-selected` set to `true`, and all
options that are not selected have `aria-selected` set to `false`."* Test
"aria-selected reflects the selected value, not the active row"
(`test/pulsar/components/combobox_test.exs`) and
test "selecting marks the row aria-selected, not merely active"
(`test/pulsar/dev_app/combobox_live_test.exs`).

This deliberately differs from the sibling `command` component, which has
no persisted "selected" concept of its own (it runs the caller's
`on_select` and resets) and so uses `aria-selected` to mean *active* — see
[`command.md`](command.md), 4.1.2. Combobox holds a real value, so its
`aria-selected` means what MDN's rule says it should.

`aria-busy` is written with `to_string(@loading)`, the same literal
`"true"`/`"false"` pattern Command's `aria-busy` uses for the same reason
— see [`command.md`](command.md), 4.1.2 — rather than a bare HEEx boolean
attr that would render nothing when `false`.

**Multi-select is deliberately outside APG's combobox pattern, and this
audit does not claim otherwise.** The WAI-ARIA Authoring Practices Guide's
combobox pattern states: *"The tree allows only one suggested value to be
selected at a time for the combobox value."* `multiple` mode — several
values held as removable badges, `aria-multiselectable="true"` on the
listbox — is not a shape APG's combobox pattern describes; it is not
claimed to be. Its ARIA shape instead follows ARIA 1.2's `listbox` role
(which explicitly supports `aria-multiselectable`) plus the same MDN
listbox rule quoted above — each option's own `aria-selected` reflects
whether *that* option is one of the several selected values, exactly as
it does in single-select mode. Nothing about picking or removing a value
moves focus (see 2.4.3, 3.2.1), so without the polite `role="status"`
live region naming the new selected count (`announcement/1`, see 4.1.3),
an add or a remove would be imperceptible to a screen reader user.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** A `role="status" aria-live="polite"` region announces the
result count on every render, and additionally the selected count in
`multiple` mode once something is selected — `render/1`,
`announcement/1`. Test "announces the result count in a polite status
region". Test "selecting in multiple mode accumulates values"
(`test/pulsar/dev_app/combobox_live_test.exs`) confirms the selected-count
half of the announcement updates on pick.

## Not applicable

- **1.2.1–1.2.5 (media criteria, A/AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — the query field is a filter over
  the caller's option list, not a text input collecting personal user
  information, and `:rest` is spread on the root wrapper `<div>`, not the
  `<input>` itself — `render/1` — so a caller cannot override
  `autocomplete`. `autocomplete="off"` is deliberate: Combobox supplies
  its own suggestion list (the listbox) rather than the browser's, the
  same reasoning `command` documents for its own query field — see
  [`command.md`](command.md).
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; icons are
  inline SVG via `Icon.icon`.
- **2.1.4 Character Key Shortcuts (A)** — no global single-character
  shortcuts; every intercepted key is a named navigation/action key.
- **2.2.1 Timing Adjustable (A)** — the debounce delay (`@debounce`,
  default 0 sync / 250ms async) is an implementation detail of when a
  keystroke is pushed to the server, not a user-facing time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — Combobox renders no `<a>`
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
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level
  concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** —
  app-level concern.

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — the `xl` row size (`px-3
  py-2.5` on `text-base` ≈ 44px tall) meets the AAA 44×44 px floor —
  `row_classes/2`.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — the field wrapper's
  focus ring is `ring-2` (2px), meeting the AAA minimum ring thickness,
  and `--color-ring` clears AAA contrast (5.02:1 light / 6.72:1 dark) —
  `wrapper_classes/3`.

## Browser a11y findings

The `/components/combobox` fixture is registered in `@fixture_groups`
(`test/support/dev_app/components.ex`), with cells `cb-outline`,
`cb-solid`, `cb-ghost`, `cb-selected`, `cb-multiple`, `cb-grouped`, and
`cb-async`, each with a distinct accessible label. It participates in
CI's axe-core browser gate (`test/integration/a11y/axe_clean_test.exs`),
the target-size gate (`test/integration/a11y/target_size_test.exs`), and
the reflow gate (`test/integration/a11y/reflow_test.exs`). All three ran
clean for Combobox in both themes as part of the full `mix test --only
integration` run (585 tests, 0 failures). The listbox is closed at rest
(`popover="manual"`, `display: none`), so a default scan exercises the
visible field, badges, and buttons; it does not scan the listbox's
contents, which is why the per-color note under 1.4.3 above matters.

The 16 real-browser keyboard tests in
`test/integration/a11y/keyboard/combobox_test.exs` all pass independently,
covering typing/filtering, arrow navigation with wrapping and
disabled-row skipping, Enter-to-pick, Escape-to-close, Tab-closes-without-
picking, the chevron and clear affordances, and `multiple` mode's badge
accumulation, phx-change propagation, and Backspace-removes-last-badge.
