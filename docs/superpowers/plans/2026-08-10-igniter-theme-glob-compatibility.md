# Igniter Theme Glob Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore Igniter.Test relative-glob reload behavior and custom-theme discovery without changing Pulsar's public generator semantics.

**Architecture:** Pin GlobEx to the last known-compatible release for Pulsar's development/test toolchain, then restore the ordinary relative glob in the production theme generator. Validate the dependency correction once against both independently failing in-memory generator paths; use a localized test-helper fallback only if the pin does not restore them.

**Tech Stack:** Elixir, ExUnit, Igniter 0.8.3, GlobEx 0.1.11

## Global Constraints

- Prefer exact `GlobEx 0.1.11` as a direct development/test dependency; do not downgrade Igniter.
- Restore the relative custom-theme glob in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Keep the existing in-memory and filesystem-backed custom-theme tests.
- Run one quick pin validation. If it fails at the same rewrite-reload boundary, revert the pin attempt and use the localized `source_content/2` fallback instead; never ship both.
- Do not preload fixtures or change theme registration semantics.
- Do not add a changelog entry; this corrects the repository's test/build dependency compatibility.

---

### Task 1: Correct the Igniter.Test dependency boundary

**Files:**
- Modify: `mix.exs:110-125`
- Modify: `mix.lock:22`
- Modify: `lib/mix/tasks/pulsar.gen.theme.ex:148-152`
- Preserve: `test/mix/tasks/pulsar.gen.theme_test.exs:253-295`
- Fallback only if pin validation fails: `test/support/generator_test_helpers.ex:34-39`

**Interfaces:**
- Consumes: Igniter 0.8.3's `Igniter.Test.apply_igniter!/1`, which reloads fixture files through GlobEx; Pulsar's relative `assets/css/themes/*.css` production glob.
- Produces: Populated `rewrite.sources` after Igniter test writes and unchanged relative source keys during real filesystem discovery.

- [ ] **Step 1: Confirm both current regression boundaries**

Run:

```bash
mix test test/pulsar/generator_test.exs:100 --seed 652238
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
```

Expected before correction: the shared generator test fails because `source_content/2` cannot find the generated button after `apply_igniter!/1`; the theme test passes only because the current branch carries a theme-specific `:test_mode?` workaround.

- [ ] **Step 2: Add the exact development/test GlobEx dependency**

In `mix.exs`, directly after the `phx_new` test dependency, add:

```elixir
{:glob_ex, "0.1.11", only: [:dev, :test], runtime: false},
```

Run:

```bash
mix deps.update glob_ex
```

Expected: `mix.lock` changes GlobEx from 0.1.12 to 0.1.11 and leaves Igniter at 0.8.3.

- [ ] **Step 3: Restore the ordinary relative theme glob**

Replace the three-line conditional glob selection in `reregister_custom_themes/1` with:

```elixir
igniter = Igniter.include_glob(igniter, "assets/css/themes/*.css")
```

Do not change downstream path filtering or import registration.

- [ ] **Step 4: Perform the one-pass pin validation**

Run:

```bash
mix test test/pulsar/generator_test.exs:100 --seed 652238
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
mix test test/mix/tasks/pulsar.gen.theme_test.exs --only tmp_dir --seed 0
```

Expected preferred result: all three commands pass. If so, skip Step 5 entirely.

If the shared generator or in-memory theme test still fails because `rewrite.sources` is empty after an Igniter test write, immediately revert only the attempted `mix.exs`, `mix.lock`, and theme-glob edits, then perform Step 5. Do not try another dependency version.

- [ ] **Step 5: Fallback only if Step 4 fails — localize test-file lookup**

Leave the original locked dependencies and theme-specific conditional glob unchanged. Replace `source_content/2` in `test/support/generator_test_helpers.ex` with:

```elixir
def source_content(igniter, path) do
  case Map.fetch(igniter.rewrite.sources, path) do
    {:ok, source} ->
      Rewrite.Source.get(source, :content)

    :error ->
      assert {:ok, content} = Map.fetch(igniter.assigns[:test_files] || %{}, path),
             "expected generated file #{path} in the igniter rewrite or test file map"

      content
  end
end
```

Run the three Step 4 commands again. Expected fallback result: all pass. Do not retain the dependency pin when using this fallback.

- [ ] **Step 6: Run complete neighboring generator tests**

Run:

```bash
mix test test/pulsar/generator_test.exs test/mix/tasks/pulsar.gen.theme_test.exs test/pulsar/theme/background_token_contract_test.exs test/pulsar/theme/color_scheme_test.exs
```

Expected: all tests pass with 0 failures.

- [ ] **Step 7: Verify formatting, dependency state, and template drift**

Run:

```bash
mix format --check-formatted
mix deps.unlock --check-unused
mix pulsar.sync --check
git diff --check
```

Expected: every command exits 0; `git diff` contains either the dependency-pin route or the localized fallback route, never both.

- [ ] **Step 8: Commit the compatibility correction**

Preferred pin route:

```bash
git add mix.exs mix.lock lib/mix/tasks/pulsar.gen.theme.ex
git commit -m "Pin GlobEx for Igniter test compatibility"
```

Fallback route:

```bash
git add test/support/generator_test_helpers.ex
git commit -m "Read applied Igniter test files from fixture state"
```

- [ ] **Step 9: Run the full repository gate**

Run:

```bash
mix check
```

Expected: compilation, template drift, formatting, Credo, Dialyzer, dependency audit, and all ExUnit tests pass.
