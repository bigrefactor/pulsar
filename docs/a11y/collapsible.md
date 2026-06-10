# Collapsible · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/collapsible.ex`](../../lib/pulsar/components/collapsible.ex)
**Tests:** [`test/pulsar/components/collapsible_test.exs`](../../test/pulsar/components/collapsible_test.exs)
**Audited:** 2026-06-10 (code + browser axe gate)

Collapsible is a single expand/collapse disclosure — a `:trigger` slot rendered
inside a native `<button>` over one collapsible panel (the default slot). It is
the simple disclosure pattern, not the grouped Accordion: there is no heading
wrapper, no `role="region"` landmark, and no roving arrow-key navigation. The
button controls a sibling panel via `aria-controls`. A colocated LiveView hook
toggles `data-expanded` on the container (driving the
`grid-template-rows: 0fr → 1fr` height animation) and keeps `aria-expanded` on
the button in sync. The component stays in document flow and does not trap focus.

## Disclosure pattern mapping

| Disclosure requirement | Implementation |
| --- | --- |
| The trigger is a native `<button type="button">`. | `lib/pulsar/components/collapsible.ex:160–169` |
| The button carries `aria-expanded` reflecting the panel's state. | `:164` (markup), hook `setOpen` (`:200–205`) |
| The button carries `aria-controls` pointing at its panel. | `:163`, panel id `:171` |
| Click or Enter/Space toggles the panel. | hook `click` listener (`:185`), `toggle` (`:191–199`) |
| Open/closed state survives LiveView re-renders. | hook `restore` (`:206–209`), `mounted`/`updated` (`:178–179`) |

