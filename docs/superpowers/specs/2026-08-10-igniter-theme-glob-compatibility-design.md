# Igniter Theme Glob Compatibility Design

## Problem

The theme generator's regression test for preserving a scaffolded custom theme fails with the current dependency set.
After `cupcake.css` is scaffolded, it remains in `Igniter.Test`'s in-memory file map, but the next default generator run
does not discover it and therefore does not restore its import after overwriting `theme.css`.

`reregister_custom_themes/1` passes the relative glob `assets/css/themes/*.css` to `Igniter.include_glob/2`. In test
mode, the current Igniter/GlobEx combination expands each fixture path to an absolute path before matching it against
that relative glob. The match fails and no custom theme enters `rewrite.sources`.

Production uses a different `Rewrite.read!/2` path and must keep the relative glob: an absolute string makes Rewrite
store absolute source keys, which the generator's relative `assets/css/themes/` filtering rejects. The two Igniter
paths therefore need different glob forms while preserving the same relative source-key contract downstream.

## Decision

Keep the current dependency versions. Define the canonical relative glob as `assets/css/themes/*.css`. When
`igniter.assigns[:test_mode?]` is true, expand that glob before passing it to `Igniter.include_glob/2`; otherwise pass
the relative glob unchanged.

The absolute test-mode glob matches Igniter's absolute fixture paths. The relative production glob keeps Rewrite's
source keys relative, so the existing custom-theme filter and import registration continue to operate unchanged.

## Scope

- Modify only custom-theme glob selection in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Retain the existing test at `test/mix/tasks/pulsar.gen.theme_test.exs` as the regression gate.
- Add a filesystem-backed regression test that exercises Igniter outside test mode and proves an existing custom theme
  is rediscovered and re-imported.
- Do not alter dependency versions, preload the in-memory fixture manually, or change theme registration semantics.
- Do not add a changelog entry because the change restores existing intended behavior after a dependency update and
  does not change Pulsar's public contract.

## Verification

Use the existing failing in-memory test as the first TDD red case. Add a filesystem-backed test that runs the task in a
temporary project without `test_mode?`; verify that it fails against an unconditional absolute-glob implementation and
passes with conditional glob selection. Then run the complete `pulsar.gen.theme` test file, formatting, and whitespace
checks.

Success means the custom theme is discovered and re-imported after the default theme files are overwritten, with no
other generator-test regressions.

## Compatibility and Failure Modes

The generator continues to evaluate the production glob from the current project directory, matching its existing
relative destination paths. Accessing the established `:test_mode?` test-harness assign introduces no new production
error path because a missing key evaluates to `nil`. If Igniter changes either discovery path again, the paired
in-memory and filesystem-backed tests will fail at the discovery boundary instead of silently allowing custom themes
to become unregistered.
