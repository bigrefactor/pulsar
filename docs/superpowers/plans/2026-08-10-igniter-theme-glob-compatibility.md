# Igniter Theme Glob Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore custom-theme discovery in the theme generator's current Igniter test environment without changing dependency versions or public behavior.

**Architecture:** Keep a canonical relative custom-theme glob for real filesystem discovery, but expand it when Igniter's `:test_mode?` assign is active so its in-memory fixture matcher compares absolute paths on both sides. Guard both branches with the existing in-memory regression and a new filesystem-backed regression, then verify the complete theme-generator test file.

**Tech Stack:** Elixir, ExUnit, Igniter 0.8.3, GlobEx 0.1.12

## Global Constraints

- Keep the current dependency versions.
- Modify only custom-theme glob selection in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Retain the existing test at `test/mix/tasks/pulsar.gen.theme_test.exs` as the regression gate.
- Add a filesystem-backed regression test that exercises Igniter outside test mode.
- Do not preload the in-memory custom-theme fixture or change theme registration semantics.
- Do not add a changelog entry; this restores existing intended behavior and does not change Pulsar's public contract.

---

### Task 1: Make custom-theme discovery path-compatible

**Files:**
- Modify: `lib/mix/tasks/pulsar.gen.theme.ex:148-150`
- Modify: `test/mix/tasks/pulsar.gen.theme_test.exs:253-285`

**Interfaces:**
- Consumes: `Igniter.include_glob/2`, which receives an `Igniter.t()` and a glob path.
- Produces: `reregister_custom_themes/1` supplies an absolute glob only in Igniter test mode and preserves a relative glob for production source keys; paired tests cover both branches.

- [ ] **Step 1: Record the existing in-memory regression as green under the rejected unconditional fix**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
```

Expected: 1 test, 0 failures with the current unconditional `Path.expand/1` implementation. The implementer report already contains the original red evidence from the relative-glob implementation; do not revert merely to reproduce it.

- [ ] **Step 2: Add a filesystem-backed regression test that fails under the unconditional absolute glob**

Add this test beside the existing custom-theme re-registration test in `test/mix/tasks/pulsar.gen.theme_test.exs`:

```elixir
@tag :tmp_dir
test "re-registers a custom theme from the real filesystem", %{tmp_dir: tmp_dir} do
  seeded =
    phx_test_project()
    |> Igniter.compose_task("pulsar.gen.theme", [])
    |> apply_igniter!()
    |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])
    |> apply_igniter!()

  for {path, content} <- seeded.assigns.test_files do
    target = Path.join(tmp_dir, path)
    File.mkdir_p!(Path.dirname(target))
    File.write!(target, content)
  end

  igniter =
    File.cd!(tmp_dir, fn ->
      Igniter.new()
      |> Igniter.compose_task("pulsar.gen.theme", [])
    end)

  content = source_content(igniter, "assets/css/theme.css")

  assert has_import_line?(content, ~s(@import "./themes/cupcake.css";))
end
```

This test writes the already-generated project fixture to ExUnit's temporary directory, constructs a fresh `Igniter` without `:test_mode?`, and composes the default theme task from that project directory.

- [ ] **Step 3: Run the filesystem-backed test to verify it fails**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs --only tmp_dir --seed 0
```

Expected: 1 failure because the unconditional absolute glob leaves absolute Rewrite source keys, which `custom_theme_file?/1` rejects.

- [ ] **Step 4: Implement conditional glob selection**

Replace the unconditional custom-theme glob call in `reregister_custom_themes/1` with:

```elixir
glob = "assets/css/themes/*.css"
glob = if igniter.assigns[:test_mode?], do: Path.expand(glob), else: glob
igniter = Igniter.include_glob(igniter, glob)
```

Do not change the downstream source-key filtering or import-registration logic.

- [ ] **Step 5: Verify both discovery paths are green**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs:253 --seed 0
mix test test/mix/tasks/pulsar.gen.theme_test.exs --only tmp_dir --seed 0
```

Expected: both commands pass with 0 failures.

- [ ] **Step 6: Run the complete theme-generator test file**

Run:

```bash
mix test test/mix/tasks/pulsar.gen.theme_test.exs
```

Expected: 27 tests, 0 failures.

- [ ] **Step 7: Verify formatting and whitespace**

Run:

```bash
mix format --check-formatted lib/mix/tasks/pulsar.gen.theme.ex test/mix/tasks/pulsar.gen.theme_test.exs
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 8: Commit the corrected compatibility fix**

Run:

```bash
git add lib/mix/tasks/pulsar.gen.theme.ex test/mix/tasks/pulsar.gen.theme_test.exs
git commit -m "Cover custom theme discovery on the filesystem"
```

Expected: the commit replaces unconditional expansion with conditional glob selection and adds the filesystem regression test.

- [ ] **Step 9: Re-run the original baseline selection**

Run:

```bash
mix test test/pulsar/theme/color_scheme_test.exs test/mix/tasks/pulsar.gen.theme_test.exs
```

Expected: 33 tests, 0 failures; the optional built-CSS assertion may print its existing skip message when assets have not been built.
