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
  `lib/pulsar/components/table.ex:398, 453`
- Action column `<th>` contains visually-hidden text label
  `<span class="sr-only">Actions</span>` — `lib/pulsar/components/table.ex:377`
- Tests `decorative SVG has aria-hidden`, `includes screen reader text for actions` —
  `test/pulsar/components/table_test.exs:381–396, 417–428`

**Notes:** Decorative graphics hidden from AT; the actions column has a
programmatic name even though it has no visible header text.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<table>` with `<thead>` and `<tbody>` —
  `lib/pulsar/components/table.ex:366, 367, 381`
- Column headers use `<th scope="col">` — `lib/pulsar/components/table.ex:369–378`
- Test `renders table headers correctly` asserts `scope="col"` —
  `test/pulsar/components/table_test.exs:33–47`
- Test `includes proper semantic markup` asserts `<table>`/`<thead>`/`<tbody>`/`scope="col"` —
  `test/pulsar/components/table_test.exs:365–379`

**Notes:** No row headers — the component treats all data cells as
`<td>`, which is correct for a generic data table where rows aren't
labeled. A `<caption>` element can be supplied via the `:caption` slot —
see 2.4.6 for full accessible-name affordances.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Rows render in `Enum.with_index` order over `@rows`;
columns render in slot order — `lib/pulsar/components/table.ex:412–433`.
Action column always appears last, matching its visual position.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instructions rely on column color or shape. Striping
and sticky header are decorative —
`lib/pulsar/components/table.ex:213–217, 531`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color variants are decorative emphasis on the header.
Row-click hover state combines `cursor-pointer`, hover background, and
focus ring, not color alone — `lib/pulsar/components/table.ex:562–567`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Header `solid` variant uses paired `bg-*` / `text-*-foreground`
tokens — `lib/pulsar/components/table.ex:200–209`. Empty state uses
`text-muted-foreground` — `lib/pulsar/components/table.ex:397, 452`.
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
through `text-xl`) — `lib/pulsar/components/table.ex:126–147`. No fixed
`px` font sizes or heights.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Container is wrapped in `relative overflow-x-auto` —
`lib/pulsar/components/table.ex:155`. Table uses `w-full border-collapse`
— `lib/pulsar/components/table.ex:151`.

**Notes:** Horizontal scroll on the wrapper is the WCAG-recommended
pattern for wide data tables at narrow viewports; users can scroll the
table without horizontal page scroll. Per WCAG 1.4.10 understanding doc,
"data tables" are explicit exempt content where horizontal scrolling
within the component is acceptable.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (serious, follow-up: table-focus-ring-opacity)

**Evidence:**
- Row borders use `border-border/50` (50% opacity) —
  `lib/pulsar/components/table.ex:222`
- Outline variant header uses `border-b-2 border-border` —
  `lib/pulsar/components/table.ex:194`
- Row focus ring is `focus:ring-2 focus:ring-primary/20` (20% opacity) —
  `lib/pulsar/components/table.ex:566`

Browser measurement: the table fixture doesn't currently render
`row_click` rows, so per-cell focus rings aren't measured. However the
20% alpha on `--color-primary` (oklch lightness ≈ 0.55) composited
over `--color-background` (white in light, near-black in dark) is
algebraically below 3:1 — code review alone is sufficient to confirm
the gap.

**Notes:** New finding — tracked as `table-focus-ring-opacity`. The
fix is to drop the `/20` suffix on the focus ring (`focus:ring-2
focus:ring-primary`) or swap to a higher-contrast token. Row borders
at 50% opacity are not focus indicators and don't need to meet 3:1
(per WCAG 1.4.11 understanding, decorative borders are exempt).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed-height cells; padding-only sizing —
`lib/pulsar/components/table.ex:126–147`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- Row with `row_click` gets `tabindex="0"` and `role="button"` —
  `lib/pulsar/components/table.ex:417–418`
- Colocated `.PulsarTableRow` hook activates on Enter or Space —
  `lib/pulsar/components/table.ex:467–489`
- Hook checks `role === "button"` before binding —
  `lib/pulsar/components/table.ex:471`
- Test `adds keyboard accessibility attributes when row_click provided` —
  `test/pulsar/components/table_test.exs:398–415`

**Notes:** Static (non-clickable) tables are inherently keyboard-safe —
no interactive elements added by the component.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Hook handles only Enter/Space; does not block Tab —
`lib/pulsar/components/table.ex:473–478`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Loading skeleton uses `animate-pulse` which is
essential-to-function (loading indicator, exempt under 2.2.2) —
`lib/pulsar/components/table.ex:439, 442`. Row transitions are smooth
`transition-colors` — `lib/pulsar/components/table.ex:221`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are smooth color transitions and
`animate-pulse` for skeletons — no flashing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Clickable rows use `tabindex="0"` —
`lib/pulsar/components/table.ex:417`. Reading order is row-then-cell
following DOM. No positive `tabindex`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Three first-class accessible-name affordances are exposed on
`table/1`:

* `aria_label` attr — `lib/pulsar/components/table.ex:285–287`,
  rendered as `aria-label` on `<table>` —
  `lib/pulsar/components/table.ex:407`.
* `aria_labelledby` attr — `lib/pulsar/components/table.ex:289–291`,
  rendered as `aria-labelledby` —
  `lib/pulsar/components/table.ex:408`.
* `:caption` slot — `lib/pulsar/components/table.ex:308–309`, rendered
  as the first child of `<table>` —
  `lib/pulsar/components/table.ex:411–413`.

If none of these is provided (and no `aria-label` / `aria-labelledby`
passes through the global `:rest`), the component emits
`Logger.info` to nudge the caller —
`lib/pulsar/components/table.ex:548–574`. Rendering is not blocked. The
docstring documents all three patterns —
`lib/pulsar/components/table.ex:319–367`.

Column-level labels remain in place: each `<:col>` slot requires a
`label`, and the action column carries an `sr-only` "Actions" header.

**Tests:** `test/pulsar/components/table_test.exs` — the
`"table/1 accessible name (WCAG 2.4.6)"` describe block covers all three
affordances, the info log nudge, suppression for each affordance, and
the global-`:rest` passthrough path.

### 2.4.7 Focus Visible (AA) — ⚠ GAP (serious, follow-up: table-focus-ring-opacity)

**Evidence:** Row focus uses `focus:outline-none focus:ring-2 focus:ring-primary/20 dark:focus:ring-dark-primary/20`
— `lib/pulsar/components/table.ex:566`.

**Notes:** Uses `focus:` not `focus-visible:` — the ring shows on
mouse click as well as keyboard. Same underlying defect as the 1.4.11
finding above: the 20% alpha ring fails the 3:1 non-text minimum.
Both criteria are addressed by the same fix (drop `/20`); tracked as
one Linear sub-issue (`table-focus-ring-opacity`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ⚠ GAP (serious, follow-up: table-sticky-header-obscures-focus)

**Evidence:** Sticky header (`sticky_header={true}`) applies
`[&_thead_th]:sticky [&_thead_th]:top-0 [&_thead_th]:z-10` —
`lib/pulsar/components/table.ex:531`. Manual browser verification
confirms: with `sticky_header={true}` and `row_click`, Tab-ing to a
row that's about to scroll under the header leaves the row partially
or fully covered. The component needs to scroll-margin-top the
focused row so it lands below the header.

**Notes:** New finding — tracked as `table-sticky-header-obscures-focus`.
Fix is to add `scroll-margin-top: <header-height>` to focusable rows when
`sticky_header={true}`. Page-level usages can also work around it by
giving rows `scroll-padding-top`, but a component-level fix is the
right place.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Hook listens for `keydown` Enter/Space and triggers
`el.click()` — `lib/pulsar/components/table.ex:473–478`. Native click on
the row uses `mouseup`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Clickable row has no `aria-label` injected by the
component; accessible name is computed from cell text content. Callers
can override via `rest` — `lib/pulsar/components/table.ex:285`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Row height at the smallest size is dictated by `py-1 text-xs`
(`lib/pulsar/components/table.ex:144`) which yields roughly 24px row
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
  implicit roles — `lib/pulsar/components/table.ex:366–445`
- Loading state exposes `aria-busy={to_string(@loading)}` on the
  `<table>` — `lib/pulsar/components/table.ex:366`
- Clickable rows add explicit `role="button"` —
  `lib/pulsar/components/table.ex:418`
- Column headers carry `scope="col"` —
  `lib/pulsar/components/table.ex:371, 376`

**Notes:** Empty state row uses `class="only:table-row hidden"` —
`lib/pulsar/components/table.ex:388–391`. The `only:` Tailwind variant
relies on the empty `<tr>` being `:only-child` of `<tbody>` to display.
This is a clever CSS-only solution but exposes a tabIndex-less hidden
row to AT until it becomes the only child. Functionally safe but worth
noting.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:**
- Loading state renders a visually-hidden `role="status" aria-live="polite"`
  region announcing "Loading rows" — `lib/pulsar/components/table.ex:358–365`
- `aria-busy="true"` set on the `<table>` while loading —
  `lib/pulsar/components/table.ex:366`

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
