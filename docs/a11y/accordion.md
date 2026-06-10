# Accordion · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/accordion.ex`](../../lib/pulsar/components/accordion.ex)
**Tests:** [`test/pulsar/components/accordion_test.exs`](../../test/pulsar/components/accordion_test.exs)
**Audited:** 2026-06-10 (code + browser axe gate)

Accordion is a set of headers, each toggling a collapsible region — the WAI-ARIA
Accordion pattern. Each `:item` renders a heading (`h2`–`h6`, configurable via
`heading_level`) wrapping a `<button>`; the button controls a sibling
`role="region"` panel. `type="single"` keeps at most one section open (set
`collapsible={false}` to keep one always open); `type="multiple"` lets sections
open independently. A colocated LiveView hook toggles `data-expanded` on the item
(driving the `grid-template-rows: 0fr → 1fr` height animation) and keeps
`aria-expanded` on the button in sync, and provides Up/Down/Home/End roving
between headers. The component stays in document flow and does not trap focus.

## WAI-ARIA Accordion pattern mapping

| APG requirement | Implementation |
| --- | --- |
| Each accordion header is a `<button>`. | `lib/pulsar/components/accordion.ex:233–246` |
| The button is wrapped in a heading element (`h2`–`h6`) fitting the document outline. | `heading_level` attr (`:173–177`); `<.dynamic_tag>` (`:232`) |
| The button carries `aria-expanded` reflecting the panel's state. | `:238` (markup), hook `applyState` (`:304–308`) |
| The button carries `aria-controls` pointing at its panel. | `:237` |
| Each panel is a region (`role="region"`) labelled by its header. | `:249` (`role="region"` + `aria-labelledby`) |
| Up/Down move between headers; Home/End jump to first/last (optional). | hook `onKeydown` (`:291–301`) |
| A disabled section is not toggleable and is skipped by keyboard nav. | `disabled` + `aria-disabled` (`:239–240`); `enabledHeaders` filter (`:280–282`) |

