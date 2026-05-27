# List · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/list.ex`](../../lib/pulsar/components/list.ex)
**Tests:** [`test/pulsar/components/list_test.exs`](../../test/pulsar/components/list_test.exs)
**Audited:** 2026-05-24 (code-only)

Key/value data list using definition-list semantics. Renders a `<dl>`
with `<dt>` / `<dd>` pairs for each item slot. Supports optional title
+ description header, custom empty state, striping, and dividers.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Component renders no non-text content of its own; icons
or images in slot content are caller-supplied.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Populated path uses `<dl>` only when items are present —
  `lib/pulsar/components/list.ex:343, 376`
- Each item renders `<dt>` (label) and `<dd>` (value) —
  `lib/pulsar/components/list.ex:356–361, 389–394`
- Empty-state path renders a plain `<div data-list-empty>` in place of
  `<dl>` — no `<dl>`/`<dt>`/`<dd>` semantics are emitted when there are
  no items — `lib/pulsar/components/list.ex:363–370, 404–415`
- Tests assert the populated path produces `<dl>`/`<dt>`/`<dd>` and the
  empty path does not —
  `test/pulsar/components/list_test.exs:31–47, 430–488, 605–622`

**Notes:** Item DOM in the populated path is `<dl> > <div> > <dt> + <dd>`.
Strict HTML5 allows `<dl>` to contain `<div>` wrappers only when the
wrapping is around one or more `<dt>` + `<dd>` groups, which is what the
component does. The empty-state path previously rendered a plain `<div>`
("No items to display") as a direct child of `<dl>`, which is invalid
HTML5; this is resolved by dropping `<dl>` entirely when empty.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Items render in `Enum.with_index` order over the slot list
— `lib/pulsar/components/list.ex:345, 377`. `<dt>` precedes `<dd>` in
each item — `lib/pulsar/components/list.ex:357–362`.

**Notes:** Responsive layout uses `sm:grid sm:grid-cols-3` — does not
reorder DOM, only visually re-columns at wider viewports.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No directional or shape-based instructions. Striping and
dividers are decorative emphasis only —
`lib/pulsar/components/list.ex:455–472`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color variants are decorative; structure is conveyed via
`<dt>` / `<dd>` semantics —
`lib/pulsar/components/list.ex:152–250`.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious)

**Evidence:** Text uses semantic tokens like `text-foreground`,
`text-primary`, `text-muted-foreground` —
`lib/pulsar/components/list.ex:152–250, 484–501`. Description text in
header uses `text-muted-foreground dark:text-dark-muted-foreground` —
`lib/pulsar/components/list.ex:574`. Browser measurement of 57 cells
per theme: all pass at the fixture level (min 7.56:1 light / 7.74:1
dark) ([light](measurements/list-light.md),
[dark](measurements/list-dark.md)).

**Notes:** A separate follow-up tracks axe-detected color-contrast
on the `success dt on tinted bg` combo (light) and `dark text on
dark bg` (dark) — neither variant is exercised by the fixture, so
direct measurement doesn't surface them. The known gaps remain
valid.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All text sizing uses `rem`-based Tailwind classes —
`lib/pulsar/components/list.ex:99–130, 548–572`. No fixed `px` sizes.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Item layout collapses to a single column below the `sm`
breakpoint (`flex` falls through with no grid) and uses
`sm:grid sm:grid-cols-3 sm:gap-4` only at wider widths —
`lib/pulsar/components/list.ex:451`. No fixed minimum width.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS (decorative borders are out of scope)

**Evidence:** Item dividers use `border-t border-border` —
`lib/pulsar/components/list.ex:352, 383`. Outline variant border-1 on
the wrapper — `lib/pulsar/components/list.ex:144, 513`. Outline-neutral
and solid-neutral both route through `border-border-strong` —
`lib/pulsar/components/list.ex:144, 230`. Solid (non-neutral) variants
use 20% opacity borders next to tinted fills —
`lib/pulsar/components/list.ex:222–248`. Browser measurement: 38
border cells per theme. Outline variants pass; `solid-neutral` passes
(~5:1 via `--color-border-strong`). Remaining failing cells are
`solid-*` (non-neutral) variants (≈1.5:1) where the colored 20%-alpha
border resolves below 3:1 — classified as decorative (see Notes).

**Notes:** Same disposition as Card. The colored `solid-*` variants
pair a tinted fill (`bg-X/5` to `bg-X/10`) with a slightly darker
decorative border — the fill alone provides clear visual
delineation against the page background; the border is
reinforcement decoration. Per WCAG 1.4.11 understanding, decorative
section separators / container outlines that don't communicate
state are out of scope.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights on text containers. Padding via `py-*`
and `px-*` only — `lib/pulsar/components/list.ex:99–130`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No animation.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Native `<dl>` / `<dt>` / `<dd>` carry their implicit
roles. Header `<h3>` renders only when a `:title` slot is supplied —
`lib/pulsar/components/list.ex:335–337`. Description renders as `<p>` —
`lib/pulsar/components/list.ex:338–340`.

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
- **2.1.1 Keyboard (A)** — non-interactive.
- **2.1.2 No Keyboard Trap (A)** — non-interactive.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no moving content.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — non-interactive.
- **2.4.4 Link Purpose (In Context) (A)** — no links in component itself.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — list header `<h3>` text is caller-provided; component renders it verbatim.
- **2.4.7 Focus Visible (AA)** — non-interactive.
- **2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — non-interactive.
- **2.5.1 Pointer Gestures (A)** — non-interactive.
- **2.5.2 Pointer Cancellation (A)** — non-interactive.
- **2.5.3 Label in Name (A)** — non-interactive.
- **2.5.4 Motion Actuation (A)** — non-interactive.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — non-interactive.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — non-interactive.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — non-interactive.
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
- **4.1.3 Status Messages (AA)** — no status content emitted.

## AAA wins (bonus)

- Definition-list semantics (`<dl>`/`<dt>`/`<dd>`) for key/value data
  exceed what most data-list components ship — many comparable libraries
  use plain `<div>` rows.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `color-contrast` | light: success dt on tinted bg; dark: dark text on dark bg (~1:1) | both |
