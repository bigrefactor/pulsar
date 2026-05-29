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

### Templates are the source of truth

Every component exists in two places, but only one is edited by hand:

- its EEx template under `priv/templates/*.ex.eex` — **the source of truth**
  (what gets generated into user apps), and
- the source module under `lib/pulsar/components/*.ex` (or
  `lib/pulsar/core_components.ex`) — **generated** from that template and
  committed so the library compiles and is directly importable.

Edit the template, then run `mix pulsar.sync` to regenerate the lib file — never
hand-edit the generated `lib/pulsar/components/*.ex`. `mix pulsar.sync --check`
(wired into the `check`/`check.ci` aliases and CI) fails the build if a committed
lib file has drifted from its template, so a forgotten regen is caught.

The component → lib-file mapping lives in `Pulsar.TemplateSync.pairs/0`; register
a new component there.

## Adding a new component

A new component is never just one file. It needs an EEx template (the source of
truth), a `Pulsar.TemplateSync.pairs/0` entry (then `mix pulsar.sync` to emit the
lib module), a generator task, install/sync registrations, unit tests, a storybook
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
