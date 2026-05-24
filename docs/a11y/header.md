# Header · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/header.ex`](../../lib/pulsar/components/header.ex)
**Tests:** [`test/pulsar/components/header_test.exs`](../../test/pulsar/components/header_test.exs)
**Audited:** 2026-05-24 (code-only)

Page header section combining a title (caller-chosen heading level
`h1`–`h6`), optional subtitle, optional actions row, and optional
breadcrumb navigation. Wraps everything in a semantic `<header>`
landmark.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Breadcrumb chevron separators render with `aria-hidden="true"`
— `lib/pulsar/components/header.ex:275`. Test
`icons have proper accessibility attributes` —
`test/pulsar/components/header_test.exs:513–527`.

**Notes:** Decorative separators are correctly hidden; meaningful text
in breadcrumbs comes from slot content.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Wrapper renders semantic `<header>` landmark —
  `lib/pulsar/components/header.ex:264`
- Title uses `Phoenix.Component.dynamic_tag` with the caller's chosen
  heading level (`h1` default, configurable `h1`–`h6`) —
  `lib/pulsar/components/header.ex:208–211, 326–328`
- Breadcrumbs use `<nav aria-label="Breadcrumb">` wrapping an `<ol>` of
  `<li>` items — `lib/pulsar/components/header.ex:265–321`
- Current page is marked `aria-current="page"` —
  `lib/pulsar/components/header.ex:279`
- Tests assert `<header>`, `<h1>`, `<nav>`, `<ol>`, `aria-label="Breadcrumb"`,
  `aria-current="page"` — `test/pulsar/components/header_test.exs:481–528`

**Notes:** Structure follows the WAI-ARIA breadcrumb pattern. The
`as` attribute uses `values: ~w(h1 h2 h3 h4 h5 h6)`
(`lib/pulsar/components/header.ex:210`) so the heading is always a real
heading element, never a styled `<div>`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order is breadcrumb → title → subtitle → actions →
divider — `lib/pulsar/components/header.ex:264–342`. Layout uses
`sm:flex-row sm:justify-between` rather than visual reordering.

**Notes:** On desktop, actions visually appear right-aligned but remain
after the title in DOM, which matches the typical reading order
expectation.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instructions in the component rely on shape/color/
position. Variants use a mix of border, background, and text color
(`lib/pulsar/components/header.ex:157–187`); current breadcrumb is
identified by both `aria-current="page"` and `font-medium` —
`lib/pulsar/components/header.ex:278–281`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Current-page breadcrumb is distinguished by font weight
and `aria-current` in addition to color —
`lib/pulsar/components/header.ex:278–281`. Variants are decorative
emphasis only.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Subtitle uses `text-neutral-600 dark:text-dark-neutral-400`
across all sizes — `lib/pulsar/components/header.ex:130, 134, 138, 142, 146`.
Breadcrumb text uses `text-neutral-500 dark:text-dark-neutral-400` —
`lib/pulsar/components/header.ex:266, 316`. Solid variants pair `*-100`
backgrounds with `*-900` foregrounds —
`lib/pulsar/components/header.ex:178–186`.

**Notes:** Token pairings look plausible against typical backgrounds
but ratios need DevTools confirmation. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All title and subtitle sizes use `rem`-based Tailwind
`text-*` classes — `lib/pulsar/components/header.ex:128–149`. No fixed
`px` heights on heading elements.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:**
- Content row uses `flex flex-col sm:flex-row sm:items-start sm:justify-between` —
  `lib/pulsar/components/header.ex:324`
- Breadcrumb `<ol>` uses `flex-wrap` —
  `lib/pulsar/components/header.ex:266`
- Title block uses `flex-1 min-w-0` to prevent text overflow —
  `lib/pulsar/components/header.ex:325`
- Test `has responsive flex classes for mobile/desktop` —
  `test/pulsar/components/header_test.exs:428–447`

**Notes:** Layout collapses to a stacked column at narrow viewports;
breadcrumb chips wrap rather than overflow.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Outline variant bottom border uses `border-*-200`
(`lib/pulsar/components/header.ex:168–175`); divider hr uses
`border-neutral-200` — `lib/pulsar/components/header.ex:341`.

