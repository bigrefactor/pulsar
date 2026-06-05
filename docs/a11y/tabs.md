# Tabs · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/tabs.ex`](../../lib/pulsar/components/tabs.ex)
**Tests:** [`test/pulsar/components/tabs_test.exs`](../../test/pulsar/components/tabs_test.exs)
**Audited:** 2026-06-05 (code + browser axe gate)

A `role="tablist"` of `<button role="tab">` triggers, each paired with a matching
`role="tabpanel"`. The selected tab carries `aria-selected="true"`, roving
`tabindex="0"`, and its panel is shown; the rest are `aria-selected="false"`,
`tabindex="-1"`, and `hidden`. The colocated `.PulsarTabs` hook handles
Arrow/Home/End navigation with automatic activation (Left/Right for horizontal,
Up/Down for vertical), skips disabled tabs, and re-syncs `aria-selected`,
`tabindex`, and panel `hidden` on activation. Variants are ghost (underline),
solid (filled segmented), outline (bordered), and elevated (raised pill); each
active state pairs a semantic color with its readable `-foreground`, and inactive
tabs use `text-muted-foreground`. Both tabs and panels carry a `focus-visible`
ring.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content is an optional leading icon, which is
caller-supplied and decorative alongside the visible tab `label` —
`lib/pulsar/components/tabs.ex:238–239`. No icon-only tabs are produced by the
component (the `label` is required) — `lib/pulsar/components/tabs.ex:175`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Tablist container has `role="tablist"` —
  `lib/pulsar/components/tabs.ex:220`
- Each trigger has `role="tab"` and `aria-controls` pointing at its panel —
  `lib/pulsar/components/tabs.ex:229, 231`
- Each panel has `role="tabpanel"` and `aria-labelledby` pointing back at its
  tab — `lib/pulsar/components/tabs.ex:245, 247`
- Test `renders tablist, tabs and panels with roles` and
  `tabs reference their panels via aria-controls / aria-labelledby` —
  `test/pulsar/components/tabs_test.exs:20, 39`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Tabs and panels both render in slot order from the same prepared
