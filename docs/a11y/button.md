# Button · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/button.ex`](../../lib/pulsar/components/button.ex)
**Tests:** [`test/pulsar/components/button_test.exs`](../../test/pulsar/components/button_test.exs)
**Audited:** 2026-05-24 (code-only)

Polymorphic interactive button — renders as `<button>`, `<a>`, or `<div>`
with variants, sizes, loading, disabled, pressed, and disclosure states.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Loading spinner `aria-hidden="true"` — `lib/pulsar/components/button.ex:572`
- `aria_label` attr supported for icon-only buttons —
  `lib/pulsar/components/button.ex:314–317`
- Test `supports aria-label for icon-only buttons` —
  `test/pulsar/components/button_test.exs:366–376`

**Notes:** Decorative SVG spinner is correctly hidden from AT. Callers
are expected to provide either visible text in `inner_block` or
`aria_label` for icon-only buttons; the API supports both patterns.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<button>` element preserves semantic role —
  `lib/pulsar/components/button.ex:392–415`
- Pseudo-button (`as: :a`, `as: :div`) explicitly applies
  `role="button"` — `lib/pulsar/components/button.ex:436, 463`
- Test `renders role="button" when rendered as a non-button element` —
  `test/pulsar/components/button_test.exs:378–396`

**Notes:** State (busy/disabled/pressed/expanded) is exposed via ARIA
attributes; relationships (controlled regions) via `aria-controls`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Content rendered in DOM order — optional `loading_content`
slot replaces inner_block, never reorders relative to siblings —
`lib/pulsar/components/button.ex:565–590`.

**Notes:** No `flex-direction: row-reverse` or absolute-positioned
content. Spinner appears before content during loading, which matches
visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:**
- Loading state combines spinner + opacity + `cursor-wait` —
  `lib/pulsar/components/button.ex:118, 570–585`
- Disabled state combines opacity + `cursor-not-allowed` + native
  `disabled` attr — `lib/pulsar/components/button.ex:117, 396`

**Notes:** State changes are not color-only; spinner motion and cursor
changes provide non-visual cues alongside color.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Disabled and loading states use opacity + cursor changes +
ARIA state (`aria-disabled`, `aria-busy`), not color alone —
`lib/pulsar/components/button.ex:117–119, 400`.

**Notes:** Color variants (primary/success/danger/etc.) convey *which*
button it is but criticality is communicated via inner text, not color.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Colors come from semantic tokens
(`text-*-foreground`, `bg-*`, dark-mode pairs) —
`lib/pulsar/components/button.ex:145–205`. Theme defaults match
Tailwind palettes that meet 4.5:1 at typical token pairings, but
ratios for each of the 7 colors × 4 variants × 2 themes (56
combinations) require DevTools measurement.

**Notes:** Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Tailwind text classes (`text-xs`, `text-sm`, `text-lg`,
`text-xl`) use `rem`; heights are also `rem`-based. No fixed `px` font
sizes — `lib/pulsar/components/button.ex:88–110`.

**Notes:** Fixed `h-*` values constrain vertical space, but values
(h-6=1.5rem, h-10=2.5rem, h-14=3.5rem) all scale with root font size.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` layout, no `min-width`, no fixed widths —
`lib/pulsar/components/button.ex:125, 133, 138`.

**Notes:** Button width is content-driven; reflows at 320 CSS px without
horizontal scroll.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Focus ring is `ring-2 ring-ring` (and `ring-dark-ring` in
dark mode) — `lib/pulsar/components/button.ex:115–116`. Outline variant
uses `border-2` in the active color — `lib/pulsar/components/button.ex:174–187`.

