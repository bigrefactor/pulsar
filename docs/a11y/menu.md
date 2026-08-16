# Menu · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/menu.ex`](../../lib/pulsar/components/menu.ex)
**Tests:** [`test/pulsar/components/menu_test.exs`](../../test/pulsar/components/menu_test.exs)
**Audited:** 2026-06-03 (code-only)

Orientation-aware navigation menu. Renders a `<nav>` landmark (or a bare list
when `landmark={false}`) around a list of links composed from `menu_item`,
`menu_section`, and `menu_group`. The active item carries `aria-current="page"`.
Groups use the APG disclosure pattern (`aria-expanded` + `aria-controls`),
rendering as an in-place disclosure when vertical and a dropdown when
horizontal. The horizontal dropdown is the [Popover](popover.md) primitive: the
anchored positioning, Escape/outside-click dismissal, focus-return, and sibling
auto-close are the Popover's, audited there. Per APG, primary navigation uses
links + disclosure — **not** the `menubar`/`menu` roles.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Leading icons and the disclosure chevron are decorative — `Icon`
defaults to `aria-hidden="true"` — while every row's name comes from its text
label — `menu_item/1`, `menu_group/1`. In the collapsed sidebar icon rail the
label is hidden with `sr-only` (not `display:none`), so an icon-only row keeps
its accessible name — `label_classes/0`. The supplementary `trailing`
affordance (e.g. a count) is `display:none` in that rail: it is hidden from
sighted users there too, so omitting it from the accessibility tree keeps the
two experiences at parity — the row's name still comes from the `sr-only` label,
and the count returns for everyone when the rail expands.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Root is a `<nav>` landmark wrapping a `<ul role="list">`; items are `<li>` —
  `menu_landmark/1`, `menu/1`, `menu_item/1`
- A section is a labelled grouping list (`<ul aria-labelledby>` pointing at the
  section heading) — `menu_section/1`
- A group exposes the disclosure relationship: the trigger's `aria-controls`
  points at its panel `id` — vertical `menu_group/1`; horizontal `menu_group/1`
  (the panel is the Popover)
- Tests assert the landmark, list, section labelling, and group wiring —
  `test/pulsar/components/menu_test.exs`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Items render in DOM order; orientation flips the visual axis with
`flex-row`/`flex-col`, never reordering source — `list_base/1`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** The active item is conveyed by `aria-current="page"` plus a filled
treatment and (typically) an icon, not by color or position alone —
`menu_item/1`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** The current page is marked programmatically with `aria-current`
(not color alone); the expanded/collapsed state is exposed via `aria-expanded`
and a rotating chevron — `menu_item/1`, `menu_group/1`, `chevron_classes/0`,
`chevron_horizontal_classes/0`. A group carrying `active` is styled with
`font-medium` (a non-color cue) in addition to the fill; this trigger
treatment is intentionally redundant — the
authoritative current-page signal is the child item's `aria-current`, so no
programmatic state is conveyed by color alone.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Rows inherit the host surface's foreground (`text-inherit`), so they
read correctly on a neutral panel or a colored sidebar/navbar; the active row
pairs `bg-primary` with `text-primary-foreground`; section labels use
`text-muted-foreground` — `lib/pulsar/components/menu.ex` (`@row_base`, `@row_active`,
`@section_label_classes`). All are semantic token pairs that meet AA in light and
dark. The axe gate scans the `/components/menu` fixture (vertical, horizontal, and
collapsed icon rail) in both themes.

**Notes:** Caller-supplied trailing content is the caller's responsibility.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** No fixed `px` font sizes; `text-sm`/`text-xs` and `rem`-based
padding throughout — `menu_item/1`, `menu_group/1`, `section_label_classes/0`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** A vertical menu is a flex column with no enforced width; a
horizontal menu is a flex row — `list_base/1`. The horizontal dropdown is the
Popover primitive, which is `min-w-48` and flips/shifts to stay on screen
rather than enforcing a viewport minimum — `menu_group/1`, see the
[Popover audit](popover.md).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:**
- Every interactive row has a `focus-visible:ring-2 ring-ring` indicator —
  `menu_item/1`, `menu_group/1`
- The horizontal dropdown delineates against the page with the Popover's
  `elevated` surface (`shadow-dropdown`) plus a `border-border` outline the menu
  adds — `menu_group/1`, see the [Popover audit](popover.md)
- The active row's `bg-primary` fill provides its own boundary — `menu_item/1`

