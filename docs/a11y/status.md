# Status · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/status.ex`](../../lib/pulsar/components/status.ex)
**Fixture:** [`test/support/dev_app/live/status_live.ex`](../../test/support/dev_app/live/status_live.ex) (`/components/status`)
**Standard:** WCAG 2.2 Level AA
**Audited:** 2026-06-08

A small colored dot signalling state, used standalone or placed on the corner of
another element via `indicator/1`. The dot is decorative by default
(`aria-hidden`), on the assumption that adjacent text conveys the state; when it
is the only signal, a `label` exposes it via `role="img"` and `aria-label`. An
optional `ping` adds an expanding-halo animation; the halo is an `aria-hidden`
clone behind a static dot, and reduced-motion users get a plain static dot.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** With no `label` the dot is removed from the accessibility tree
(`aria-hidden="true"` on the wrapper) — `lib/pulsar/components/status.ex:138`,
resolved at `lib/pulsar/components/status.ex:235–236` —
which is correct for a dot that is redundant with adjacent text. With a `label`
the dot is exposed as a named image (`role="img"` + `aria-label`) —
`lib/pulsar/components/status.ex:136–137`. The `ping` halo clone is always
`aria-hidden="true"` — `lib/pulsar/components/status.ex:143`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** A labeled dot uses `role="img"` to mark itself a single graphical
object — `lib/pulsar/components/status.ex:136`, resolved at
`lib/pulsar/components/status.ex:232–233`. The dot has no internal structure
to expose; `indicator/1` is a plain layout `<div>` with no role —
`lib/pulsar/components/status.ex:196`.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on the dot's shape, size, or position; the
state reaches assistive tech through the `label` text rather than the color or
the corner it sits on — `lib/pulsar/components/status.ex:136–137`.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** When the dot carries meaning, that meaning is the `label` text
(announced via `role="img"`/`aria-label`), never color alone —
`lib/pulsar/components/status.ex:136–137`. A dot with no label is decorative and the
meaning lives in adjacent visible text the caller provides.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All dot dimensions are `rem`-based Tailwind tokens
(`h-1.5 w-1.5`…`h-4 w-4`) — `lib/pulsar/components/status.ex:66–72`. No fixed `px`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The dot is a small inline `<span>`; `indicator/1` is
`relative inline-flex` with the item absolutely positioned relative to its own
content — `lib/pulsar/components/status.ex:192, 223`. No fixed-`px` widths; reflows at
320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** A status dot is a graphical object conveying state, so its fill
must reach ≥3:1 against the surface behind it. The fills are the house semantic
background tokens (`bg-primary`, `bg-success`, `bg-danger`, …) —
`lib/pulsar/components/status.ex:55–63` — the same saturated tokens used as
button/badge backgrounds, which clear 3:1 against both page backgrounds. When the
dot is overlaid on busy content, `indicator/1` draws a `ring-background`
separation ring around it so the dot edge stays distinguishable —
`lib/pulsar/components/status.ex:88, 224`. Verified axe-clean in light + dark via the
fixture.

**Notes:** axe's `color-contrast` rule targets text; the dot renders no text, so
its non-text contrast is verified by the semantic-token values above (and, where
needed, the separation ring), not by an automated text-contrast check.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The only motion is the optional `ping` halo (`animate-ping` —
`lib/pulsar/components/status.ex:145`), a smooth sub-second loop, not essential to
meaning. The library-wide `prefers-reduced-motion: reduce` rule near-stops it,
and the halo clone additionally carries `motion-reduce:hidden` —
`lib/pulsar/components/status.ex:145` — so reduced-motion users see a plain static
dot.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** The `ping` halo is a smooth expand-and-fade loop —
`lib/pulsar/components/status.ex:145` — nothing flashes more than three times per
second.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** A labeled dot exposes `role="img"` with an accessible name from
`aria-label` — `lib/pulsar/components/status.ex:136–137`; an unlabeled dot sets
`aria-hidden="true"` and is removed from the tree —
`lib/pulsar/components/status.ex:138`. `@rest` forwards `id`/`data-*`/ARIA —
`lib/pulsar/components/status.ex:139, 196`. The dot has no settable value or
interactive state.

## Not applicable

- **1.2.1–1.2.5 (time-based media)** — no media.
- **1.3.2 Meaningful Sequence (A)** — a single dot (and an item-after-content flow in `indicator/1`) carries no order-dependent meaning.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.3 Contrast (Minimum) (AA)** — renders no text; the graphic is covered by 1.4.11.
- **1.4.5 Images of Text (AA)** — renders no text as images.
- **1.4.12 Text Spacing (AA)** — renders no text.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-revealed content.
- **2.1.1 / 2.1.2 / 2.1.4 (keyboard)** — non-interactive; nothing to operate.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1–2.4.7, 2.4.11 (focus/navigation)** — no focusable content; page-level concerns.
- **2.5.1–2.5.4, 2.5.7, 2.5.8 (pointer/target)** — no interactive target or gesture.
- **3.1.1 / 3.1.2 (language)** — page-level concerns.
- **3.2.1–3.2.6 (predictable)** — non-interactive; page-level concerns.
- **3.3.1–3.3.8 (input assistance)** — not a form input.

## Browser a11y findings

The axe-core browser gate reports no violations for the Status fixture on
`/components/status` in either theme
([`test/integration/a11y/axe_clean_test.exs`](../../test/integration/a11y/axe_clean_test.exs)).
