# Textarea · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/textarea.ex`](../../lib/pulsar/components/textarea.ex)
**Tests:** [`test/pulsar/components/textarea_test.exs`](../../test/pulsar/components/textarea_test.exs)
**Audited:** 2026-05-24 (code-only)

Native `<textarea>` leaf with variants, sizes, optional character
counter, and auto-resize hook hint. Automatically merges
`aria-describedby` from caller + field errors.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** No icons rendered by the textarea itself. Character
counter is plain text. The counter wrapper is `aria-hidden="true"` to
prevent double-reading of the count (which is implicit from the
textarea content) — `lib/pulsar/components/textarea.ex:537`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Native `<textarea>` carries semantic role —
  `lib/pulsar/components/textarea.ex:474`
- `aria-describedby` composed from caller value + field error region ID —
  `lib/pulsar/components/textarea.ex:488, 701–713`
- Test `merges caller aria-describedby with error ids` —
  `test/pulsar/components/textarea_test.exs:583–603`

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: textarea then optional character counter —
`lib/pulsar/components/textarea.ex:473–514`. Visual order matches.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Error state pairs color with `aria-invalid="true"` and (at
the field level) a text error message —
`lib/pulsar/components/textarea.ex:489`. Character counter changes color
at thresholds *and* shows explicit numeric values + "remaining" /
"over" text — `lib/pulsar/components/textarea.ex:539–542, 558–571`.

### 1.3.5 Identify Input Purpose (AA) — ✓ PASS

