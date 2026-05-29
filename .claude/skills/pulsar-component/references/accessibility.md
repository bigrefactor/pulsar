# Accessibility: WCAG 2.2 AA

Pulsar's published target is **WCAG 2.2 AA, built in by default**. A new component
isn't done until (a) its a11y is correct in code, (b) it passes the axe browser
gate, and (c) it has a per-criterion audit doc. Read `docs/a11y/README.md` for the
project's audit methodology and the criteria grid before writing the doc.

## Get the semantics right in code

Driven by the component's **WAI-ARIA APG pattern** (decided in brainstorming):

- **Roles/states/properties** — native element first (`<button>`, `<input>`,
  `<a>`). Add ARIA only to fill gaps the native element can't express. For custom
  widgets, follow the APG pattern's required roles and state attributes exactly.
- **Don't fake roles on the wrong element.** Only put a role on an element that
  actually behaves that way. A `<span>`/`<div>` that wraps content but has no
  click/key handler must NOT carry `role="button"` (or `link`, `checkbox`, …) —
  that lies to AT and demands keyboard behavior you haven't implemented. If
  something is genuinely a button, render a `<button>`. A non-interactive wrapper
  (tooltip trigger container, badge, card shell) stays role-free.
- **Accessible name: supply it once, never double up.** Decide the *single* source
  of the name and don't add a second. The classic bug: a wrapper carries
  `role="img"` + `aria-label={name}` *while also* containing a native `<img alt>`
  — now the image is announced twice and a native img-role is nested in an
  img-role container. Gate the wrapper role/label on the branch where the native
  name is ABSENT (e.g. `:if={is_nil(@src)}`). Same rule for any component whose
  name can come from a native child (img `alt`, button text, `<a>` text): if the
  child names it, the wrapper says nothing.
- **Form inputs route through `Field`** — `lib/pulsar/components/field.ex` owns
  `<label>` association, error text, `aria-describedby`, `aria-labelledby`, and
  `aria-invalid`. Don't duplicate that wiring on the leaf input; read field.ex and
  plug into its contract.
- **Focus visible** — `focus-visible:outline-none focus-visible:ring-2
  focus-visible:ring-offset-2` (or `focus-within:` for wrappers around a focusable
  child).
- **Color is never the only signal** — pair every color/status with text or an
  icon; make required content (`inner_block`) `required: true` when the meaning
  depends on it.
- **Contrast** — semantic tokens generally pass, but success/warning foreground
  shades have historically undershot 4.5:1 in light mode. Don't assume; the axe
  gate and the audit's measurement step verify it.

## Keyboard (interactive components only)

If the APG pattern defines key behavior (Enter/Space activation, arrow
navigation, Escape, Home/End), you must:

1. Implement it (native element behavior, or `Phoenix.LiveView.JS` /
   colocated hook — no external JS).
2. Add a keyboard fixture + route + a `describe` block in
   `test/integration/a11y/keyboard_test.exs` exercising each key. See
   `registries.md` §F and the existing Button/Card/RadioGroup/Select/Checkbox/
   Switch blocks for the `visit |> await_live_connected |> press |> assert_has`
   pattern.

## The axe browser gate

`test/integration/a11y/axe_clean_test.exs` auto-discovers fixtures from
`Components.fixtures()` and runs axe-core against each in **light and dark**. You
don't write a test — you add the fixture (see `testing.md` §3 and `registries.md`
§D). Run it with `mix test --only integration`.

This gate is **brittle by nature** (Playwright cold-start, worker-pool starvation
with `--max-cases`, per-page mount budget). If it flakes or times out, read the
project note on its three levers (`--max-cases`, the Playwright timeout in
`config/test.exs`, and variant-splitting heavy fixtures) before changing config.
**Never make the gate pass by loosening the axe assertion** — fix the fixture or
the component.

## The audit doc — `docs/a11y/widget.md`

Mirror `docs/a11y/badge.md` exactly. Required shape:

```markdown
# Widget · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/widget.ex`](../../lib/pulsar/components/widget.ex)
**Tests:** [`test/pulsar/components/widget_test.exs`](../../test/pulsar/components/widget_test.exs)
**Audited:** YYYY-MM-DD (code-only)

<one-paragraph description of the component and what element it renders>

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** <what in the code satisfies it> — `lib/pulsar/components/widget.ex:NN`.

**Notes:** <reasoning>

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious)

**Evidence:** <token source + browser measurement summary> — `...:NN–NN`.

**Notes:** <root cause; what's affected>

<...one entry per APPLICABLE A/AA criterion, PASS or GAP...>

## Not applicable

- **1.2.1 Audio-only ... (A)** — no media.
- **2.1.1 Keyboard (A)** — non-interactive wrapper.
<...every criterion that doesn't apply, with a one-line reason...>

## AAA wins (bonus)
<optional: any AAA criteria the component happens to meet>

## Browser a11y findings
<table of any axe violations by variant/theme, if any remain>
```

### Doc rules

- **Every applicable WCAG 2.2 Level A and AA criterion** gets an entry: status
  `✓ PASS`, `⚠ GAP`, or routed to "Not applicable" with a reason. Use the
  criteria list in `docs/a11y/README.md` as the master checklist so none are
  missed.
- **Evidence cites `file:line`** in source or tests — concrete, not hand-wavy.
- **GAPs are tagged by severity** (`blocker` / `serious` / `minor`), e.g.
  `⚠ GAP (serious)`. **Never** put a Linear ticket id (PUL-XX) or linear.app link
  in the doc — or anywhere in `lib/`, `priv/`, `docs/`. Gaps hand off to tickets
  separately (use the `ticket-breakdown` skill if there are several).
- **If a measurement contradicts the AA claim, remeasure** — the AA target is the
  published commitment; a stale audit number is what's wrong, not the claim.
  Don't downgrade the claim to match a bad reading.
- Update the criteria-grid rows for the new component in `docs/a11y/README.md` so
  the master grid stays complete.