## Applicable criteria

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Header text rests at `text-muted-foreground` (gray-600,
≈6.0–7.23:1 on the container surfaces — clears AA for normal text in both
themes) and darkens to `text-foreground` on hover and when its section is open
(`group-data-[expanded]/item:text-{color}`). Panel body text inherits the
surrounding `foreground`. The browser axe gate measures the settled colors of
every header and the open panel across light + dark and reports clean.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:124`
(`@header_base` — `text-muted-foreground … hover:text-foreground`),
`lib/pulsar/components/accordion.ex:71–79` (`@header_open` open-state tint map),
`lib/pulsar/components/accordion.ex:399–402` (`header_classes/2` composing them).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Two non-text affordances clear the 3:1 floor. The focus ring is
`ring-2` drawn from the `--color-ring` token (verified to clear 3:1 on every
surface). The chevron indicator inherits the header's text color — at rest
`muted-foreground` (≈6:1, well over 3:1) and `foreground`/the open tint when
expanded — and rotates 180° to encode open/closed, so the state is conveyed by
orientation and `aria-expanded`, not by contrast alone.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:124`
(`focus-visible:ring-2 focus-visible:ring-ring` in `@header_base`),
`lib/pulsar/components/accordion.ex:126` (`@chevron_base` —
`group-data-[expanded]/item:rotate-180`), `lib/pulsar/components/accordion.ex:245`
(chevron icon, color inherited from the header button).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Each header is a native `<button>` in the tab order — Tab reaches
it and Enter/Space toggles its section natively (the hook's `click` listener
fires on the synthetic click that Enter/Space dispatches on a button). With a
header focused, Up/Down move to the previous/next enabled header (wrapping),
Home/End jump to the first/last; disabled headers are excluded from the roving
set. All interactions have a keyboard path — there is no pointer-only affordance.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:233–234`
(`<button type="button">`), `lib/pulsar/components/accordion.ex:285–290`
(`onClick` — toggles on click, which Enter/Space synthesize on a button),
`lib/pulsar/components/accordion.ex:291–301` (`onKeydown` — ArrowDown/ArrowUp at
:297–298, Home/End at :299–300), `lib/pulsar/components/accordion.ex:280–282`
(`enabledHeaders` — disabled headers skipped). Tests `headers are buttons with
aria-expanded, default closed` and `disabled item is a disabled button with
aria-disabled and never open` — `test/pulsar/components/accordion_test.exs`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Each header is a native `<button>` rendered in slot order, so Tab
visits the headers in document order with no positive `tabindex` reordering. The
hook's roving navigation moves focus among headers with Up/Down/Home/End but
never alters the natural Tab sequence.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:233–246`
(header `<button>` rendered in slot order, no positive tabindex),
`lib/pulsar/components/accordion.ex:291–301` (`onKeydown` roving — moves focus
without rewriting tab order).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Each header button shows a `focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-inset` indicator and
`focus-visible:outline-none` to suppress the doubled UA outline.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:124`
(`@header_base` — `focus-visible:outline-none focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-inset`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The accordion renders linearly in document flow and creates no
sticky, fixed, or overlapping content that could cover a focused header or its
panel — the markup is a plain `<div>` of heading/button/region rows.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:216–253`
(in-flow container → item → header/region render tree; no sticky/overlay layer).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Toggling is driven by a `click` listener (fires on mouseup, after
the up-event so a pointer-down can be cancelled by dragging off), not by
`pointerdown`/`mousedown`.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:268`
(`addEventListener("click", …)`), `lib/pulsar/components/accordion.ex:285–290`
(`onClick` — resolves the header and toggles on click).

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Each header button's accessible name is its visible `title` text;
there is no `aria-label` on the button to contradict the visible label, and the
leading icon and chevron are decorative.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:244`
(`<span>{item.title}</span>` — visible text is the accessible name),
`lib/pulsar/components/accordion.ex:233–246` (button has no overriding
`aria-label`).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Header padding starts at `px-3 py-2` on `text-xs` (xs) and grows
through the size scale, keeping every header's clickable box at or above 24×24
CSS px; headers are full-width rows with no overlapping adjacent targets.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:87–93`
(`@size_header` padding scale — `px-3 py-2` floor at xs up to `px-6 py-5` at xl),
`lib/pulsar/components/accordion.ex:233–246` (full-width header button).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**

- **Role/name** — each header is a `<button>` whose accessible name is its
  `title` text (plus an optional leading icon, which is decorative). Each panel
  is `role="region"` named by `aria-labelledby` pointing at its header id.
- **Value** — `aria-expanded` is `"true"`/`"false"` in the server markup and is
  kept in sync by the hook's `applyState` on every toggle, including silent
  sibling closes in `single` mode, and re-asserted across LiveView re-renders via
  `restore()` in `updated()`.
- **State** — disabled sections carry both `disabled` and `aria-disabled="true"`.

**Evidence line numbers:** `lib/pulsar/components/accordion.ex:233–246` (button:
`aria-controls` at :237, `aria-expanded` at :238, `aria-disabled` at :239,
`disabled` at :240, `title` span at :244), `lib/pulsar/components/accordion.ex:249`
(`role="region"` + `id` + `aria-labelledby`),
`lib/pulsar/components/accordion.ex:304–308` (`applyState` — `aria-expanded`
sync), `lib/pulsar/components/accordion.ex:326–332` (`restore` — re-asserts open
set after a LiveView patch), `lib/pulsar/components/accordion.ex:257–258`
(`mounted`/`updated` both call `restore`). Tests `wires
aria-controls/aria-labelledby between header and region` and `exposes type +
collapsible config to the hook` — `test/pulsar/components/accordion_test.exs`.

## Landmark caveat

`role="region"` is an ARIA landmark, so each open panel becomes a landmark in the
accessibility tree. Per APG guidance, mark up regions as landmarks **only** when
the count stays small enough that the landmark list remains useful — roughly six
or fewer per page. The shipped examples and the a11y fixtures keep each accordion
to three sections (and ≤6 per page) so the `landmark-unique` axe rule passes;
authors rendering many long accordions on one page should keep each section
`title` distinct (so the regions get unique accessible names) and stay within the
landmark budget.

## Not applicable

- **1.1.1 Non-text Content (A)** — the leading icon and the chevron are
  decorative alongside the header button's text name; no informational image.
- **1.2.x Time-based Media** — no media.
- **1.3.1 Info and Relationships (A)** — covered by the heading/button/region
  structure under 4.1.2.
- **1.3.2 Meaningful Sequence (A)** — sections render in slot order; no visual
  reordering.
- **1.3.3 Sensory Characteristics (A)** — open state is exposed via
  `aria-expanded`, not by shape or position alone.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — the open state is encoded by the chevron rotation
  and `aria-expanded`, not by the color tint alone.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — all sizing is relative (`text-*`/`rem`); no fixed
  pixel text.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.10 Reflow (AA)** — the container is fluid; callers cap width with a
  utility class (e.g. `max-w-lg`), imposing no fixed minimum.
- **1.4.12 Text Spacing (AA)** — no inline style overrides line-height or spacing.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered
  supplementary content; the header hover only shifts text color.
- **2.1.2 No Keyboard Trap (A)** — headers are ordinary tab stops; no Tab/Shift+Tab
  is intercepted.
- **2.1.4 Character Key Shortcuts (A)** — Arrow/Home/End are navigation keys, not
  single-character shortcuts.
- **2.2.x Timing / Pause** — only a sub-second open transition; no time limit or
  auto-updating content.
- **2.3.1 Three Flashes (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — headers are buttons, not links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the header `title` and `heading_level` are
  caller-supplied; the component renders them faithfully.
- **2.5.1 Pointer Gestures (A)** — no path or multipoint gestures; a single click
  toggles.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag (sections are not
  reorderable).
- **3.1.x Language** — page-level concern.
- **3.2.1 On Focus (A)** — focusing a header does not toggle it; only Enter/Space
  or click do.
- **3.2.2 On Input (A)** — toggling does not trigger navigation or submission.
- **3.2.3–3.2.6 (page-level)** — consistent-navigation/identification/help are
  page-level concerns.
- **3.3.x Forms** — not a form input.
- **4.1.3 Status Messages (AA)** — `aria-expanded` on the header communicates
  state in-place; no separate live region is needed.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  minimum thickness and the `--color-ring` token clears AAA contrast —
  `lib/pulsar/components/accordion.ex:124`.

## Browser a11y findings

None. The axe gate at `/components/accordion/{outline,solid,ghost,elevated}` —
each scanned in light + dark, with the "one open" fixture rendering an open
`role="region"` panel — is clean.