**Notes:** 200-shade borders need browser check for 3:1 against the
page background. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Header uses `flex flex-col gap-4` —
`lib/pulsar/components/header.ex:153`. Subtitle uses `mt-1` and inherits
line-height — `lib/pulsar/components/header.ex:329`. No fixed heights on
text containers.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Header itself is non-interactive. Breadcrumb links delegate
to `Pulsar.Components.Link.a/1` —
`lib/pulsar/components/header.ex:284–310` — which uses native `<a>` and
inherits keyboard activation. Action buttons in the `actions` slot are
caller-supplied.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No JS hooks on the header element. Breadcrumb links and
caller-supplied actions use native focus management.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** No animation. Sticky positioning is static —
`lib/pulsar/components/header.ex:366`.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No animation.

### 2.4.1 Bypass Blocks (A) — ✓ PASS (partial credit, page-level)

**Evidence:** Header is rendered as a `<header>` landmark, which AT
landmark navigation can skip to/from — `lib/pulsar/components/header.ex:264`.

**Notes:** Strictly a page-level criterion, but the landmark contributes
positively rather than obstructing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** DOM order matches visual order; breadcrumb → title →
actions — `lib/pulsar/components/header.ex:264–339`. No positive
`tabindex` set anywhere.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** Breadcrumb links use the slot's inner_block text as the
link text — `lib/pulsar/components/header.ex:284–310`. Combined with the
parent `<nav aria-label="Breadcrumb">` landmark, link purpose is clear.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:**
- `as` attribute restricted to `h1`–`h6` — `lib/pulsar/components/header.ex:210`,
  so the header always renders a real heading element
- Title slot is `required: true` — `lib/pulsar/components/header.ex:231–233`
- Subtitle is rendered as a `<div>` (not a heading) so it doesn't
  pollute the heading outline — `lib/pulsar/components/header.ex:329–331`
- Test `renders with custom heading level` —
  `test/pulsar/components/header_test.exs:395–408`

**Notes:** The component preserves the level the caller chose. Hierarchy
across multiple headers is a page-level concern.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** No interactive elements rendered by the component itself
besides breadcrumb links, which inherit the Link component's focus
styling.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Sticky header uses `sticky top-0 z-10 bg-background dark:bg-dark-background`
— `lib/pulsar/components/header.ex:366`.

**Notes:** A sticky header sitting at `z-10` can obscure focused
controls scrolled behind it. The component itself can't fully prevent
this without knowing the page layout, but `scroll-margin-top` on focus
targets is a typical mitigation. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No `phx-focus` or focus-triggered behavior in component
template.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- `<header>` landmark with implicit role — `lib/pulsar/components/header.ex:264`
- `<nav aria-label="Breadcrumb">` for the breadcrumb landmark —
  `lib/pulsar/components/header.ex:265`
- `<ol>` / `<li>` for the breadcrumb list —
  `lib/pulsar/components/header.ex:266–267`
- Current breadcrumb has `aria-current="page"` —
  `lib/pulsar/components/header.ex:279`
- Chevron icons have `aria-hidden="true"` —
  `lib/pulsar/components/header.ex:275`

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
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — non-interactive container.
- **2.5.2 Pointer Cancellation (A)** — non-interactive container.
- **2.5.3 Label in Name (A)** — non-interactive container.
- **2.5.4 Motion Actuation (A)** — non-interactive container.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — non-interactive container.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — non-interactive container; breadcrumb link target sizing is inherited from the Link component.
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
- **4.1.3 Status Messages (AA)** — no status content.

## AAA wins (bonus)

- **2.4.10 Section Headings (AAA)** — component is purpose-built around
  a required heading + optional subtitle, encouraging proper sectioning
  at call sites.
- **2.4.1 Bypass Blocks (A)** — landmark-quality semantic `<header>` and
  `<nav>` improve skip-by-landmark behavior beyond what 2.4.1 strictly
  requires.
