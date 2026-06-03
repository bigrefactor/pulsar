# DropdownMenu · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/dropdown_menu.ex`](../../lib/pulsar/components/dropdown_menu.ex)
**Tests:** [`test/pulsar/components/dropdown_menu_test.exs`](../../test/pulsar/components/dropdown_menu_test.exs)
**Audited:** 2026-06-03 (code-only)

Anchored action menu opened from a trigger button — the APG menu-button pattern.
Built on the popover primitive in click mode: the `.PulsarPopover` hook anchors a
native `popover="auto"` panel carrying `role="menu"` to the trigger, and handles
open/close, outside-click + Escape dismissal, and focus return. The
`.PulsarDropdownMenu` colocated hook layers the menu keyboard model on top —
roving focus across `tabindex="-1"` items, type-ahead, Enter/Space activation,
and submenu navigation. Items are action buttons or navigation links
(`role="menuitem"`), with checkbox/radio items (`role="menuitemcheckbox"` /
`role="menuitemradio"` with `aria-checked`), labelled groups (`role="group"`),
separators (`role="separator"`), and submenus (a `menuitem` with
`aria-haspopup="menu"` owning a nested `role="menu"`).

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The leading icons, the checkbox check, the radio dot, and the
submenu chevron are decorative. Icons render through `Icon.icon` with no
`aria_label`, so they are `aria-hidden`; the radio dot is a bare `<span>` —
`lib/pulsar/components/dropdown_menu.ex:491`, `:552–553`, `:620–621`. Each item's
meaning is carried by its text label.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The structure is fully programmatic: the panel is `role="menu"`
(`:198`); items are `role="menuitem"` (`:480`, `:499`),
`role="menuitemcheckbox"` with `aria-checked` (`:543–546`), or
`role="menuitemradio"` with `aria-checked` (`:611–614`); groups are `role="group"`
with `aria-labelledby` to their heading (`:668–669`); separators are
`role="separator"` (`:688`). The trigger exposes `aria-haspopup="menu"` and (via
the popover hook) `aria-expanded` (`:216`, `lib/pulsar/components/popover.ex:366–367`).
Unit tests assert each role/state — `test/pulsar/components/dropdown_menu_test.exs`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order matches the visual top-to-bottom item order; the menu does
not reorder content with CSS.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction relies on shape, size, or position; items are
identified by their text labels.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** State is never color-only. A checked checkbox/radio shows a check
glyph / filled dot, not just a tint — `lib/pulsar/components/dropdown_menu.ex:552–553`,
`:620–621`. An item set to `color="danger"` pairs its danger color with the action's
text label (and typically an icon) — `:813–814`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Item text and headings use `text-foreground`
(`lib/pulsar/components/dropdown_menu.ex:95`, `:110`); items set to `color="danger"`
use `text-danger`, the same token Button uses for danger text (`:813`); the surface is
the popover's `bg-surface-1` (`lib/pulsar/components/popover.ex:133–141`). All clear
4.5:1 in both themes. The trailing shortcut hint is supplementary
(`text-muted-foreground`, `:102`). The axe gate scans the `/components/dropdown_menu`
fixture in light and dark.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Item text is `text-sm` (a `rem`-based size); rows size to content and
wrap rather than clipping — `lib/pulsar/components/dropdown_menu.ex:95`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The menu renders in the browser top layer and the popover hook shifts
it into the viewport with an 8px margin on both axes, so it never forces horizontal
scrolling at 320px — `lib/pulsar/components/popover.ex:426–431` (`position`).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The roving focus indicator is `focus-visible:ring-2
focus-visible:ring-ring` (`lib/pulsar/components/dropdown_menu.ex:97`); the
`--color-ring` token measures ≥5:1, above the 3:1 minimum. Separators are
decorative dividers, not UI controls.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No `!important` spacing and no fixed text heights; rows use padding
and inherit line-height, so user spacing overrides reflow without clipping —
`lib/pulsar/components/dropdown_menu.ex:95`.

### 1.4.13 Content on Hover or Focus (AA) — ✓ PASS

