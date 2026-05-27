# Input · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/input.ex`](../../lib/pulsar/components/input.ex)
**Tests:** [`test/pulsar/components/input_test.exs`](../../test/pulsar/components/input_test.exs)
**Audited:** 2026-05-24 (code-only)

Styled text input leaf for all HTML5 single-line input types
(text/email/password/number/tel/url/search/date/time/file/range/etc.)
with optional start/end decorator slots. Wraps the native `<input>` in
a container `<div>` that owns focus-within styling.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** No decorative icons rendered by the component itself.
Decorator slots are caller-supplied; any icons passed in are the
caller's responsibility — `lib/pulsar/components/input.ex:495–539`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<input>` carries its semantic type via `type={@type}` —
  `lib/pulsar/components/input.ex:459`
- `aria-invalid` reflects validation state from Phoenix form errors or
  the explicit `:invalid` attr — `lib/pulsar/components/input.ex:415–419, 466`
- Test `sets aria-invalid to 'true' when field has errors` —
  `test/pulsar/components/input_test.exs:368–389`

**Notes:** Label association is the responsibility of the `field`
wrapper (or caller); this leaf accepts `id` and exposes it for `for=`
linkage.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: start decorator → input → end decorator —
`lib/pulsar/components/input.ex:439–478`. Matches visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Error state combines color (`text-danger`/`bg-danger`),
border, and `aria-invalid="true"` —
`lib/pulsar/components/input.ex:181–211, 466`. Disabled state combines
opacity + cursor + native `disabled` —
`lib/pulsar/components/input.ex:454, 464, 561–568`.

### 1.3.5 Identify Input Purpose (AA) — ✓ PASS

**Evidence:** `:rest` is a `:global` attribute, allowing
`autocomplete="email"`/`autocomplete="name"`/etc. to pass through to the
native input — `lib/pulsar/components/input.ex:360, 467`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state pairs danger color with `aria-invalid="true"`
and (when used via field) a text error message —
`lib/pulsar/components/input.ex:417, 466`. Disabled state combines
opacity + cursor + native `disabled` attr.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious)

**Evidence:** Color/variant matrix uses semantic tokens —
`lib/pulsar/components/input.ex:162–211, 213–250`. Browser measurement
of 361 cells per theme ([light](measurements/input-light.md),
[dark](measurements/input-dark.md)):

- **Dark:** 344/361 pass (min 3.31:1). 17 failures cluster around
  `decorators` (3.31:1) and `solid-neutral` placeholder text against
  the surface bg.
- **Light:** 209/361 pass (min 2.74:1). 152 failures span
  `ghost-success`, `ghost-warning`, `outline-success`,
  `outline-warning`, and all `solid-*` variants — solid backgrounds
  in light mode pair high-luminance bg with text foreground in a
  way that undershoots 4.5:1.

**Notes:** Originally scoped to "success outline variant"; the failure
set extends to the warning variant and all `solid-*` variants in light
mode. Pattern is the same as Button — success/warning color tokens
need higher contrast in light theme.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Container heights use rem-based `min-h-*` values —
`lib/pulsar/components/input.ex:90–96`. Padding and text classes also rem.

**Notes:** `min-h-` (not `h-`) gives the input headroom to grow with
larger user text settings.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Container is `flex group overflow-hidden` —
`lib/pulsar/components/input.ex:149`. Input itself uses `w-full` (`px-*`
padding only) — `lib/pulsar/components/input.ex:452`. No fixed widths or
min-widths.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS — borders measured on wrapper

**Evidence:**
- Outline variant uses `border-2` with semantic border colors —
  `lib/pulsar/components/input.ex:156, 179–194`
- Outline-neutral routes through `border-border-strong` —
  `lib/pulsar/components/input.ex:181`
- Focus ring is `focus-within:ring-2 focus-within:ring-offset-2` —
  `lib/pulsar/components/input.ex:150`
- Test `includes focus ring classes` —
  `test/pulsar/components/input_test.exs:300–311`

Browser measurement reads `no-border` and `no-focus-ring` for every
input cell because the `data-fixture-cell` is on the `<input>`
element while the visible border and focus-within ring live on the
wrapping container. The shared `--color-border-strong` and
`--color-ring` tokens are the same ones measured on Button
(`--color-ring` 5.02:1 / 6.72:1, `outline-neutral` border 4.63:1 in
both themes).

