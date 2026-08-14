# Table · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/table.ex`](../../lib/pulsar/components/table.ex)
**Tests:** [`test/pulsar/components/table_test.exs`](../../test/pulsar/components/table_test.exs)
**Audited:** 2026-05-24 (code-only)

Data table with native `<table>` / `<thead>` / `<tbody>` semantics,
Phoenix `LiveStream` support, optional row-click (which makes the row a
keyboard-operable pseudo-button), action column, striped rows, sticky
header, loading state, and empty state.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Empty-state SVG icon has `aria-hidden="true"` —
  `lib/pulsar/components/table.ex`, `table/1`
- Action column `<th>` contains visually-hidden text label
  `<span class="sr-only">Actions</span>` — `lib/pulsar/components/table.ex`, `table/1`
- Test `decorative SVG has aria-hidden` — `test/pulsar/components/table_test.exs`
- Test `includes screen reader text for actions` — `test/pulsar/components/table_test.exs`

**Notes:** Decorative graphics hidden from AT; the actions column has a
programmatic name even though it has no visible header text.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<table>` with `<thead>` and `<tbody>` —
  `lib/pulsar/components/table.ex`, `table/1`
- Column headers use `<th scope="col">` — `lib/pulsar/components/table.ex`, `table/1`
- Sortable column headers keep `<th scope="col">` and put `aria-sort` on that
  owning `<th>`; `ascending`, `descending`, `other`, and `none` are supported —
  `lib/pulsar/components/table.ex`, `table/1`
- A column with no current direction reports `aria-sort="none"` rather than
  dropping the attribute, so the sort state stays exposed on every sortable
  header — `lib/pulsar/components/table.ex`, `sort_direction/1`
- Test `treats a dynamic nil sort direction as none` covers the runtime `nil`
  that the slot's compile-time `values:` list cannot catch —
  `test/pulsar/components/table_test.exs`
- Test `renders table headers correctly` asserts `scope="col"` —
  `test/pulsar/components/table_test.exs`
- Test `includes proper semantic markup` asserts `<table>`/`<thead>`/`<tbody>`/`scope="col"` —
  `test/pulsar/components/table_test.exs`
- Test `renders the sortable affordance and state inside the semantic column header`
  asserts the state remains on the header — `test/pulsar/components/table_test.exs`
- Test `supports every valid aria-sort value with the default Heroicons` covers
  every supported `aria-sort` value — `test/pulsar/components/table_test.exs`
- Test `keeps ordinary headers non-interactive and omits aria-sort` verifies
  non-sortable headers retain their existing semantics —
  `test/pulsar/components/table_test.exs`

**Notes:** No row headers — the component treats all data cells as
`<td>`, which is correct for a generic data table where rows aren't
labeled. A `<caption>` element can be supplied via the `:caption` slot —
see 2.4.6 for full accessible-name affordances.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Rows render in `Enum.with_index` order over `@rows`;
columns render in slot order — `lib/pulsar/components/table.ex`.
Action column always appears last, matching its visual position.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instructions rely on column color or shape. Striping
and sticky header are decorative —
`lib/pulsar/components/table.ex`, `build_container_classes/1`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color variants are decorative emphasis on the header.
Row-click hover state combines `cursor-pointer`, hover background, and
focus ring, not color alone — `lib/pulsar/components/table.ex`, `build_row_classes/1`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Header `solid` variant uses paired `bg-*` / `text-*-foreground`
tokens — `lib/pulsar/components/table.ex`, `build_header_classes/1`. Empty state uses
`text-muted-foreground` — `lib/pulsar/components/table.ex`, `table/1`.
Browser measurement of 56 cells across both themes: all pass, min
19.27:1 (light) / 16.98:1 (dark) ([light](measurements/table-light.md),
[dark](measurements/table-dark.md)). Existing axe `color-contrast`
violations on the header solid variant are tracked separately
— the measurement script doesn't see those because the fixture
exercises the outline variant header by default.

**Notes:** The tracked axe failures are header `solid` variant
combos not currently exercised by the table fixture; expand the fixture
to render those before re-measuring.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Cell sizing uses `rem`-based Tailwind classes (`text-xs`
through `text-xl`) — `lib/pulsar/components/table.ex`,
`build_header_cell_classes/3`, `build_data_cell_classes/3`. No fixed
`px` font sizes or heights.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Container is wrapped in `relative overflow-x-auto` —
`lib/pulsar/components/table.ex`, `build_container_classes/1`. Table uses `w-full border-collapse`
— `lib/pulsar/components/table.ex`, `build_table_base_classes/0`.

**Notes:** Horizontal scroll on the wrapper is the WCAG-recommended
pattern for wide data tables at narrow viewports; users can scroll the
table without horizontal page scroll. Per WCAG 1.4.10 understanding doc,
"data tables" are explicit exempt content where horizontal scrolling
within the component is acceptable.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Row borders use `border-border/50` (50% opacity) —
  `lib/pulsar/components/table.ex`, `build_row_classes/1` — decorative, exempt under
  WCAG 1.4.11.
- Outline variant header uses `border-b-2 border-border` —
  `lib/pulsar/components/table.ex`, `build_header_classes/1`.
- Row focus ring uses `focus-visible:ring-ring focus-visible:ring-offset-2`
  resolving to the standard `--color-ring` token —
  `lib/pulsar/components/table.ex`, `build_row_classes/1`.

Row focus ring matches Button at full opacity (5.02:1 / 6.72:1) —
above the 3:1 minimum in both themes.

**Notes:** Previously failed because the row focus ring used
`focus:ring-primary/20` (20% opacity). Resolved by switching to the
neutral `--color-ring` token at full opacity and using `focus-visible:`
(keyboard-only) for consistency with Button/Input.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed-height cells; padding-only sizing —
`lib/pulsar/components/table.ex`, `build_header_cell_classes/3`,
`build_data_cell_classes/3`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- Row with `row_click` gets `tabindex="0"` and `role="button"` —
  `lib/pulsar/components/table.ex`, `table/1`
- Colocated `.PulsarTableRow` hook delegates from the `<tbody>` to rows
  marked `data-row-click="true"` and activates them on Enter, keypad
  Enter, or Space —
  `lib/pulsar/components/table.ex`, `table/1`
- Test `adds keyboard accessibility attributes when row_click provided` —
  `test/pulsar/components/table_test.exs`
- Sortable headers contain a native `<button type="button">` inside their
  `<th scope="col">`, so they are keyboard-operable without a custom key
  handler — `lib/pulsar/components/table.ex`, `table/1`
- Test `renders the sortable affordance and state inside the semantic column header`
  asserts the native button — `test/pulsar/components/table_test.exs`
- Real-browser test `Space and Enter cycle a sortable column header` drives the
  header button with both keys and asserts the resulting `aria-sort` value and
  visible chevron — `test/integration/a11y/keyboard/table_test.exs`

**Notes:** Static (non-clickable) tables are inherently keyboard-safe —
no interactive elements added by the component.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Hook handles only Enter/Space; does not block Tab —
`lib/pulsar/components/table.ex`, `table/1`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Loading skeleton uses `animate-pulse` which is
essential-to-function (loading indicator, exempt under 2.2.2) —
`lib/pulsar/components/table.ex`, `table/1`. Row transitions are smooth
`transition-colors` — `lib/pulsar/components/table.ex`, `build_row_classes/1`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are smooth color transitions and
`animate-pulse` for skeletons — no flashing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Clickable rows use `tabindex="0"` —
`lib/pulsar/components/table.ex`, `table/1`. Reading order is row-then-cell
following DOM. No positive `tabindex`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Three first-class accessible-name affordances are exposed on
`table/1`:

* `aria_label` attr — `lib/pulsar/components/table.ex`, `table/1`,
  rendered as `aria-label` on `<table>` —
  `lib/pulsar/components/table.ex`, `table/1`.
* `aria_labelledby` attr — `lib/pulsar/components/table.ex`, `table/1`,
  rendered as `aria-labelledby` —
  `lib/pulsar/components/table.ex`, `table/1`.
* `:caption` slot — `lib/pulsar/components/table.ex`, `table/1`, rendered
  as the first child of `<table>` —
  `lib/pulsar/components/table.ex`, `table/1`.

If none of these is provided (and no `aria-label` / `aria-labelledby`
passes through the global `:rest`), the component emits
`Logger.warning` to nudge the caller —
`lib/pulsar/components/table.ex`, `warn_if_missing_accessible_name/1`.
Rendering is not blocked. The
docstring documents all three patterns —
`lib/pulsar/components/table.ex`, `table/1`.

Column-level labels remain in place: each `<:col>` slot requires a
`label`, and the action column carries an `sr-only` "Actions" header.

**Tests:** `test/pulsar/components/table_test.exs` — the
`"table/1 accessible name (WCAG 2.4.6)"` describe block covers all three
affordances, the info log nudge, suppression for each affordance, and
the global-`:rest` passthrough path.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Row focus uses
`focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background`
— `lib/pulsar/components/table.ex`, `build_row_classes/1`. Ring resolves to the standard
`--color-ring` token at 5.02:1 (light) / 6.72:1 (dark).

Sortable header buttons use `hover:bg-foreground/10` and
`focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-current` —
`lib/pulsar/components/table.ex`, `build_sort_button_classes/1`. These buttons
sit on the header surface, which the `solid` variant paints with a full-strength
accent (`bg-primary`, `bg-danger`, …). `ring-current` draws the indicator in the
header's own foreground token — the same color as the header label beside it —
so the indicator carries that pair's contrast on every variant and color instead
of the fixed `--color-ring` blue, which measures below 3:1 on a solid header.
The ring is inset so it tracks the button box without overflowing the header
cell padding. Test
`renders the sortable affordance and state inside the semantic column header`
asserts those focus-visible ring classes on the rendered native sortable button —
`test/pulsar/components/table_test.exs`.

**Notes:** Uses `focus-visible:` (keyboard-only) consistent with
Button/Input. Mouse activation no longer paints a focus ring on the
row.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Sticky header (`sticky_header={true}`) applies
`[&_thead_th]:sticky [&_thead_th]:top-0 [&_thead_th]:z-docked`
**and** a size-appropriate `[&_tbody_tr]:scroll-mt-{N}` so focused
rows scroll clear of the sticky thead —
`lib/pulsar/components/table.ex`, `build_container_classes/1`. Per-size scroll-margin
values mirror the thead row height —
`lib/pulsar/components/table.ex`, `build_container_classes/1`.

Test `applies size-appropriate scroll-margin on rows so focus is not obscured` —
`test/pulsar/components/table_test.exs`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Delegated hook triggers `row.click()` for Enter and keypad
Enter on `keydown`, and for Space on `keyup` —
`lib/pulsar/components/table.ex`, `table/1`. Native click on the row uses
`mouseup`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Clickable row has no `aria-label` injected by the
component; accessible name is computed from cell text content —
`lib/pulsar/components/table.ex`, `table/1`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Row height at the smallest size is dictated by `py-1 text-xs`
(`lib/pulsar/components/table.ex`, `build_data_cell_classes/3`) which yields roughly 24px row
height for `xs`. Clickable rows span the full table width, so width is
not a concern — only height. Browser measurement of 56 fixture
cells (table headers, cells, multiple sizes): all rows ≥ 24×24
([light](measurements/table-light.md),
[dark](measurements/table-dark.md)).

**Notes:** `xs` rows measure ~28px in the fixture due to default font
metrics; sm/md/lg sizes exceed 32 px.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus-triggered behavior in template.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Native `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>` carry
  implicit roles — `lib/pulsar/components/table.ex`, `table/1`
- Loading state exposes `aria-busy={to_string(@loading)}` on the
  `<table>` — `lib/pulsar/components/table.ex`, `table/1`
- Clickable rows add explicit `role="button"` —
  `lib/pulsar/components/table.ex`, `table/1`
- Column headers carry `scope="col"` —
  `lib/pulsar/components/table.ex`, `table/1`
- Sortable headers expose their state with `aria-sort` on the `<th>`, while
  the nested native button supplies the role and name from its label —
  `lib/pulsar/components/table.ex`, `table/1`
- The built-in Heroicons are decorative (`aria-hidden="true"`); assistive
  technology receives the sort state from `aria-sort` instead. Test
  `supports every valid aria-sort value with the default Heroicons` verifies
  each state and icon — `test/pulsar/components/table_test.exs`

**Notes:** Empty state row uses `class="only:table-row hidden"` —
`lib/pulsar/components/table.ex`, `table/1`. The `only:` Tailwind variant
relies on the empty `<tr>` being `:only-child` of `<tbody>` to display.
This is a clever CSS-only solution but exposes a tabIndex-less hidden
row to AT until it becomes the only child. Functionally safe but worth
noting.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:**
- Loading state renders a visually-hidden `role="status" aria-live="polite"`
  region announcing "Loading rows" — `lib/pulsar/components/table.ex`, `table/1`
- `aria-busy="true"` set on the `<table>` while loading —
  `lib/pulsar/components/table.ex`, `table/1`

**Notes:** Loading skeletons are visual; the SR announcement and
`aria-busy` together convey state programmatically.

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
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or popover.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — links inside cells are caller-supplied.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no multipoint/path gestures.
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

- **4.1.3 Status Messages (AA, achieved with bonus rigor)** — loading
  state pairs `aria-busy` with a `role="status"` live region, going
  beyond the typical single-mechanism implementation.
- Native semantic `<table>` markup with `<th scope="col">` is a
  meaningful structural win over many comparable libraries that ship
  `<div role="table">` shells.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `color-contrast` | light: success header; dark: dark text on dark bg | both |
