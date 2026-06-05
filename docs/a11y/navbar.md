# Navbar · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/navbar.ex`](../../lib/pulsar/components/navbar.ex)
**Tests:** [`test/pulsar/components/navbar_test.exs`](../../test/pulsar/components/navbar_test.exs)
**Audited:** 2026-06-01 (code-only + browser measurement)

Top app-bar for app-shell navigation. Renders a `<header>` banner with `left`,
`center`, and `right` regions the caller composes (brand, search, navigation,
notifications, a user menu). When `on_menu_toggle` is set it also renders a
labeled menu `<button>` that runs the supplied JS — typically a sidebar toggle.
The navbar owns the surface, height, sticky positioning, and alignment; what
goes in each region is caller-supplied.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content the navbar renders itself is the menu
button's hamburger glyph, which is decorative (`Icon` defaults to
`aria-hidden="true"`) while the button carries a text alternative via
`aria-label` — `lib/pulsar/components/navbar.ex:243, 247`. Region content is
caller-supplied.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Root is a `<header>` banner landmark with an optional accessible name —
  `lib/pulsar/components/navbar.ex:236`
- The left / center / right regions render as distinct flex groups in DOM order
  — `:237–260`
- Tests assert the banner and the three regions render — `test/pulsar/components/navbar_test.exs:37–52`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Regions render left → center → right in DOM order, matching the
visual row (`flex`, no `flex-row-reverse`) — `lib/pulsar/components/navbar.ex:236–260`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on shape/position/color; the menu button is
identified by its label, not "the button on the left" — `lib/pulsar/components/navbar.ex:243`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color encodes visual emphasis only. The menu button pairs an icon
with a text `aria-label`, so its purpose is not color-borne —
`lib/pulsar/components/navbar.ex:243, 247`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Each variant/color pairs a semantic background with its matching
`-foreground` (solid) or `text-foreground` on a surface (outline/ghost/elevated)
— `lib/pulsar/components/navbar.ex:86–123`. Region text inherits the bar
foreground. Browser measurement of all 34 fixture cells per theme: every cell
passes, min text contrast 5.89:1 (light, `solid-secondary`) / 7.06:1 (dark,
`solid-secondary`) ([light](measurements/navbar-light.md),
[dark](measurements/navbar-dark.md)). The axe gate is clean in both themes.

**Notes:** Caller-supplied region content that overrides the inherited color is
the caller's responsibility.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** No fixed `px` font sizes; height, padding, and gap use `rem`-based
Tailwind utilities — `lib/pulsar/components/navbar.ex:60–66`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The bar is `w-full` with no enforced minimum width; the left and
right regions are `shrink-0` and the center is `min-w-0` so it absorbs the
remaining space — `lib/pulsar/components/navbar.ex:237, 254, 258`. A standalone
bar reflows to 320 CSS px.

**Notes:** The measurement run flags overflow at 320px because the fixture tiles
many full-width bars in one flex-wrap row under the CSS-only constraint (each
bar squeezed to ~32px) — a fixture-tiling artifact, not the component enforcing
width. Caller content placed in a region is the caller's responsibility to keep
responsive.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS (decorative borders are out of scope)

**Evidence:**
- The neutral bottom border routes through `border-border-strong` (≥3:1) in both
  `solid` and `outline` — `lib/pulsar/components/navbar.ex:88, 97`
- Colored `outline` borders use the saturated brand/status color — `:98–103`
- The menu button's focus ring uses `ring-ring` — `:79`

Browser measurement of the bordered cells: all pass — `outline-neutral` /
`solid-neutral` / sizes 4.63:1 (light) via `border-border-strong`; colored
borders 5.05–8.67:1 (light) / 6.22–10.3:1 (dark)
([light](measurements/navbar-light.md), [dark](measurements/navbar-dark.md)).
The `--color-ring` token measures 5.02:1 (light) / 6.72:1 (dark) per the
project ring audit.

**Notes:** For colored `solid` bars the filled background provides the boundary
and the same-hue border is decorative reinforcement; `ghost` has no boundary by
design and `elevated` delineates with `shadow-dropdown` —
`lib/pulsar/components/navbar.ex:105–122`. Per WCAG 1.4.11 understanding,
decorative container outlines are out of scope; the one neutral case where the
border *is* the boundary uses `border-border-strong`.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** The bar holds short single-line controls, not running text, and
applies no `!important` spacing overrides. The text-spacing override run reports
no overflowing cells ([light](measurements/navbar-light.md),
[dark](measurements/navbar-dark.md)).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The menu button is a native `<button>` whose action is the
caller's `%JS{}` composed into `phx-click` — keyboard-operable by default (no
custom key handling) — `lib/pulsar/components/navbar.ex:238–248`. Region content
is caller-supplied interactive markup.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The navbar adds no focus management, modal, or focus trap; focus
moves through it in normal tab order — `lib/pulsar/components/navbar.ex:236–261`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only transition is `transition-colors` on the menu button
hover, which is finite — `lib/pulsar/components/navbar.ex:78`. Reduced motion is
honored globally by the theme's single `@media (prefers-reduced-motion: reduce)`
rule. No looping or auto-updating content.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; only a color transition on hover —
`lib/pulsar/components/navbar.ex:78`.

### 2.4.1 Bypass Blocks (A) — ✓ PASS

**Evidence:** The bar is a `<header>` banner landmark (optionally named), so
assistive tech can jump to or past it via landmark navigation —
`lib/pulsar/components/navbar.ex:236`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`; the menu button (when present) precedes the
left/center/right content in DOM order, matching the visual order —
`lib/pulsar/components/navbar.ex:237–260`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** The banner takes an optional descriptive `aria-label`, and the menu
button has an overridable `aria-label` — `lib/pulsar/components/navbar.ex:236, 243`.
Tests assert both — `test/pulsar/components/navbar_test.exs:108–118, 228–238`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The menu button applies `focus-visible:ring-2 focus-visible:ring-ring
focus-visible:ring-offset-2` — `lib/pulsar/components/navbar.ex:79`. Caller
controls keep their own focus rings; `focus-visible:outline-none` is scoped to
the bar root, which is not in the tab sequence — `:72`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** When `sticky` is set, sibling and descendant focusable content gets
`scroll-mt-*` sized to the bar height, so a keyboard-scrolled element is pushed
clear of the sticky band rather than obscured by it —
`lib/pulsar/components/navbar.ex:135–141, 282, 286`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The menu button activates on `click` (pointer-up), cancellable by
moving off-target before release — `lib/pulsar/components/navbar.ex:242`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The menu button is `size-9` (36×36 CSS px), above the 24×24
minimum — `lib/pulsar/components/navbar.ex:77`. Other targets are caller-supplied.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the bar or the menu button triggers no context change;
the menu action runs on click, not focus — `lib/pulsar/components/navbar.ex:242`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- `<header>` banner role, optionally named — `lib/pulsar/components/navbar.ex:236`
- The menu button is a native `<button>` with an `aria-label` and an optional
  `aria-controls` pointing at the element it drives — `:238–244`
- Tests assert the button's name, `aria-controls`, and that it renders only when
  `on_menu_toggle` is set — `test/pulsar/components/navbar_test.exs:66–119`

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
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered content.
- **2.1.4 Character Key Shortcuts (A)** — no single-character shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — the navbar renders no links of its own.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.3 Label in Name (A)** — the menu button is icon-only, named via `aria-label`, with no visible text label.
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
- **4.1.3 Status Messages (AA)** — the navbar emits no status messages.

## Browser a11y findings

None. The axe gate is clean across all fixture cells in light and dark themes.