The `--color-ring` token measures 5.02:1 (light) / 6.72:1 (dark) per the project
ring audit. Verified clean by the axe gate.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Rows hold short single-line labels with no `!important` spacing
overrides; labels truncate rather than clip layout — `label_classes/0`.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** The horizontal group's dropdown opens on **click/Enter** (not
hover) via the trigger's `popovertarget`, is dismissable via Escape and
click-outside, and is persistent until dismissed — the Popover primitive supplies
this behavior — `menu_group/1`, see the
[Popover audit](popover.md). The vertical disclosure likewise toggles on
click/Enter, never on hover — `menu/1`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Items are native `<a>`/`<button>` elements; group triggers are
native `<button>`s — vertical toggles on Enter/Space through the hook, horizontal
toggles via the native `popovertarget`, which the trigger carries in the server's
markup so a patch cannot strip it — `menu_item/1`, `menu_group/1`.
Arrow keys add roving focus (Up/Down vertical, Left/Right horizontal) and
Home/End — `menu/1`. A keyboard fixture exercises ArrowDown, Enter-to-expand,
and Escape — `test/integration/a11y/keyboard/menu_test.exs`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Arrow keys move focus among items but Tab/Shift+Tab still leave the
menu normally; nothing holds focus. The horizontal dropdown closes on Escape and
returns focus to its trigger via the native popover — see the
[Popover audit](popover.md). Closing a vertical disclosure that holds focus
returns focus to its trigger — `menu/1`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Transitions are finite — the vertical disclosure height and the
chevron rotation — and collapse under the global
`@media (prefers-reduced-motion: reduce)` rule via `motion-reduce:transition-none`
— `chevron_classes/0`, `chevron_horizontal_classes/0`,
`disclosure_wrapper_classes/0`. The horizontal dropdown is shown and hidden by
the native popover, not by animation.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; only finite open/close and hover transitions —
`chevron_classes/0`, `disclosure_wrapper_classes/0`.

### 2.4.1 Bypass Blocks (A) — ✓ PASS

**Evidence:** The menu is a `<nav>` landmark (overridable `label`), reachable and
skippable via landmark navigation — `menu_landmark/1`. When
`landmark={false}` (nested in a sidebar's own `<nav>`), the host provides the
landmark.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`; DOM order matches visual order. Collapsed
vertical group children are `invisible`, and a closed horizontal dropdown is
`display:none` via the native popover, keeping both out of the tab sequence until
opened — `disclosure_list_classes/0`.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** Each item requires label content (`inner_block`, required), so link
text is always present — `menu_item/1` (`slot :inner_block`).

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** The landmark takes a descriptive `label`; sections take a heading
label; groups take a trigger `label` — `menu/1` (`attr :label`),
`menu_section/1` (`attr :label`), `menu_group/1` (`attr :label`).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Every row and trigger applies `focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-offset-2` — `menu_item/1`, `menu_group/1`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The menu creates no sticky/overlapping chrome of its own. The
horizontal dropdown is positioned by the Popover primitive, which anchors it
beside the trigger (default below) and flips/shifts to stay on screen rather than
covering the trigger — `menu_group/1`, see the
[Popover audit](popover.md).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Triggers and links activate on `click` (pointer-up), cancellable by
moving off-target; the horizontal trigger uses the native `popovertarget` button,
also pointer-up — `menu/1`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Rows are named by their visible text, with no conflicting
`aria-label` — `menu_item/1`, `menu_group/1`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Rows and triggers are `px-3 py-2` on `text-sm` (≈ 36 px tall),
above the 24×24 minimum — `menu_item/1`, `menu_group/1`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing a row or trigger causes no context change; groups toggle
on activation, links navigate on activation — `menu/1`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Items are native links/buttons; the active item exposes `aria-current="page"`
  — `menu_item/1`
- Vertical group triggers are `<button>` with `aria-expanded` reflecting state
  and `aria-controls` naming the panel; the hook keeps `aria-expanded` in sync on
  toggle — `menu_group/1`, hook `menu/1`
- Horizontal group triggers carry server-rendered `aria-expanded` and
  `aria-controls`; the Popover keeps `aria-expanded` in sync as the dropdown
  opens and closes — `menu_group/1`, see the [Popover audit](popover.md)
- Tests assert the disclosure attributes and active state —
  `test/pulsar/components/menu_test.exs`

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — works in both orientations; no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **2.1.4 Character Key Shortcuts (A)** — no single-character shortcuts (only Arrow/Home/End/Escape, and only while focused within the menu).
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
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
- **4.1.3 Status Messages (AA)** — the menu emits no status messages.

## Browser a11y findings

None. The axe gate is clean across the `/components/menu` fixture cells in light
and dark themes.
