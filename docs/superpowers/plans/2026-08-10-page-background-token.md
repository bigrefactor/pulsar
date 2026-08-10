# Page Background Token Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `--color-background` the unambiguous application/page ground and keep `--color-surface-0` as the independent base of the surface elevation scale.

**Architecture:** Treat the shipped EEx theme templates as the public source of truth, and guard their semantic wording with a focused source-level ExUnit test. Align the repository's development Storybook sandbox with that contract, while leaving every token name and built-in value unchanged.

**Tech Stack:** Elixir, ExUnit, CSS, EEx templates, Phoenix Storybook development fixture

## Global Constraints

- `--color-background` is the application/page ground; applications should apply it to `<body>`.
- `--color-surface-0` is an independently customizable base in the surface elevation scale, not the page ground.
- Do not remove, alias, or change the built-in value of either token.
- Do not edit generated component modules under `lib/pulsar/components/`.
- Preserve WCAG 2.2 AA behavior; the default rendering must remain visually unchanged.
- Preserve the existing untracked `AGENTS.md` and any unrelated worktree changes.

---

### Task 1: Document and test the public token contract

**Files:**
- Create: `test/pulsar/theme/background_token_contract_test.exs`
- Modify: `priv/templates/theme.css.eex:3-22`
- Modify: `priv/templates/themes/light.css.eex:30`
- Modify: `priv/templates/themes/dark.css.eex:27`

**Interfaces:**
- Consumes: The public token declarations and comments in the three theme EEx templates.
- Produces: A documented contract in which `--color-background` grounds `<body>` and `--color-surface-0` is the base elevation surface; an ExUnit regression test guarding those roles.

- [ ] **Step 1: Write the failing contract test**

Create `test/pulsar/theme/background_token_contract_test.exs`:

```elixir
defmodule Pulsar.Theme.BackgroundTokenContractTest do
  use ExUnit.Case, async: true

  @entry Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @light Path.expand("../../../priv/templates/themes/light.css.eex", __DIR__)
  @dark Path.expand("../../../priv/templates/themes/dark.css.eex", __DIR__)

  test "documents --color-background as the body page ground" do
    css = File.read!(@entry)

    assert css =~ "`--color-background` is the application/page ground"
    assert css =~ "apply `bg-background` to `<body>`"
  end

  test "documents --color-surface-0 as the base elevation surface" do
    for template <- [@light, @dark] do
      css = File.read!(template)

      assert css =~ ~r/--color-surface-0:[^;]+;\s*\/\* Base elevation surface \*\//
      refute css =~ "Canvas/page background"
    end
  end
end
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
mix test test/pulsar/theme/background_token_contract_test.exs
```

Expected: FAIL because the entry template lacks the new page-ground guidance and both built-in theme templates still call `--color-surface-0` the canvas/page background.

- [ ] **Step 3: Add the explicit contract to the theme entry template**

In the header comment of `priv/templates/theme.css.eex`, after the two-tier model and before “To add a theme,” add:

```css
  Page and surface roles:

  - `--color-background` is the application/page ground. Apply `bg-background`
    to `<body>` (or use `background-color: var(--color-background)`).
  - `--color-surface-0` is the independently customizable base of the surface
    elevation scale used by `--color-surface-1`, `--color-surface-2`, and
    `--color-surface-3`; it is not the page ground.
```

- [ ] **Step 4: Correct the surface comments in both built-in themes**

In `priv/templates/themes/light.css.eex`, change only the inline comment:

```css
  --color-surface-0: var(--color-white);     /* Base elevation surface */
```

In `priv/templates/themes/dark.css.eex`, change only the inline comment:

```css
  --color-surface-0: var(--color-gray-950);  /* Base elevation surface */
```

Do not change the repeated uncommented light selector block or any token values.

- [ ] **Step 5: Run the focused test to verify it passes**

Run:

```bash
mix test test/pulsar/theme/background_token_contract_test.exs
```

Expected: 2 tests, 0 failures.

- [ ] **Step 6: Format and commit the public contract**

Run:

```bash
mix format test/pulsar/theme/background_token_contract_test.exs
git diff --check
git add test/pulsar/theme/background_token_contract_test.exs priv/templates/theme.css.eex priv/templates/themes/light.css.eex priv/templates/themes/dark.css.eex
git commit -m "Clarify the page background token contract"
```

Expected: formatting and whitespace checks pass; the commit contains only the test and three canonical templates.