**Notes:** Focus ring and outline borders need 3:1 against adjacent
background; the semantic-token approach is sound but ratios require
DevTools. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 1.4.12 Text Spacing (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Fixed button heights (`h-6` through `h-14`) —
`lib/pulsar/components/button.ex:89–110`.

**Notes:** WCAG 1.4.12 requires content to adapt when line-height is
overridden to 1.5×. Default line-height on Tailwind text-* classes
already exceeds 1.5×, so the fixed heights have small headroom. Needs
runtime check — tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:**
- Native `<button>` is keyboard-operable.
- Pseudo-button JS hook handles `keydown` Space/Enter and `keyup`
  Space to trigger `click()` — `lib/pulsar/components/button.ex:633–642`
- Hook respects `aria-disabled` / `aria-busy` to short-circuit
  activation — `lib/pulsar/components/button.ex:607–610, 634`

**Notes:** Activation pattern matches WAI-ARIA APG button pattern.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No `keydown` handler prevents Tab. Hook only handles
Space/Enter — `lib/pulsar/components/button.ex:633–642`.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:**
- Hover/active scale animations gated by `motion-reduce` —
  `lib/pulsar/components/button.ex:127, 135, 140`
- Loading spinner uses `animate-spin` which is essential-to-function
  (exempt per WCAG 2.2.2 essential clause).

**Notes:** Respects user motion preferences for non-essential motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are smooth `animate-spin` and transform
scales. No flashing — `lib/pulsar/components/button.ex:114, 127, 135, 140, 583`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Server-side `tabindex/1` is authoritative: emits `"0"` when
focusable, `"-1"` when disabled or loading —
`lib/pulsar/components/button.ex:tabindex/1`. The pseudo-button hook
only handles Space/Enter activation and blocks clicks while
disabled/busy — it no longer caches or rewrites tabindex.

**Notes:** Earlier versions cached the initial `tabindex` on mount,
which could lock pseudo-buttons that mounted disabled at `tabindex="-1"`
even after `disabled={false}` was patched in. Server-authoritative
tabindex avoids that class of bug entirely.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** `inner_block` slot is `required: true` —
`lib/pulsar/components/button.ex:326–329`. Buttons with navigation
(`href`/`navigate`/`patch`) inherit this requirement, so the link text
is always present.

**Notes:** Caller responsibility to provide descriptive content; the
component enforces presence, not quality.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** `inner_block` required (visible label); `aria_label`
available as a supplement for icon-only buttons —
`lib/pulsar/components/button.ex:314–317, 326–329`.

### 2.4.7 Focus Visible (AA) — ⚠ GAP (minor) — needs browser verification

**Evidence:**
- Base classes include `focus-visible:outline-none`,
  `focus-visible:ring-2`, `focus-visible:ring-offset-2`,
  `focus-visible:ring-ring` — `lib/pulsar/components/button.ex:115–116`
- Link variant overrides ring with `focus-visible:underline` —
  `lib/pulsar/components/button.ex:130`
- Tests assert focus ring classes — `test/pulsar/components/button_test.exs:350–364`

**Notes:** Code is correct. Ring visibility under disabled (`opacity-50`)
and loading states, plus visibility under each color variant, requires
DevTools verification. Tracked under [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Button doesn't create sticky/overlapping content that
could obscure other focused elements — single-element render.

**Notes:** Page-level concern when buttons are used in sticky toolbars;
not a component-level gap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native `<button>` fires on `click` (mouseup). Pseudo-button
hook listens to `click` event, not `mousedown` —
`lib/pulsar/components/button.ex:644–646, 650`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** `aria_label` is optional and explicitly documented as "for
icon-only buttons" — `lib/pulsar/components/button.ex:314–317`. Default
behavior takes the accessible name from `inner_block` text content.

**Notes:** Callers can technically set `aria_label` that conflicts with
visible text; out of library control. Default behavior passes.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ⚠ GAP (minor) — needs browser verification

**Evidence:** Size `xs` is `h-6` (24px) — `lib/pulsar/components/button.ex:107`,
exactly at the AA 24×24 floor. Sizes `sm` (h-8), `md` (h-10), `lg` (h-12),
`xl` (h-14) all exceed. Padding `px-2` on xs gives ≈32px width for
single-character labels.

**Notes:** Height meets 24px minimum exactly; width depends on content
and padding. Icon-only `xs` buttons with single-character labels are
right at the floor — needs runtime confirmation. Tracked under browser
audit.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No `phx-focus` or focus-triggered context change in
component template — `lib/pulsar/components/button.ex:385–589`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Native button has implicit role; pseudo-buttons get `role="button"` —
  `lib/pulsar/components/button.ex:436, 463`
- State: `aria-busy`, `aria-disabled`, `aria-pressed`, `aria-expanded`,
  `aria-controls`, `aria-haspopup`, `aria-label` —
  `lib/pulsar/components/button.ex:399–409, 442–451, 469–479`
- Disclosure linkage enforced: raises if `:expanded` set without
  `:controls` — `lib/pulsar/components/button.ex:702–709`
- Tests assert `aria-busy`, `aria-disabled`, `aria-pressed`, `role="button"` —
  `test/pulsar/components/button_test.exs:378–443`

**Notes:** Comprehensive name/role/value coverage. The
`ensure_disclosure_linkage!` guard catches the common misuse of
`aria-expanded` without `aria-controls`.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:**
- `aria-busy="true"` rendered while loading —
  `lib/pulsar/components/button.ex:400, 442, 469, 522`
- Test asserts `aria-busy="true"` — `test/pulsar/components/button_test.exs:398–407`

**Notes:** Loading state is announced via `aria-busy`; AT can convey
the in-progress status without polling the visible spinner.

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
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no multipoint or path gestures.
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

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `lg` (h-12=48px) and
  `xl` (h-14=56px) exceed the AAA 44×44 target. Default `md` (h-10=40px)
  does not.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — focus ring uses
  `ring-2` (2px), the minimum thickness for AAA. Contrast still needs
  browser verification.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `color-contrast` | light: success solid; dark: primary ghost/solid | both | [PUL-27](https://linear.app/bigrefactor/issue/PUL-27/button-fix-axe-color-contrast-violation) |
