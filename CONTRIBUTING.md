# Contributing to Pulsar

Thanks for your interest! First, please read this honestly:

> ⚠️ **Pulsar is early stage and a work in progress.** APIs are unstable and
> will change without notice, components are incomplete, and there is no
> stability or support guarantee. Contributions are welcome, but expect the
> ground to shift under you — code you build on today may be reshaped tomorrow,
> and reviews/merges may be slow.

If that's fine with you, here's how to help.

## Getting set up

```bash
mix deps.get      # install dependencies (only Twm + Phoenix LiveView)
mix test          # run the full test suite
mix credo --strict
mix format        # always run before pushing
```

Please run `mix format` and make sure `mix test` and `mix credo --strict` pass
before opening a pull request.

## How Pulsar is structured

Pulsar is **generator-first**: components are *copied into* user applications by
the `mix pulsar.install` / `mix pulsar.gen.*` tasks rather than imported as a
shared runtime. There is no shared helper layer — each component is
self-contained so the generated code stands on its own in the user's app.

### The template-sync contract (important)

Every component exists in two places that must stay identical:

- the source module under `lib/pulsar/components/*.ex`, and
- its EEx template under `priv/templates/*.ex.eex` (what gets generated into
  user apps).

If you edit one, you **must** mirror the change in the other. `Pulsar.TemplateSyncTest`
fails the build on drift, so this isn't optional — the suite will catch it.

## Adding a new component

A new component is never just one file. It needs a source module, a synced EEx
template, a generator task, install/sync registrations, unit tests, a storybook
story (+ template), an accessibility fixture LiveView, and a WCAG 2.2 AA audit
doc. See `CLAUDE.md` for the full architecture before starting.

## Accessibility

Pulsar targets WCAG 2.2 AA. Interactive components are expected to ship with
proper ARIA semantics, keyboard support, and a per-component audit under
`docs/a11y/`. Don't regress existing accessibility behavior.

## Pull requests

- Keep PRs focused — one logical change per PR.
- Include tests for new behavior.
- Note any breaking change explicitly in the description.
- Update `CHANGELOG.md` (the `Unreleased` section) when your change is
  user-visible.

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