**Evidence:** `:rest` is `:global`, allowing `autocomplete=` to pass
through — `lib/pulsar/components/textarea.ex:422, 503`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Error state combines danger color + `aria-invalid` + (via
field) text error — `lib/pulsar/components/textarea.ex:489`. Character
counter color changes are paired with explicit numeric text and
"remaining"/"over" labels — `lib/pulsar/components/textarea.ex:539–542`.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious, [PUL-43](https://linear.app/bigrefactor/issue/PUL-43/textarea-fix-axe-color-contrast-violation))

**Evidence:** Color/variant matrix uses semantic tokens —
`lib/pulsar/components/textarea.ex:151–310`. Character counter has
multi-state colors — `lib/pulsar/components/textarea.ex:313–325`.
Browser measurement of 271 cells per theme
([light](measurements/textarea-light.md),
[dark](measurements/textarea-dark.md)):

- **Dark:** 258/271 pass (min 3.31:1). 13 failures cluster around
  `character-count` and `solid-neutral` text.
- **Light:** 157/271 pass (min 2.74:1). 114 failures span ghost/
  outline-success/warning and all `solid-*` variants — same pattern
  as Input.

**Notes:** [PUL-43](https://linear.app/bigrefactor/issue/PUL-43)
scoped to "success outline variant"; expand to cover warning and the
solid family in light mode. Pattern mirrors Input and Select; a
single fix to the color tokens at the theme level addresses all
three.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Min-heights use rem-based `min-h-*` —
`lib/pulsar/components/textarea.ex:104–135`. Padding/text classes also rem.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** Textarea uses `w-full` and no fixed width —
`lib/pulsar/components/textarea.ex:139`. Container is `space-y-2` —
`lib/pulsar/components/textarea.ex:473`.

### 1.4.11 Non-text Contrast (AA) — ⚠ GAP (serious, PUL-19 follow-up: textarea-outline-border-contrast)

**Evidence:** Outline variant uses `border-2` —
`lib/pulsar/components/textarea.ex:146`; focus ring `focus:ring-2
focus:ring-offset-2` — `lib/pulsar/components/textarea.ex:140`.
Browser measurement: border contrast measured on the textarea cell
itself (which carries the border directly). 90 outline cells per
theme, 30 pass light / 48 pass dark. Failing outline colors in light
mode: `outline-neutral` (1.18:1), `outline-primary` (~2.4:1),
`outline-secondary` (~2.4:1), `outline-success` (~2.6:1),
`outline-warning` (~2.7:1) — all below the 3:1 floor. Focus ring
measured 3.06:1 (light min) / 3.67:1 (dark min) — passes.

**Notes:** New finding — `textarea-outline-border-contrast` to be
filed as a Linear sub-issue parented to PUL-19. The textarea outline
variant border (`border-*-300`) sits between primary/secondary/etc
tokens at light shades that don't reliably meet 3:1 against the
default white background. Same defect as the Select outline borders
([`select.md` 1.4.11](select.md#1411-non-text-contrast-aa)).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** `min-h-*` (not `h-*`) gives vertical headroom —
`lib/pulsar/components/textarea.ex:104–135`. `max-h-*` *does* cap growth,
which could be a concern under user line-height overrides. Browser
test injects the WCAG overrides and re-measures: 0 cells overflow
([light](measurements/textarea-light.md#text-spacing-override-wcag-1412),
[dark](measurements/textarea-dark.md#text-spacing-override-wcag-1412)).
The textarea content uses native scrolling, so once content exceeds
`max-h-*` the textarea scrolls — content is not clipped or lost.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<textarea>` is fully keyboard-operable —
`lib/pulsar/components/textarea.ex:474–504`. No custom keydown handlers.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Native textarea; Tab moves focus normally.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only `transition-all duration-200 ease-in-out` for color
changes — `lib/pulsar/components/textarea.ex:139`. No essential motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** No flashing; smooth transitions only.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** No positive `tabindex`; native textarea takes focus in DOM
order — `lib/pulsar/components/textarea.ex:474–504`.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** Label is the caller's responsibility (typically via
`field`); leaf accepts `id` for `for=` linkage.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** `focus:ring-2 focus:ring-offset-2` —
`lib/pulsar/components/textarea.ex:140`. Browser measurement of 217
focus-ring cells: min 3.06:1 (light) / 3.67:1 (dark)
([light](measurements/textarea-light.md),
[dark](measurements/textarea-dark.md)). All cells exceed 3:1.

**Notes:** Uses `focus:` not `focus-visible:`, so the ring shows on
mouse click as well as keyboard focus. The 3.06:1 minimum in light
theme corresponds to lower-contrast color rings (success/warning);
the default neutral ring resolves to the same `--color-ring` token
as Button (5.02:1 / 6.72:1).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Single textarea + optional counter; no sticky overlap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native textarea; no custom click handlers —
`lib/pulsar/components/textarea.ex:474–504`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** No `aria-label` set; accessible name flows from the
associated label — `lib/pulsar/components/textarea.ex:474–504`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Smallest size `xs` is `min-h-16` (64px) —
`lib/pulsar/components/textarea.ex:131`. All sizes exceed the 24px
floor comfortably. Width is `w-full`. Browser measurement: 271/271
cells ≥ 24×24
([light](measurements/textarea-light.md),
[dark](measurements/textarea-dark.md)).

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No focus handler; auto-resize is a data-attribute hint
(`data-auto-resize`) not a focus trigger —
`lib/pulsar/components/textarea.ex:494`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** `:rest` forwards `phx-change` to the textarea, but
component itself triggers no navigation/submit —
`lib/pulsar/components/textarea.ex:422, 503`.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** `aria-invalid` flips based on errors or explicit `:invalid` —
`lib/pulsar/components/textarea.ex:489`. `aria-describedby` extends to
the errors ID — `lib/pulsar/components/textarea.ex:701–713`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** Label is caller's responsibility via `field`; leaf accepts
`id` and supports `aria-describedby` for help text.

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Textarea doesn't suppress error text; rendering happens at
the `field` wrapper level.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Role: native `<textarea>` —
  `lib/pulsar/components/textarea.ex:474`
- Name: `name=` attr —
  `lib/pulsar/components/textarea.ex:476`
- Value: rendered as text content `{to_string(@value || "")}` —
  `lib/pulsar/components/textarea.ex:504`
- State: `aria-invalid`, `aria-describedby`, native
  `required`/`disabled`/`readonly`/`maxlength`/`minlength` —
  `lib/pulsar/components/textarea.ex:481–489`

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** `aria-invalid` reflects error state —
`lib/pulsar/components/textarea.ex:489`. Field-level error region carries
`aria-live="polite"`.

**Notes:** Character counter is `aria-hidden="true"` —
`lib/pulsar/components/textarea.ex:537`. This is intentional to prevent
double-announcement when the user is typing; the count is implicit from
the textarea content. If callers need live count announcement, they
should add their own `aria-live` region — out of scope here.

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

- **2.5.5 Target Size (Enhanced) (AAA)** — all sizes (`xs`=64px through
  `xl`=160px) exceed the AAA 44×44 floor.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets
  AAA minimum thickness. Browser measurement: ring contrast min
  3.06:1 (light) / 3.67:1 (dark) — passes AA 3:1 but falls below
  AAA 4.5:1 for low-contrast color variants. Not a confirmed AAA win
  for every color.

## Browser a11y findings (PUL-11)

Violations surfaced by the axe-core browser gate added in `pul-11-axe-playwright`.

| Rule | Affected variant(s) | Themes | Ticket |
|------|---------------------|--------|--------|
| `label` | unlabelled textarea-cc | both | [PUL-42](https://linear.app/bigrefactor/issue/PUL-42/textarea-fix-axe-label-violation) |
| `color-contrast` | success outline variant | both | [PUL-43](https://linear.app/bigrefactor/issue/PUL-43/textarea-fix-axe-color-contrast-violation) |
