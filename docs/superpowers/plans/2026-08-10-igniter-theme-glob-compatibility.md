# Igniter Theme Glob Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore custom-theme discovery in the theme generator's current Igniter test environment without changing dependency versions or public behavior.

**Architecture:** Supply an absolute custom-theme glob at Pulsar's `Igniter.include_glob/2` boundary. Keep the existing end-to-end generator regression test as the TDD red/green proof, then verify the complete theme-generator test file.

**Tech Stack:** Elixir, ExUnit, Igniter 0.8.3, GlobEx 0.1.12

## Global Constraints

- Keep the current dependency versions.
- Modify only the custom-theme discovery call in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Retain the existing test at `test/mix/tasks/pulsar.gen.theme_test.exs` as the regression gate.
- Do not preload the custom-theme fixture or change theme registration semantics.
- Do not add a changelog entry; this restores existing intended behavior and does not change Pulsar's public contract.

---

### Task 1: Make custom-theme discovery path-compatible

**Files:**
- Modify: `lib/mix/tasks/pulsar.gen.theme.ex:148-150`
- Test: `test/mix/tasks/pulsar.gen.theme_test.exs:253-270`

**Interfaces:**
- Consumes: `Igniter.include_glob/2`, which receives an `Igniter.t()` and a glob path.
- Produces: `reregister_custom_themes/1` supplies an absolute `assets/css/themes/*.css` glob so both Igniter's production and test-mode discovery paths find custom themes.

- [ ] **Step 1: Verify the existing regression test is red**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
```

Expected: 1 test, 1 failure. The failure says the cupcake theme should still be registered, while the rendered `theme.css` contains only the light and dark imports.

- [ ] **Step 2: Implement the minimal compatibility fix**

In `reregister_custom_themes/1`, replace the relative glob call with:

```elixir
igniter = Igniter.include_glob(igniter, Path.expand("assets/css/themes/*.css"))
```

Do not change any surrounding filtering or import-registration logic.

- [ ] **Step 3: Verify the regression test is green**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
```

Expected: 1 test, 0 failures.

- [ ] **Step 4: Run the complete theme-generator test file**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs
```

Expected: 26 tests, 0 failures.

- [ ] **Step 5: Verify formatting and whitespace**

Run:

```bash
mix format --check-formatted lib/mix/tasks/pulsar.gen.theme.ex test/mix/tasks/pulsar.gen.theme_test.exs
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 6: Commit the compatibility fix**

Run:

```bash
git add lib/mix/tasks/pulsar.gen.theme.ex
git commit -m "Fix custom theme discovery with current Igniter"
```

Expected: the commit changes only the relative glob expression to an absolute one.

- [ ] **Step 7: Re-run the original baseline selection**

Run:

```bash
mix test test/pulsar/theme/color_scheme_test.exs test/mix/tasks/pulsar.gen.theme_test.exs
```

Expected: 32 tests, 0 failures; the optional built-CSS assertion may print its existing skip message when assets have not been built.