**Notes:** `--color-border-strong` resolves to `gray-500` (light) /
`gray-400` (dark), giving the outline-neutral wrapper edge ≥4.5:1
against the page background. Other outline colors continue to pass
(primary 4.4:1, danger 4.2:1).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** `min-h-*` heights (not `h-*`) allow vertical growth —
`lib/pulsar/components/input.ex:90–96`. Padding `px-*`/`py-*` is rem.
Browser test injects the four WCAG 1.4.12 overrides and re-measures:
0 cells overflow
([light](measurements/input-light.md#text-spacing-override-wcag-1412),
[dark](measurements/input-dark.md#text-spacing-override-wcag-1412)).

**Notes:** The `min-h-*` (not `h-*`) choice is what makes this PASS —
inputs absorb the larger line-height without clipping.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<input>` is keyboard-operable by default —
`lib/pulsar/components/input.ex:449–468`. No custom keydown handlers.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No `keydown` handler. Native Tab behavior preserved.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only animations are smooth color/transform transitions
(`transition-all duration-200`) — `lib/pulsar/components/input.ex:149, 452`.
No essential motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; only smooth transitions —
`lib/pulsar/components/input.ex:149, 452`.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`. Decorators are non-interactive
`<div>` wrappers around caller-supplied content; the native input takes
focus in DOM order — `lib/pulsar/components/input.ex:495–539`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Label is the caller's responsibility (typically via
`field`); leaf accepts `id` for `for=`/`aria-labelledby` linkage.

### 2.4.7 Focus Visible (AA) — ✓ PASS (inferred)

**Evidence:** `focus-within:ring-2 focus-within:ring-offset-2` on the
container — `lib/pulsar/components/input.ex:150`. Native input is
inside; container focus-within fires when the input is focused.

**Notes:** Same ring color (`--color-ring`) as Button — measured at
5.02:1 (light) / 6.72:1 (dark) on the Button fixture, which exceeds
the 3:1 non-text minimum. The input fixture doesn't currently capture
the focus ring per-cell because the wrapper that carries
`focus-within:ring-*` doesn't carry `data-fixture-cell`.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Single-element render; doesn't create sticky overlap —
`lib/pulsar/components/input.ex:439–479`.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native `<input>` interaction; no custom mousedown/click
handlers — `lib/pulsar/components/input.ex:449–468`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** Input does not set its own `aria-label`; accessible name
flows from the associated `<label>` — `lib/pulsar/components/input.ex:449–468`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Size `xs` is `min-h-6` (24px) —
`lib/pulsar/components/input.ex:95`. Other sizes (`sm`=32px, `md`=40px,
`lg`=48px, `xl`=56px) exceed. Browser measurement of 361 fixture
cells: 361/361 pass ≥24×24
([light](measurements/input-light.md), [dark](measurements/input-dark.md)).
Width is `w-full` (typically ample); height meets or exceeds 24px
in every variant×color×size×state combination tested.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No `phx-focus` or context change on focus —
`lib/pulsar/components/input.ex:449–468`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-change` etc. to the input, but the
component itself triggers no navigation/submit on input —
`lib/pulsar/components/input.ex:360, 467`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid="true"`/`"false"` written based on errors —
`lib/pulsar/components/input.ex:466`. Error message rendering happens at
the `field` wrapper level.

**Notes:** Test `sets aria-invalid to 'true' when field has errors` —
`test/pulsar/components/input_test.exs:368–389`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label is the caller's responsibility via `field` wrapper;
the leaf accepts the necessary `id` for `for=` linkage.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Input doesn't suppress or modify caller-provided error
text; error text rendering is the `field` wrapper's responsibility.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: implicit from native `<input type="…">` —
  `lib/pulsar/components/input.ex:459`
- Name: from `name=` attr (Phoenix form integration) —
  `lib/pulsar/components/input.ex:461`
- Value: from `value=` attr (skipped for `type="file"` per HTML
  semantics) — `lib/pulsar/components/input.ex:462`
- State: `aria-invalid`, native `required`/`disabled`/`readonly` —
  `lib/pulsar/components/input.ex:463–466`

**Notes:** Uses native HTML attributes wherever possible; ARIA only
where needed.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` flips with error state —
`lib/pulsar/components/input.ex:466`. The associated error region
(rendered by `field`) carries `aria-live="polite"`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip/popover.
- **2.1.4 Character Key Shortcuts (A)** — none registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no gestures.
- **2.5.4 Motion Actuation (A)** — none.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (AA)** — form-level concern.
- **3.3.7 Redundant Entry (A, new in 2.2)** — form/app-level concern.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.

## AAA wins (bonus)

- **2.5.5 Target Size (Enhanced) (AAA)** — sizes `lg` (`min-h-12`=48px)
  and `xl` (`min-h-14`=56px) exceed the AAA 44×44 floor. Default `md`
  (40px) does not.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — focus ring is `ring-2`
  (2px), meeting AAA minimum thickness. Contrast still needs browser
  verification.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `color-contrast` | success outline variant | both |
