# Igniter Theme Glob Compatibility Design

## Problem

The theme generator's regression test for preserving a scaffolded custom theme fails with the current dependency set.
After `cupcake.css` is scaffolded, it remains in `Igniter.Test`'s in-memory file map, but the next default generator run
does not discover it and therefore does not restore its import after overwriting `theme.css`.

`reregister_custom_themes/1` passes the relative glob `assets/css/themes/*.css` to `Igniter.include_glob/2`. In test
mode, the current Igniter/GlobEx combination expands each fixture path to an absolute path before matching it against
that relative glob. The match fails and no custom theme enters `rewrite.sources`.

Production uses a different `Rewrite.read!/2` path and must keep the relative glob: an absolute string makes Rewrite
store absolute source keys, which the generator's relative `assets/css/themes/` filtering rejects.

The regression is broader than Pulsar's theme task. `Igniter.Test.apply_igniter!/1` itself reloads its in-memory files
with relative globs. With GlobEx 0.1.12 those reloads produce an empty `rewrite.sources`, even though the generated files
remain present in `igniter.assigns.test_files`. A theme-only conditional therefore leaves other generator tests broken.

## Decision

Pin GlobEx to the last known-compatible version, 0.1.11, as an exact direct development/test dependency while no newer
corrected release exists. Restore Pulsar's canonical relative `assets/css/themes/*.css` glob for every environment.

Validate the pin quickly against both the theme re-registration test and the independently failing shared generator
test. If the pin does not restore Igniter.Test's rewrite reload, stop pursuing the dependency route and add a localized
fallback to Pulsar's generator-test content helper that reads `igniter.assigns.test_files` only when the rewrite source
is absent. Do not combine both approaches.

## Scope

- Add exact `{:glob_ex, "0.1.11", only: [:dev, :test], runtime: false}` dependency metadata and update `mix.lock`.
- Restore the relative custom-theme discovery call in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Retain the existing test at `test/mix/tasks/pulsar.gen.theme_test.exs` as the regression gate.
- Add a filesystem-backed regression test that exercises Igniter outside test mode and proves an existing custom theme
  is rediscovered and re-imported.
- Do not preload the in-memory fixture or change theme registration semantics.
- Use the localized `source_content/2` fallback only if the one-pass GlobEx 0.1.11 validation fails.
- Do not add a changelog entry because the change restores existing intended behavior after a dependency update and
  does not change Pulsar's public contract.

## Verification

Use the existing failing shared-generator test as the red case for Igniter.Test's internal reload. Pin GlobEx 0.1.11,
restore the relative theme glob, fetch the locked dependency, and run the shared-generator and theme re-registration
tests once. If both pass, retain the pin and run the complete theme-generator and shared-generator files. If either
still fails at the same reload boundary, revert the dependency attempt and implement the localized test-helper fallback
instead. Then run the repository's full `mix check` gate.

Success means the custom theme is discovered and re-imported after the default theme files are overwritten, with no
other generator-test regressions.

## Compatibility and Failure Modes

The exact GlobEx pin applies only to Pulsar's development and test environments and is not shipped as a runtime
dependency to consumers. Production theme discovery keeps its original relative-path behavior. The pin should be
removed when an upstream GlobEx or Igniter release restores relative-glob matching in Igniter.Test. The existing
in-memory, filesystem-backed, and shared-generator tests guard both the original feature and the dependency boundary.