**Evidence:** A submenu can open on hover, and satisfies all three requirements:
it is **dismissable** (Escape closes the submenu via the native nested popover),
**hoverable** (the nested `popover="auto"` panel stays open while the pointer is
over it), and **persistent** (it stays until dismissed or focus/pointer leaves) —
`lib/pulsar/components/dropdown_menu.ex:386–392` (hover-intent open), the nested
`Popover.popover` at `:741–773`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The menu is fully operable from the keyboard: Enter/Space/ArrowDown
on the trigger open it and focus the first item, ArrowUp focuses the last
(`:251–265`); ArrowUp/ArrowDown rove, Home/End jump to the edges, and printable
keys type-ahead (`:278–324`); Enter/Space activate the focused item (`:362–371`);
ArrowRight/ArrowLeft open and close submenus (`:300–309`). The keyboard fixture
exercises these — `test/integration/a11y/keyboard_test.exs`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The menu is non-modal; Escape closes it and returns focus to the
trigger (native popover), and Tab is never trapped — focus leaves the menu
normally. `lib/pulsar/components/popover.ex:240–254`.

### 2.1.4 Character Key Shortcuts (A) — ✓ PASS

**Evidence:** The only single-character keys are type-ahead, which is active *only*
while the open menu holds focus — it meets the "active only on focus of a component"
exception and registers no global shortcut — `lib/pulsar/components/dropdown_menu.ex:418–427`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Items carry `tabindex="-1"` and are reached by roving focus, so only
the trigger is in the page tab order (`:482`, `:501`, `:545`, `:613`, `:761`); a
closed menu is `display:none` (native `[popover]`), keeping its items out of the
tab order. No positive `tabindex` is used.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** Item links require `inner_block` content and derive their purpose
from that visible text; the component renders no "click here" markup and adds no
contradicting accessible name — `lib/pulsar/components/dropdown_menu.ex:471–514`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** The menu has an accessible name — the `label` attr becomes
`aria-label`, or the hook labels it by the trigger (`:244–248`); groups name
themselves via `aria-labelledby` to their heading (`:668–669`); non-interactive
section headings render through `dropdown_menu_label` (`:110`).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The focused item shows a background highlight plus a
`focus-visible:ring-2 focus-visible:ring-ring` ring; the caller's trigger keeps its
own ring — `lib/pulsar/components/dropdown_menu.ex:95–97`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The menu renders in the browser top layer (native popover), so it is
never clipped by `overflow:hidden` ancestors, and the hook flips it to the opposite
side when the requested side lacks room — `lib/pulsar/components/popover.ex:401–411`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Items are native `<button>`/`<a>` activated on `click` (fires on
pointer-up), and the menu opens via the trigger's `click` — no action fires on
pointer-down — `lib/pulsar/components/dropdown_menu.ex:478`, `:496`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Each item's accessible name is its visible text content; the component
adds no contradicting `aria-label`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Item rows are `px-2 py-1.5 text-sm`, giving a target height ≥24 CSS px
— `lib/pulsar/components/dropdown_menu.ex:95`. The trigger is caller-supplied (e.g.
Pulsar `Button`, which meets 24×24).

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Moving roving focus between items changes no context — it neither
navigates nor submits. The menu opens only on explicit activation (click / Enter /
Space / Arrow), not on focus — `lib/pulsar/components/dropdown_menu.ex:251–265`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** The trigger is a menu button (`aria-haspopup="menu"` +
`aria-expanded`); the panel is `role="menu"`; items expose their roles and
`aria-checked`/`aria-disabled` state — `lib/pulsar/components/dropdown_menu.ex:198`,
`:216`, `:543–546`, `:611–614`. Unit tests assert the roles and states —
`test/pulsar/components/dropdown_menu_test.exs`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input collecting personal data.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no text images; icons are inline SVG.
- **2.2.1 Timing Adjustable (A)** — no content time limit (the type-ahead reset and submenu hover delay are sub-second affordances, not content timeouts).
- **2.2.2 Pause, Stop, Hide (A)** — the only motion is a sub-second entrance fade on open (`animate-fade-in`), below the 5s threshold and near-zeroed by the global reduced-motion rule.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing; the entrance is a single opacity fade.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.2 On Input (A)** — not a form input; toggling checkbox/radio items emits caller events, it does not change context.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.3 Status Messages (AA)** — the menu is not a status message and uses no live region.

## Browser a11y findings

None. The axe gate is clean across the `/components/dropdown_menu` fixture cells in
light and dark themes.
