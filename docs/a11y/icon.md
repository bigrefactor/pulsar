# Icon · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/icon.ex`](../../lib/pulsar/components/icon.ex)
**Tests:** [`test/pulsar/components/icon_test.exs`](../../test/pulsar/components/icon_test.exs)
**Audited:** 2026-05-24 (code-only)

Non-interactive Heroicon renderer — `<span>` with CSS-based icon
backgrounds across outline/solid/mini/micro variants, semantic color
tokens, and ARIA semantics that toggle between decorative (default) and
informative (`aria_label` set) modes.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Decorative default: `aria-hidden="true"` and no `role` —
  `lib/pulsar/components/icon.ex:209–214`
- Informative mode: setting `aria_label` switches to `role="img"` with
  `aria-label` and drops `aria-hidden` —
  `lib/pulsar/components/icon.ex:202–206`
- Override escape hatch: `aria_hidden` attr lets callers force visible/
  hidden — `lib/pulsar/components/icon.ex:194–199`
- Tests: decorative default at
  `test/pulsar/components/icon_test.exs:136–143`; informative mode at
  `test/pulsar/components/icon_test.exs:145–152`; override at
  `test/pulsar/components/icon_test.exs:165–171`

**Notes:** Both halves of the WCAG requirement are covered — decorative
icons are hidden from AT, meaningful icons get a programmatic name. API
documents the contract — `lib/pulsar/components/icon.ex:46–60`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Renders a single `<span>` with `role="img"` only when a
label exists — `lib/pulsar/components/icon.ex:140, 199, 206, 213`.
Decorative spans carry no role, matching the WAI-ARIA practice for
purely presentational graphics.

**Notes:** CSS-background rendering means the icon glyph itself is not
in the DOM; the wrapper's role/label is the only relationship surface,
which is correct for a single-icon element.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Single self-closing `<span />` element —
`lib/pulsar/components/icon.ex:140`. No reordering possible.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Icon can be paired with text via the caller (and via
`aria_label` for the screen-reader signal) —
`lib/pulsar/components/icon.ex:112–114, 202–206`. The component itself
doesn't require color-only interpretation; the `aria_label` API allows a
text equivalent for any state communicated by color.

**Notes:** Caller is responsible for pairing icons with text labels in
context (e.g., a warning icon + visible "Warning" text); the component
supports that pattern.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** `aria_label` attribute is the documented escape hatch for
meaning that would otherwise be conveyed only by color/glyph —
`lib/pulsar/components/icon.ex:30, 56, 112–114`. Decorative-by-default
behavior implies the meaning must already exist elsewhere in the DOM.

**Notes:** Color tokens (`text-danger`, `text-success`, etc.) are
visual only; AT meaning travels through `aria_label` or sibling text.

### 1.4.3 Contrast (Minimum) (AA) — N/A

**Notes:** 1.4.3 governs text contrast; icons fall under 1.4.11. Listed
here for traceability — see 1.4.11.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Size classes are Tailwind `rem`-based
(`w-3 h-3` … `w-8 h-8`) — `lib/pulsar/components/icon.ex:73–79`.

**Notes:** Icon scales with root font size when users zoom.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Fixed but small inline dimensions (12–32px) with no
`min-width` or `min-height` constraints on surrounding layout —
`lib/pulsar/components/icon.ex:73–79`.

**Notes:** Inline icon does not force horizontal scrolling at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (minor) — color-dependent

**Evidence:** Icon glyph color is driven by semantic color tokens
(`text-danger`/`text-success`/etc., with dark-mode pairs) —
`lib/pulsar/components/icon.ex:82–91`. When `aria_label` is set the
icon is meaningful and needs 3:1 against its background. Browser
measurement of 108 cells: many cells report `unparseable-color` or
`1.0:1` for the icon fill because the SVG renders text inside a
parent-foreground-colored `<svg>` and the script's text-contrast
walk evaluates the SVG content rather than the glyph stroke. Per-
color glyph contrast against page background derives from the same
token contrasts used by text (4.5:1 for primary, secondary, danger,
neutral, info; success ~3.08:1 light, warning ~3.06:1 light).

**Notes:** The text-meaning success/warning glyphs share the same
token shortfall as button/badge/link text and are tracked by the same
upstream color-token follow-ups. Decorative icons (`aria-hidden="true"`)
are exempt from 1.4.11. No new sub-issue needed — the upstream color
token fix resolves icon contrast in parallel with text contrast.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No text inside the icon; no fixed line-height or
letter-spacing values — `lib/pulsar/components/icon.ex:73–79`.

**Notes:** Icon is a square box; user text-spacing overrides have no
effect on it.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Non-focusable single inline span —
`lib/pulsar/components/icon.ex:140`. Doesn't create sticky/overlapping
content.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Meaningful icons get `role="img"` and `aria-label` —
  `lib/pulsar/components/icon.ex:202–206`
- Decorative icons get `aria-hidden="true"` and no role —
  `lib/pulsar/components/icon.ex:209–214`
- Override path preserves user intent —
  `lib/pulsar/components/icon.ex:194–199`
- Tests verify all three branches —
  `test/pulsar/components/icon_test.exs:136–171`

**Notes:** Icon has no state, so role + name are the complete contract.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — CSS-rendered glyph, not raster text.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or popover.
- **2.1.1 Keyboard (A)** — non-interactive.
- **2.1.2 No Keyboard Trap (A)** — non-interactive.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no animation or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — static glyph, no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — non-focusable.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — not a heading or form label.
- **2.4.7 Focus Visible (AA)** — non-focusable.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.2 Pointer Cancellation (A)** — no click handler.
- **2.5.3 Label in Name (A)** — no visible label text to conflict with.
- **2.5.4 Motion Actuation (A)** — no motion input.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **2.5.8 Target Size (Minimum) (AA, new in 2.2)** — non-interactive (caller wraps icon-only buttons in Button component, which carries its own target-size obligations).
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.1 On Focus (A)** — non-focusable.
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
- **4.1.3 Status Messages (AA)** — static icon; status semantics belong to the surrounding container (e.g., flash with `role="alert"`).

## AAA wins (bonus)

- Decorative-by-default API minimizes screen-reader noise — every icon
  is silent unless the developer explicitly opts in via `aria_label`,
  satisfying the spirit of WCAG 2.4.6 / general AAA guidance on
  reducing irrelevant content.
