# Igniter Theme Glob Compatibility Design

## Problem

The theme generator's regression test for preserving a scaffolded custom theme fails with the current dependency set.
After `cupcake.css` is scaffolded, it remains in `Igniter.Test`'s in-memory file map, but the next default generator run
does not discover it and therefore does not restore its import after overwriting `theme.css`.

`reregister_custom_themes/1` passes the relative glob `assets/css/themes/*.css` to `Igniter.include_glob/2`. In test
mode, the current Igniter/GlobEx combination expands each fixture path to an absolute path before matching it against
that relative glob. The match fails and no custom theme enters `rewrite.sources`. Production uses a different
`Rewrite.read!/2` path, but Pulsar can make both modes unambiguous by supplying an absolute glob.

## Decision

Keep the current dependency versions. Change the generator to call `Igniter.include_glob/2` with
`Path.expand("assets/css/themes/*.css")`.

Igniter explicitly normalizes an absolute compiled glob for its production path, while its test-mode branch then
matches absolute fixture paths against an absolute glob. This preserves the generator's intended behavior and keeps
the existing regression test meaningful.

## Scope

- Modify only the custom-theme discovery call in `lib/mix/tasks/pulsar.gen.theme.ex`.
- Retain the existing test at `test/mix/tasks/pulsar.gen.theme_test.exs` as the regression gate.
- Do not alter dependency versions, preload the fixture manually, or change theme registration semantics.
- Do not add a changelog entry because the change restores existing intended behavior after a dependency update and
  does not change Pulsar's public contract.

## Verification

Use the existing failing test as the TDD red case. After changing the glob, run that single test and then the complete
`pulsar.gen.theme` test file. Finally run formatting and whitespace checks.

Success means the custom theme is discovered and re-imported after the default theme files are overwritten, with no
other generator-test regressions.

## Compatibility and Failure Modes

The absolute glob is evaluated from the generator's current project directory, which is the same base already assumed
by the relative destination paths throughout the task. No new runtime error path is introduced. If Igniter changes its
glob normalization again, the existing regression test will fail at the discovery boundary instead of silently
allowing custom themes to become unregistered.