list (`Enum.with_index`), so DOM order matches the authored order and the visual
order — `lib/pulsar/components/tabs.ex:227, 244, 342–345`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** The active tab is signaled programmatically via `aria-selected`,
not by shape/position alone — `lib/pulsar/components/tabs.ex:232`. Disabled tabs
combine `aria-disabled`, the native `disabled` attribute, and reduced opacity —
`lib/pulsar/components/tabs.ex:233, 235, 114`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Active state is not color-only: ghost/outline variants add a
border indicator (`border-b-2` / `border` with `border-border-strong`) and the
solid/elevated variants change the tab to a filled pill shape (plus `shadow-card`
on elevated) — `lib/pulsar/components/tabs.ex:409–413, 416–421`. The selected
tab is also exposed via `aria-selected="true"` independent of any color cue —
`lib/pulsar/components/tabs.ex:232`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Active tabs pair a semantic fill with its readable foreground
(`bg-{color} text-{color}-foreground`, the browser-verified Button palette), or
use `text-{color}` on the page background; inactive tabs use
`text-muted-foreground` (measured 6.0–7.23:1 on all surfaces) —
`lib/pulsar/components/tabs.ex:63–93, 416–422`. The axe gate scans the
`/components/tabs` fixture in light and dark with no violations.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Tab sizes use rem-based Tailwind text utilities (`text-xs`–
`text-lg`) and `rem`-based padding — `lib/pulsar/components/tabs.ex:104–110`.
Text scales with the user's font size; `whitespace-nowrap` applies only to the
short tab labels, not panel content.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The tablist is a `flex` row/column with no fixed width, and the
panel wrapper uses `min-w-0` in vertical orientation so panels shrink rather than
force horizontal scrolling — `lib/pulsar/components/tabs.ex:116–124, 386`. No
min-width floor is imposed on the container.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The active indicator borders route through `border-foreground` /
the semantic `border-{color}` (ghost) and `border-border-strong` (outline), all
meeting 3:1 — `lib/pulsar/components/tabs.ex:74–82, 416, 418`. The focus ring on
both tabs and panels uses `ring-ring` (the `--color-ring` token measured 5.02:1
light / 6.72:1 dark) — `lib/pulsar/components/tabs.ex:114, 126`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The `.PulsarTabs` hook handles Arrow (Left/Right horizontal,
Up/Down vertical), Home, and End with automatic activation, skipping disabled
tabs — `lib/pulsar/components/tabs.ex:287–313`. Native `<button>` triggers
activate on click/Enter/Space. The dedicated keyboard fixture exercises
roving focus and arrow/Home/End navigation —
`test/integration/a11y/keyboard_test.exs:201–245`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Arrow navigation moves focus among tabs without trapping; Tab from
the selected tab moves into its panel (`tabindex="0"` on the panel) and onward
out of the component — `lib/pulsar/components/tabs.ex:234, 248`. No custom
Tab/Shift+Tab handling is registered (the keydown handler only consumes
Arrow/Home/End) — `lib/pulsar/components/tabs.ex:287–309`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Roving tabindex: the active tab is `tabindex="0"` and the rest are
`tabindex="-1"`, so Tab lands once on the tablist; the hook keeps exactly one tab
at `0` on activation — `lib/pulsar/components/tabs.ex:234, 316–318`. No positive
tabindex is used. Test `first tab is selected and its panel visible; others
hidden` asserts the `0` / `-1` split —
`test/pulsar/components/tabs_test.exs:55`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Tabs apply `focus-visible:ring-2 focus-visible:ring-ring
focus-visible:ring-offset-2` and panels apply the same ring —
`lib/pulsar/components/tabs.ex:114, 126`. The `--color-ring` token measures
5.02:1 (light) / 6.72:1 (dark), above the 3:1 non-text minimum.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Linear in-flow render; the component creates no sticky or
overlapping content that could cover a focused tab or panel —
`lib/pulsar/components/tabs.ex:211–255`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Activation is driven by the tablist `click` listener (fires on
mouseup), not pointer-down — `lib/pulsar/components/tabs.ex:266, 281–286`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Each tab's accessible name is its visible `label` text (no
contradicting `aria-label` on the trigger) — `lib/pulsar/components/tabs.ex:239`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Tab padding starts at `px-2 py-1` on `text-xs` (xs) and grows from
there, keeping every tab's clickable box at or above 24×24 CSS px —
`lib/pulsar/components/tabs.ex:104–110, 114`. Tabs are separated by `gap` in the
tablist so adjacent targets don't overlap —
`lib/pulsar/components/tabs.ex:391–395`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing a tab does not change context; activation happens through
the hook's keydown/click handlers, and arrow-key activation only follows an
explicit keystroke (automatic-activation pattern), not bare focus —
`lib/pulsar/components/tabs.ex:287–313`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Activating a tab toggles panel visibility and runs the optional
`on_change` `%JS{}` callback the caller supplies; the component itself triggers no
navigation or form submission — `lib/pulsar/components/tabs.ex:314–329`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: `role="tablist"`, `role="tab"`, `role="tabpanel"` —
  `lib/pulsar/components/tabs.ex:220, 229, 245`
- Name: tab name from visible `label`; tablist labeled via `aria-label` /
  `aria-labelledby` — `lib/pulsar/components/tabs.ex:222–223, 239`
- State/Value: `aria-selected`, roving `tabindex`, `aria-controls`,
  `aria-orientation`, and `aria-disabled` + native `disabled` —
  `lib/pulsar/components/tabs.ex:221, 231–235`. The hook keeps `aria-selected`,
  `tabindex`, and panel `hidden` in sync on activation —
  `lib/pulsar/components/tabs.ex:315–323`.
- Test `tabs reference their panels via aria-controls / aria-labelledby` and
  `vertical orientation sets aria-orientation and data-orientation` —
  `test/pulsar/components/tabs_test.exs:39, 89`

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock; supports both horizontal and vertical.
- **1.3.5 Identify Input Purpose (AA)** — not a form input collecting user info.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — labels are text, optional icons are inline SVG.
- **1.4.12 Text Spacing (AA)** — no `!important` spacing or fixed text heights; labels inherit page spacing.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered supplementary content.
- **2.1.4 Character Key Shortcuts (A)** — only Arrow/Home/End navigation keys, no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — only a sub-second color transition on tab state; no auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — tabs are buttons, not links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — tab labels and the tablist `aria-label` are caller-supplied; the component renders them faithfully.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag (tabs are not reorderable).
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.
- **4.1.3 Status Messages (AA)** — tab activation isn't a status message; no live region.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  minimum thickness, and the `--color-ring` token clears AAA contrast (5.02:1 /
  6.72:1) — `lib/pulsar/components/tabs.ex:114, 126`.

## Browser a11y findings

None. The axe gate is clean across the `/components/tabs` fixture cells in light
and dark themes.
