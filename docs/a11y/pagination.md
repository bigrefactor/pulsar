# Pagination · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/pagination.ex`](../../lib/pulsar/components/pagination.ex)
**Tests:** [`test/pulsar/components/pagination_test.exs`](../../test/pulsar/components/pagination_test.exs)
**Audited:** 2026-06-05 (code + browser axe gate)

A `<nav aria-label="Pagination">` landmark wrapping a `<ul>` of page links.
In page mode it renders previous/next controls, a windowed run of page-number
links (with `…` ellipses for gaps), and an optional summary; the current page
carries `aria-current="page"`. In cursor mode it renders only previous/next.
Disabled boundary controls render as `<span aria-disabled="true">` rather than
links, keeping them out of the tab order. Navigation uses native Phoenix
`<.link>`s, so the component is fully keyboard-operable with no custom JS. The
current page is emphasized per `variant` (ghost tint, solid fill, outline ring)
paired with a semantic `color`; inactive controls use `text-muted-foreground`,
and every control has a `focus-visible` ring.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The only non-text content is the prev/next chevron icons, which are
decorative (`aria-hidden` via the Icon component's default) and accompanied by the
visible `previous_label` / `next_label` text — `lib/pulsar/components/pagination.ex:244, 278`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** `<nav>` landmark with `aria-label`; the controls are a `<ul>`/`<li>`
list; the current page is marked with `aria-current="page"` —
`lib/pulsar/components/pagination.ex:233, 260`. Tests `renders a nav landmark…` and
`current page carries aria-current=page` — `test/pulsar/components/pagination_test.exs:13, 37`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Items render in the order produced by `page_items/4` (prev, pages
left-to-right, next), matching visual order — `lib/pulsar/components/pagination.ex:317`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** The current page is not signaled by color alone — it carries
`aria-current="page"` and, per variant, a fill (solid), tinted background (ghost),
or border ring (outline) — `lib/pulsar/components/pagination.ex:260, 400`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Active pages pair a semantic fill with its readable foreground
(`bg-{color} text-{color}-foreground`) or `text-{color}` on the background;
inactive controls use `text-muted-foreground` (measured 6.0–7.23:1 on all
surfaces) — `lib/pulsar/components/pagination.ex:400–408`. The axe gate scans the
`/components/pagination` fixture in light and dark with no violations.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Sizes use rem-based Tailwind text utilities (`text-xs`–`text-lg`)
and rem padding — `lib/pulsar/components/pagination.ex:91`. `whitespace-nowrap`
applies only to short numeric labels.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The list is `flex flex-row flex-wrap`, so controls wrap rather than
force horizontal scrolling at narrow widths — `lib/pulsar/components/pagination.ex:103`.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The outline variant's active border routes through
`border-border-strong` (≥3:1); the focus ring uses `ring-ring` (the `--color-ring`
token, 5.02:1 light / 6.72:1 dark) — `lib/pulsar/components/pagination.ex:72, 101`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** All controls are native `<.link>`s reachable and activatable by
keyboard (Tab + Enter); disabled boundaries are non-focusable spans —
`lib/pulsar/components/pagination.ex:236, 247`.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Links are in normal flow with no focus management or key interception —
`lib/pulsar/components/pagination.ex:236`.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** Each page link has `aria-label="{go_to_label_prefix} {n}"`; prev/next
carry visible label text — `lib/pulsar/components/pagination.ex:261, 245`. Test
`previous_label / next_label / go_to_label_prefix override…` —
`test/pulsar/components/pagination_test.exs:254`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** Every control applies `focus-visible:ring-2 focus-visible:ring-ring
focus-visible:ring-offset-2` — `lib/pulsar/components/pagination.ex:101`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Linear in-flow render; no sticky/overlapping content covers a focused
control — `lib/pulsar/components/pagination.ex:233`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native link activation fires on click (mouseup), not pointer-down —
`lib/pulsar/components/pagination.ex:236`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Page link visible text is its number; its `aria-label` contains that
number (`Go to page 3` over visible `3`) — `lib/pulsar/components/pagination.ex:261`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The smallest control is `min-w-7 h-7` (28 CSS px), above the 24×24
minimum, with `gap` separation between items — `lib/pulsar/components/pagination.ex:92, 103`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Native `<nav>`/`<a>` roles; nav named via `aria-label`; current page
exposes `aria-current="page"`; disabled controls expose `aria-disabled="true"` —
`lib/pulsar/components/pagination.ex:233, 260, 247`.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** When `show_summary` is set, the summary is an `aria-live="polite"`
region so page changes are announced — `lib/pulsar/components/pagination.ex:287`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.3 Sensory Characteristics (A)** — instructions don't rely on shape/position.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — labels are text; icons are inline SVG.
- **1.4.12 Text Spacing (AA)** — no fixed text heights or `!important` spacing.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered content.
- **2.1.4 Character Key Shortcuts (A)** — no key shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — links follow DOM order; no managed focus.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — labels are caller-supplied and rendered faithfully.
- **2.5.1 Pointer Gestures (A)** — no path/multipoint gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no dragging.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — focusing a link doesn't change context.
- **3.2.2 On Input (A)** — no form inputs; activation is explicit navigation.
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

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  thickness minimum and `--color-ring` clears AAA contrast (5.02:1 / 6.72:1) —
  `lib/pulsar/components/pagination.ex:101`.

## Browser a11y findings

None. The axe gate is clean across the `/components/pagination` fixture cells in
light and dark themes.