---

### Task 2: Align the development consumer and release notes

**Files:**
- Modify: `test/pulsar/theme/background_token_contract_test.exs`
- Modify: `test/support/dev_app/assets/css/app.css:27-31`
- Modify: `CHANGELOG.md:8`
- Regenerate for local verification only: `test/support/dev_app/assets/css/theme.css`
- Regenerate for local verification only: `test/support/dev_app/assets/css/themes/light.css`
- Regenerate for local verification only: `test/support/dev_app/assets/css/themes/dark.css`

**Interfaces:**
- Consumes: The token contract established in Task 1 and the `.pulsar-sandbox` development-app CSS rule.
- Produces: A canonical in-repository consumer of `--color-background`, release guidance for theme authors, and a regression assertion preventing the example from reverting to `--color-surface-0`.

- [ ] **Step 1: Add a failing sandbox-consumer assertion**

Extend `test/pulsar/theme/background_token_contract_test.exs` with the module attribute and test below:

```elixir
  @dev_app_css Path.expand("../../support/dev_app/assets/css/app.css", __DIR__)

  test "the development sandbox uses the page ground token" do
    css = File.read!(@dev_app_css)

    assert css =~
             ~r/\.pulsar-sandbox\s*\{[^}]*background-color:\s*var\(--color-background\);/s

    refute css =~
             ~r/\.pulsar-sandbox\s*\{[^}]*background-color:\s*var\(--color-surface-0\);/s
  end
```

- [ ] **Step 2: Run the focused test to verify the new assertion fails**

Run:

```bash
mix test test/pulsar/theme/background_token_contract_test.exs
```

Expected: 1 failure in “the development sandbox uses the page ground token,” showing that `.pulsar-sandbox` still consumes `--color-surface-0`.

- [ ] **Step 3: Align the development sandbox**

In `test/support/dev_app/assets/css/app.css`, change the `.pulsar-sandbox` rule to:

```css
.pulsar-sandbox {
  font-family: var(--font-sans);
  color: var(--color-foreground);
  background-color: var(--color-background);
}
```

- [ ] **Step 4: Add the Unreleased changelog entry**

Immediately below `## [Unreleased]` in `CHANGELOG.md`, add:

```markdown
### Fixed - Page Background Token Documentation

- **`--color-background` is now explicitly documented as the application/page ground**: apply `bg-background` to `<body>`. `--color-surface-0` remains independently customizable as the base of the surface elevation scale and is no longer described as the canvas/page background. Pulsar's development Storybook sandbox now demonstrates the same contract. Token names, built-in values, and default rendering are unchanged.
```

- [ ] **Step 5: Synchronize theme fixtures and verify generated-source drift**

Run:

```bash
mix pulsar.dev_app.theme
mix pulsar.sync --check
```

Expected: the dev-app theme copies are regenerated from the corrected EEx comments, and `mix pulsar.sync --check` reports that generated component and Storybook files are in sync. The regenerated theme copies are ignored local verification artifacts and must not be force-added.

- [ ] **Step 6: Run focused and neighboring theme tests**

Run:

```bash
mix test test/pulsar/theme/background_token_contract_test.exs test/pulsar/theme/color_scheme_test.exs test/mix/tasks/pulsar.gen.theme_test.exs
```

Expected: all tests pass with 0 failures.

- [ ] **Step 7: Run formatting and repository checks**

Run:

```bash
mix format --check-formatted
git diff --check
mix pulsar.sync --check
```

Expected: all commands exit 0. Inspect `git status --short` and confirm that only the intended tracked files are modified; leave the user's untracked `AGENTS.md` untouched.

- [ ] **Step 8: Commit the aligned consumer and release note**

Run:

```bash
git add test/pulsar/theme/background_token_contract_test.exs test/support/dev_app/assets/css/app.css CHANGELOG.md
git commit -m "Align the dev sandbox with the page background token"
```

Expected: the commit contains only the expanded contract test, the dev sandbox consumer, and the changelog entry.

- [ ] **Step 9: Perform final verification**

Run:

```bash
mix test test/pulsar/theme/background_token_contract_test.exs test/pulsar/theme/color_scheme_test.exs test/mix/tasks/pulsar.gen.theme_test.exs
mix pulsar.sync --check
mix format --check-formatted
git diff --check
git status --short --branch
```

Expected: tests and checks exit 0; the branch is clean except for the pre-existing untracked `AGENTS.md`.
