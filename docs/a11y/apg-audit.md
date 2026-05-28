# Pulsar APG audit — interactive components

Companion to the [WCAG 2.2 AA audit](README.md). Where the WCAG audit
verified that ARIA attributes are present and keyboard handlers exist,
this audit cross-checks Pulsar's interactive components against the
W3C [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/)
(APG) — the pattern-by-pattern playbook for accessible widgets.

APG is stricter than WCAG. A component can pass WCAG 4.1.2 (Name, Role,
Value) yet still diverge from its prescribed APG pattern — for example,
a radio group with `role="radiogroup"` and proper labels passes WCAG
but still misses the APG-required **Home** / **End** keys for jumping
to the first / last radio.

**Method:** Code-only. For each component → APG pattern pairing, the
audit confirms the APG keyboard interactions and ARIA roles / states /
properties against the Pulsar source.

**Scope (7 patterns):**

| Pulsar component | APG pattern |
|------------------|-------------|
| `button.ex` (native + pseudo-button) | [Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) |
| `button.ex` with `expanded` + `controls` | [Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) |
| `link.ex` | [Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/) |
| `checkbox.ex` (two-state + tri-state) | [Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) |
| `switch.ex` | [Switch](https://www.w3.org/WAI/ARIA/apg/patterns/switch/) |
| `radio_group.ex` | [Radio Group](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) |
| `flash.ex` (`role="alert"` / `role="status"`) | [Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) |
| `table.ex` `row_click` (treated as Button) | Button pattern applied to `<tr>` |

**Out of scope** — components without an APG equivalent: `field`,
`label`, `input`, `textarea`, `select` (native semantics), `card`,
`divider`, `header`, `list`, `flash_group`, `badge`, `icon`
(structural / content).

**Severity:**

- **blocker** — APG-required interaction or attribute missing (e.g., no
  `role="switch"` on a switch; Enter triggers action on a switch).
- **serious** — APG-required interaction missing but an alternative
  path exists (e.g., Home/End missing while arrow keys still navigate).
- **minor** — APG-recommended (not required) feature missing, or
  inconsistency in event timing.

---

## Summary

| Component | APG pattern | Keyboard | ARIA | Status |
|-----------|-------------|:--------:|:----:|--------|
| button (native + pseudo) | Button | ✓ | ✓ | ✓ Compliant |
| button (with expanded+controls) | Disclosure | ✓ | ✓ | ✓ Compliant |
| link | Link | ✓ | ✓ | ✓ Compliant |
| checkbox (two-state) | Checkbox · two-state | ✓ | ✓ | ✓ Compliant |
| checkbox (tri-state) | Checkbox · tri-state | ✓ | ✓ | ✓ Compliant |
| switch | Switch | ✓ | ✓ | ✓ Compliant |
| radio_group (default) | Radio Group | ✓ | ✓ | ✓ Compliant |
| radio_group (card) | Radio Group | ✓ | ✓ | ✓ Compliant |
| flash (alert / status) | Alert | N/A | ✓ | ✓ Compliant |
| table row-click | Button (applied to `<tr>`) | ✓ | ✓ | ✓ Compliant |

**All audited components: ✓ Compliant.**

---

## Button — `button.ex`

**Source:** [`lib/pulsar/components/button.ex`](../../lib/pulsar/components/button.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/button/>

Native `<button>` is keyboard-operable by default. The pseudo-button
branches (`as: :a`, `as: :div` with `role="button"`) supply the same
behavior through the colocated `.PulsarButton` hook
(`lib/pulsar/components/button.ex:595–666`).

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Space | Activate | ✓ | Native `<button>`: browser default. Pseudo-button: `e.preventDefault()` on keydown to prevent page scroll (`button.ex:635`), then `el.click()` on keyup (`button.ex:641`). |
| Enter | Activate | ✓ | Native `<button>`: browser default. Pseudo-button: `e.preventDefault(); el.click()` on keydown (`button.ex:636`). |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `button` | ✓ | Native `<button>` element (`button.ex:392–415`). Pseudo-button explicitly sets `role="button"` (`button.ex:436, 463`). |
| Accessible name | ✓ | `inner_block` is `required: true` (`button.ex:326–329`); optional `aria_label` for icon-only buttons (`button.ex:314–317, 405`). |
| Description (`aria-describedby`) | ✓ | Available via `{@rest}` pass-through; not enforced. |
| `aria-disabled` when disabled | ✓ | `button.ex:400, 442, 469` — emitted whenever `disabled` or `loading` is true. |
| `aria-pressed` for toggle buttons | ✓ | `button.ex:401, 443, 470` — emitted when `pressed` is a boolean. |

### Divergences

None. ✓ Compliant.

---

## Disclosure — `button.ex` with `expanded` + `controls`

**Source:** [`lib/pulsar/components/button.ex`](../../lib/pulsar/components/button.ex) (same component; disclosure is the use of `:expanded` + `:controls` attrs)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/>

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Space | Toggle visibility | ✓ | Same as button activation (`button.ex:635, 641`). |
| Enter | Toggle visibility | ✓ | Same as button activation (`button.ex:636`). |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `button` | ✓ | Inherits from button pattern. |
| `aria-expanded` (true/false) | ✓ | `button.ex:402, 444, 471` — emitted as `"true"` / `"false"` when `:expanded` is boolean. |
| `aria-controls` references the controlled element | ✓ | `button.ex:403, 445, 472` — emitted from `:controls` attr. Linkage **enforced**: `ensure_disclosure_linkage!` raises if `:expanded` is set without `:controls` (`button.ex:702–709`). |

### Divergences

None. ✓ Compliant.

**Note:** The enforcement guard fires only one way (expanded ⇒ controls
required). Setting `:controls` without `:expanded` does not raise — but
that combination is APG-incorrect for the disclosure pattern (a
disclosure trigger must announce its state via `aria-expanded`).
Callers must opt in by setting `:expanded`. Not a component-level gap.

---

## Link — `link.ex`

**Source:** [`lib/pulsar/components/link.ex`](../../lib/pulsar/components/link.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/link/>

Native `<a>` element — keyboard and role inherited from HTML.

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Enter | Execute link, move focus to target | ✓ | Browser default on `<a href>`. |
| Shift+F10 (optional) | Context menu | ✓ | Browser default; not a component concern. |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `link` | ✓ | Implicit on native `<a>` element. |

### Divergences

None. ✓ Compliant.

---

## Checkbox — `checkbox.ex` (two-state + tri-state)

**Source:** [`lib/pulsar/components/checkbox.ex`](../../lib/pulsar/components/checkbox.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/>

Native `<input type="checkbox">` — role and keyboard inherited from HTML.

### Keyboard interactions (two-state & tri-state)

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Space | Toggle checked state | ✓ | Browser default on `<input type="checkbox">`. |

### WAI-ARIA roles, states, properties (two-state)

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `checkbox` | ✓ | Implicit on `<input type="checkbox">` (`checkbox.ex:384, 442`). |
| Accessible name | ✓ | Provided via field wrapper (`field.ex`) or caller's `<.label for={id}>`. |
| Checked state via `aria-checked` (or native `checked`) | ✓ | Native `checked` attribute (`checkbox.ex:388, 446`). APG explicitly notes that HTML checkbox inputs use `checked` instead of `aria-checked` — ✓ correct. |
| `aria-describedby` for additional context | ✓ | Card variant sets `aria-describedby="{id}-content"` linking the input to the card content slot (`checkbox.ex:456`). |
| Group presentation | ✓ | When used in a form, native form semantics group inputs; no explicit `role="group"` needed for sibling checkboxes. |

### WAI-ARIA roles, states, properties (tri-state)

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `checkbox` | ✓ | Same as two-state. |
| `aria-checked="mixed"` when partially checked | ✓ | `checkbox.ex:397, 455` — emits `"mixed"` only when `@indeterminate` is true. |
| Visual indication of mixed state | ✓ | CSS `data-[indeterminate=true]:after:content-['−']` renders a dash via the custom `::after` checkmark (`checkbox.ex:126`). `appearance-none` (`checkbox.ex:116`) suppresses the native checkmark, so the data-attr selector drives the visual. |

### Divergences

None. ✓ Compliant.

**Note on DOM `indeterminate` property:** Pulsar does not set the
JavaScript `HTMLInputElement.indeterminate` property — it conveys the
state via `aria-checked="mixed"` and `data-indeterminate="true"` only.
APG only requires `aria-checked="mixed"`; the DOM property is needed
only when the native checkmark is in use (Pulsar suppresses it via
`appearance-none`). ✓ Not a gap.

---

## Switch — `switch.ex`

**Source:** [`lib/pulsar/components/switch.ex`](../../lib/pulsar/components/switch.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/switch/>

Implementation: hidden native `<input type="checkbox">` with
`role="switch"` (the focusable element) + a non-focusable visual track
button that dispatches click to the input.

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Space | Toggle | ✓ | Native checkbox browser-default. |
| Enter (optional) | Toggle | ✓ | Not implemented. APG explicitly marks Enter as **optional** for the switch pattern, and native checkbox does not toggle on Enter. Matching native behavior is APG-compliant. |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `switch` | ✓ | `role="switch"` on the hidden checkbox (`switch.ex:496`). |
| Accessible name | ✓ | `aria-label` (`switch.ex:498`) and `aria-labelledby` (`switch.ex:499`) attrs supported; field wrapper provides the labelledby ID. |
| `aria-checked` as boolean | ✓ | `switch.ex:497` — always emitted as `"true"` or `"false"`. |
| `aria-invalid` | ✓ | `switch.ex:500` — emitted when `@invalid` is true. |

### Visual track button

The visual track is a `<button type="button">` (`switch.ex:505`) with
`tabindex="-1"` (`switch.ex:507`) — **not focusable**, so it doesn't
create a dual-focus problem. Click dispatches to the hidden input via
`JS.dispatch("click", to: "##{@id}")` (`switch.ex:508`). ✓ Correct
pattern.

### Divergences

None. ✓ Compliant.

---

## Radio Group — `radio_group.ex`

**Source:** [`lib/pulsar/components/radio_group.ex`](../../lib/pulsar/components/radio_group.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/radio/>

Implementation: `<div role="radiogroup">` containing native
`<input type="radio">` elements, all sharing the same `name`. Arrow-key
navigation and roving-tabindex behavior come from native HTML's radio
grouping.

### Keyboard interactions (Non-Toolbar Radio Group)

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Tab / Shift+Tab | Move focus into / out of group (lands on checked, or first) | ✓ | Native HTML radio behavior — only the checked radio is in the tab sequence; if none checked, the first is. |
| Space | Check focused radio if not already checked | ✓ | Native checkbox/radio browser-default. |
| Right Arrow / Down Arrow | Move to next, uncheck previous, check new; wrap to first | ✓ | Native HTML radio behavior on grouped radios sharing the same `name` (`radio_group.ex:400, 455`). Browsers also wrap. |
| Left Arrow / Up Arrow | Move to previous, uncheck previous, check new; wrap to last | ✓ | Same as above. |
| Home | Move focus to first radio | ✓ | `.PulsarRadioGroup` hook intercepts Home, focuses and clicks the first non-disabled radio (`radio_group.ex` colocated hook). |
| End | Move focus to last radio | ✓ | Same hook, last non-disabled radio. |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `radiogroup` on container | ✓ | `radio_group.ex:327`. |
| Role: `radio` on each option | ✓ | Implicit on `<input type="radio">` (`radio_group.ex:398, 453`). |
| `aria-checked` on each radio | ✓ | Implicit from native `checked` attr (`radio_group.ex:402, 457`). |
| `aria-labelledby` on radiogroup container | ✓ | Explicit `aria_labelledby` attr on `radio_group/1` applies to the container in both variants. Field wrapper binds it to the field's label ID (`field.ex:448`). |
| `aria-required` on container | ✓ | `radio_group.ex:331`. |
| `aria-invalid` on container | ✓ | `radio_group.ex:330` (container) and on each radio (`radio_group.ex:405, 460`). |
| `aria-describedby` for descriptive text | ✓ | Card variant adds `aria-describedby="{id}-content"` on each radio input (`radio_group.ex:462`). |

#### `aria-label` / `aria-labelledby` on the container

Both attrs are exposed as explicit attrs on `radio_group/1`
(mirroring `switch.ex`). They apply to the single
`<div role="radiogroup">` container that wraps both default and
card variants, so the group's accessible name is always
attached to the radiogroup itself — never duplicated onto
individual option labels.

### Divergences

None. ✓ Compliant.

---

## Alert — `flash.ex`

**Source:** [`lib/pulsar/components/flash.ex`](../../lib/pulsar/components/flash.ex)
**APG pattern:** <https://www.w3.org/WAI/ARIA/apg/patterns/alert/>

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| *None required* | — | N/A | APG explicitly notes "the alert pattern does not require keyboard interaction." |

The dismiss button (when `dismissible=true`) is a regular native
`<button>` (`flash.ex:300–311`), keyboard-operable by default.

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `alert` (or `status`) | ✓ | `role={@role}` (`flash.ex:281`) — defaults to `"status"`, set to `"alert"` for urgent messages. |
| Announcement behavior | ✓ | `aria-live` auto-determined from role (`flash.ex:282`): `"assertive"` for alert, `"polite"` for status. Although `role="alert"` implies `aria-live="assertive"`, emitting both is APG-allowed (safer for legacy AT). |
| `aria-atomic` for whole-message announcement | ✓ | `aria-atomic="true"` (`flash.ex:283`). |
| Dismiss button accessible name | ✓ | `aria-label="Dismiss"` (`flash.ex:304`). |
| Dismiss button → content linkage | ✓ | `aria-controls={@id}` (`flash.ex:305`). |

### Divergences

None. ✓ Compliant.

**Bonus:** Pulsar's flash hook pauses the auto-dismiss timer on
hover (`flash.ex:390–391`) **and** on focus (`flash.ex:392–393`),
giving keyboard users and slow readers time to consume the message.
This isn't in APG but is widely recommended.

---

## Table row-click — `table.ex` (button pattern on `<tr>`)

**Source:** [`lib/pulsar/components/table.ex`](../../lib/pulsar/components/table.ex)
**APG pattern:** [Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) applied to a table row.

When the caller provides `row_click`, each `<tr>` gets
`role="button"`, `tabindex="0"`, and the `.PulsarTableRow` hook
handles keyboard activation. APG doesn't define a "clickable row"
pattern explicitly; the Button pattern is the closest fit and is
widely used by Phoenix and React table libraries for this purpose.

### Keyboard interactions

| APG key | Action | Status | Evidence |
|---------|--------|:------:|----------|
| Enter | Activate | ✓ | Hook calls `el.click()` on keydown (`table.ex:474–476`). |
| Space | Activate | ✓ | Hook calls `el.click()` on **keyup**, matching `button.ex`'s pseudo-button hook. Keydown is reserved for `preventDefault()` (prevent scroll) and the disabled/busy short-circuit. |

### WAI-ARIA roles, states, properties

| APG requirement | Status | Evidence |
|-----------------|:------:|----------|
| Role: `button` | ✓ | `role="button"` on clickable `<tr>` (`table.ex:418`). |
| Accessible name | ✓ | Computed from cell text content; callers can override via `{@rest}` (`table.ex:285`). |
| Focusable | ✓ | `tabindex="0"` (`table.ex:417`). |
| `aria-disabled` / `aria-busy` honored | ✓ | Hook's `isDisabledOrBusy()` short-circuits keydown, keyup, and click when the `<tr>` carries either attr. Callers can set these via `{@rest}` on the row. |

### Divergences

None. ✓ Compliant.

---

## Notes on out-of-scope components

For completeness, here's why the 11 non-audited components aren't
APG-pattern-matched:

- **Form leaves** (`input`, `textarea`, `select`) — use native HTML
  elements. APG doesn't prescribe patterns for native form controls;
  HTML semantics + AT-default behavior is the expected approach.
- **Form wrappers** (`field`, `label`) — label/error association is a
  WCAG concern (1.3.1, 3.3.1) handled in the WCAG audit; no APG widget
  pattern applies.
- **Structural** (`card`, `divider`, `header`, `list`, `flash_group`,
  `table` itself without row_click) — non-interactive; APG only
  covers interactive widget patterns.
- **Content** (`badge`, `icon`) — non-interactive presentational
  components.

If any of these become interactive in the future (e.g., card with
expand-collapse, list with selectable items), they would need to be
added to this audit and mapped to the relevant APG pattern (Disclosure,
Listbox, etc.).

---

**Audited:** 2026-05-24 (code-only)
**Companion audit:** [WCAG 2.2 AA](README.md)