## Applicable criteria

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Trigger text rests at `text-muted-foreground` (gray-600,
≈6.0–7.23:1 on the container surfaces — clears AA for normal text in both
themes) and darkens to `text-foreground` on hover and when open
(`group-data-[expanded]/collapsible:text-{color}`). Panel body text inherits the
surrounding `foreground`. The browser axe gate measures the settled colors of
the trigger and the open panel across light + dark and reports clean.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:91`
(`@trigger_base` — `text-muted-foreground … hover:text-foreground`),
`lib/pulsar/components/collapsible.ex:50–58` (`@trigger_open` open-state tint map),
`lib/pulsar/components/collapsible.ex:230–233` (`trigger_classes/2` composing them).

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Two non-text affordances clear the 3:1 floor. The focus ring is
`ring-2` drawn from the `--color-ring` token (verified to clear 3:1 on every
surface). The chevron indicator inherits the trigger's text color — at rest
`muted-foreground` (≈6:1, well over 3:1) and `foreground`/the open tint when
expanded — and rotates 180° to encode open/closed, so the state is conveyed by
orientation and `aria-expanded`, not by contrast alone.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:91`
(`focus-visible:ring-2 focus-visible:ring-ring` in `@trigger_base`),
`lib/pulsar/components/collapsible.ex:93` (`@chevron_base` —
`group-data-[expanded]/collapsible:rotate-180`),
`lib/pulsar/components/collapsible.ex:168` (chevron icon, color inherited from
the trigger button).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The trigger is a native `<button>` in the tab order — Tab reaches
it and Enter/Space toggles the panel natively (the hook's `click` listener fires
on the synthetic click that Enter/Space dispatches on a button). There is no
pointer-only affordance.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:160–161`
(`<button type="button">`), `lib/pulsar/components/collapsible.ex:185`
(`addEventListener("click", …)` on the trigger),
`lib/pulsar/components/collapsible.ex:191–199` (`toggle` — runs on click, which
Enter/Space synthesize on a button). Tests `trigger is a button wired to the
panel, closed by default` and `open renders expanded state` —
`test/pulsar/components/collapsible_test.exs`. The browser interaction test
`clicking the trigger opens the panel (visible, not just aria)` in
`test/integration/a11y/keyboard_test.exs` proves the panel actually expands.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** The trigger is a native `<button>` rendered before its panel in
document order, so Tab visits the trigger then any focusables inside the open
panel in source order, with no positive `tabindex` reordering.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:160–174`
(trigger button then panel, no positive tabindex).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The trigger button shows a `focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-inset` indicator and
`focus-visible:outline-none` to suppress the doubled UA outline.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:91`
(`@trigger_base` — `focus-visible:outline-none focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-inset`).

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The collapsible renders linearly in document flow and creates no
sticky, fixed, or overlapping content that could cover the focused trigger or
its panel — the markup is a plain `<div>` of button and panel.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:152–175`
(in-flow container → button/panel render tree; no sticky/overlay layer).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Toggling is driven by a `click` listener (fires on mouseup, after
the up-event so a pointer-down can be cancelled by dragging off), not by
`pointerdown`/`mousedown`.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:185`
(`addEventListener("click", …)`), `lib/pulsar/components/collapsible.ex:191–199`
(`toggle` — runs on click).

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** The trigger button's accessible name is its visible `:trigger`
content; there is no `aria-label` on the button to contradict the visible label,
and the chevron is decorative.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:167`
(`<span>{render_slot(@trigger)}</span>` — visible text is the accessible name),
`lib/pulsar/components/collapsible.ex:160–169` (button has no overriding
`aria-label`).

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Trigger padding starts at `px-3 py-2` on `text-xs` (xs) and grows
through the size scale, keeping the clickable box at or above 24×24 CSS px; the
trigger is a full-width row with no overlapping adjacent targets.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:73–79`
(`@size_trigger` padding scale — `px-3 py-2` floor at xs up to `px-6 py-5` at xl),
`lib/pulsar/components/collapsible.ex:160–169` (full-width trigger button).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**

- **Role/name** — the trigger is a `<button>` whose accessible name is its
  visible `:trigger` content (the chevron is decorative).
- **Value** — `aria-expanded` is `"true"`/`"false"` in the server markup and is
  kept in sync by the hook's `setOpen` on every toggle, and re-asserted across
  LiveView re-renders via `restore()` in `updated()`. The panel is linked from
  the trigger via `aria-controls`.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:160–169` (button:
`aria-controls` at :163, `aria-expanded` at :164, `:trigger` span at :167),
`lib/pulsar/components/collapsible.ex:171` (panel `id` matching `aria-controls`),
`lib/pulsar/components/collapsible.ex:200–205` (`setOpen` — `aria-expanded` sync),
`lib/pulsar/components/collapsible.ex:206–209` (`restore` — re-asserts open state
after a LiveView patch), `lib/pulsar/components/collapsible.ex:178–179`
(`mounted`/`updated` both call `restore`). Tests `trigger is a button wired to
the panel, closed by default` and `open renders expanded state` —
`test/pulsar/components/collapsible_test.exs`.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the trigger does not toggle the panel or cause any context
change; only Enter/Space or a click toggles it.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:185`
(only a `click` listener — no `focus` handler that changes context).

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Toggling the panel does not trigger navigation or form submission;
it only shows/hides in-page content and (when `on_change` is wired) pushes a
server event the app handles.

**Evidence line numbers:** `lib/pulsar/components/collapsible.ex:191–199`
(`toggle` — local show/hide plus an optional `on_change` push, no navigation).

## Not applicable

- **1.1.1 Non-text Content (A)** — the chevron is decorative alongside the
  trigger button's text name; no informational image.
- **1.2.x Time-based Media** — no media.
- **1.3.1 Info and Relationships (A)** — covered by the button/`aria-controls`
  structure under 4.1.2.
- **1.3.2 Meaningful Sequence (A)** — trigger precedes panel; no visual
  reordering.
- **1.3.3 Sensory Characteristics (A)** — open state is exposed via
  `aria-expanded`, not by shape or position alone.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.1 Use of Color (A)** — the open state is encoded by the chevron rotation
  and `aria-expanded`, not by the color tint alone.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.4 Resize Text (AA)** — all sizing is relative (`text-*`/`rem`); no fixed
  pixel text.
- **1.4.5 Images of Text (AA)** — no text images.
- **1.4.10 Reflow (AA)** — the container is fluid; callers cap width with a
  utility class (e.g. `max-w-md`), imposing no fixed minimum.
- **1.4.12 Text Spacing (AA)** — no inline style overrides line-height or spacing.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-triggered
  supplementary content; the trigger hover only shifts text color.
- **2.1.2 No Keyboard Trap (A)** — the trigger is an ordinary tab stop; no
  Tab/Shift+Tab is intercepted.
- **2.1.4 Character Key Shortcuts (A)** — no single-character shortcuts (there is
  no arrow-key navigation in a single disclosure).
- **2.2.x Timing / Pause** — only a sub-second open transition; no time limit or
  auto-updating content.
- **2.3.1 Three Flashes (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — the trigger is a button, not a link.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the `:trigger` content is caller-supplied;
  the component renders it faithfully.
- **2.5.1 Pointer Gestures (A)** — no path or multipoint gestures; a single click
  toggles.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.x Language** — page-level concern.
- **3.2.3–3.2.6 (page-level)** — consistent-navigation/identification/help are
  page-level concerns.
- **3.3.x Forms** — not a form input.
- **4.1.3 Status Messages (AA)** — `aria-expanded` on the trigger communicates
  state in-place; no separate live region is needed.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — `ring-2` (2px) meets the AAA
  minimum thickness and the `--color-ring` token clears AAA contrast —
  `lib/pulsar/components/collapsible.ex:91`.

## Browser a11y findings

None. The axe gate at `/components/collapsible` — scanned in light + dark, with
the "open (primary)" cell rendering an open panel — is clean.
