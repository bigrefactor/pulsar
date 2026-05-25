# Divider · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/divider.ex`](../../lib/pulsar/components/divider.ex)
**Tests:** [`test/pulsar/components/divider_test.exs`](../../test/pulsar/components/divider_test.exs)
**Audited:** 2026-05-24 (code-only)

Visual separator between content sections — renders as `<hr>` for simple
horizontal dividers, or a `<div role="separator">` for vertical and
labeled variants. Supports optional inline label content.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Decorative line segments in labeled dividers are marked
`aria-hidden="true"` — `lib/pulsar/components/divider.ex:325, 329`. Test
`labeled divider has proper structure` —
`test/pulsar/components/divider_test.exs:195–202`.

**Notes:** The visual lines flanking a label are presentational; hiding
them prevents redundant AT noise while preserving the semantic separator
role on the container.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Simple horizontal divider uses native `<hr>` —
  `lib/pulsar/components/divider.ex:293`
- Vertical divider applies `role="separator"` with
  `aria-orientation="vertical"` — `lib/pulsar/components/divider.ex:301`
- Labeled divider applies `role="separator"` and conditional
  `aria-orientation` — `lib/pulsar/components/divider.ex:319–323`
- Tests assert `role="separator"` and `<hr>` —
  `test/pulsar/components/divider_test.exs:14, 183`

**Notes:** Semantic separator role is preserved across every render
path. `<hr>` has implicit `role="separator"` with horizontal orientation,
so the absence of an explicit role on the simple-horizontal branch is
correct.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Labeled divider renders line / label / line in DOM order
matching the visual flex layout —
`lib/pulsar/components/divider.ex:325–329`.

**Notes:** No reverse-direction flex. Vertical labeled divider uses
`flex-col` (`lib/pulsar/components/divider.ex:361`), again matching
visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Divider position/style is purely decorative — the
component conveys no instruction that depends on shape, color, or
position.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Color variants on dividers are decorative emphasis; they
do not communicate information that needs a non-color alternative —
`lib/pulsar/components/divider.ex:155–183`.

### 1.4.3 Contrast (Minimum) (AA) — N/A

**Notes:** Divider lines are non-text. Label text contrast falls under
1.4.11 and would require browser verification, but the label inherits
semantic color tokens (`text-foreground`, `text-primary`, etc.) —
`lib/pulsar/components/divider.ex:186–214`.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Label sizing uses Tailwind `text-*` classes (`text-xs`
through `text-xl`) that resolve to `rem` —
`lib/pulsar/components/divider.ex:95, 106, 117, 128, 139`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Horizontal divider is `w-full`; labeled container is
`flex items-center w-full` (`lib/pulsar/components/divider.ex:359`); no
fixed minimum width — `lib/pulsar/components/divider.ex:413–418`.

**Notes:** Vertical divider relies on caller-provided height
(documented at `lib/pulsar/components/divider.ex:34–35`). Component
itself doesn't force any minimum dimension that would break at 320 CSS
px.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Border colors come from semantic tokens with opacity
modifiers (e.g., `border-border/30`, `border-primary/60`) —
`lib/pulsar/components/divider.ex:155–183`.

**Notes:** The `ghost` variant at 30% opacity may struggle to meet 3:1
against the page background. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (follow-up browser audit).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Label uses `whitespace-nowrap` (`lib/pulsar/components/divider.ex:391`)
which is permitted under 1.4.12. No fixed height on the label container.

**Notes:** `whitespace-nowrap` constrains wrapping but does not violate
1.4.12, which addresses line-height/letter-spacing/word-spacing/paragraph
spacing overrides.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No animation on the divider.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- `<hr>` has implicit `role="separator"` —
  `lib/pulsar/components/divider.ex:293`
- Non-`<hr>` paths apply explicit `role="separator"` plus
  `aria-orientation` for vertical — `lib/pulsar/components/divider.ex:301, 319–323`
- Label content is exposed via the `<span>` text —
  `lib/pulsar/components/divider.ex:326–328`

**Notes:** Separators have no value/state to expose; name comes from
slot content where present.

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
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus content.
- **2.1.1 Keyboard (A)** — non-interactive.
- **2.1.2 No Keyboard Trap (A)** — non-interactive.
- **2.1.4 Character Key Shortcuts (A)** — no shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no moving content.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — non-interactive.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — label text is caller-provided.
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
- **4.1.3 Status Messages (AA)** — no status content.

## AAA wins (bonus)

- None notable. Divider is intentionally minimal; semantic separator
  role and decorative-line `aria-hidden` together cover the AA bar
  without overreach.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `color-contrast` | section label | dark | [PUL-30](https://linear.app/bigrefactor/issue/PUL-30/divider-fix-axe-color-contrast-violation) |
