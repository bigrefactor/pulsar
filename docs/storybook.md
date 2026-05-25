# Pulsar Storybook

This document is for **Pulsar contributors** who want to understand, extend, or maintain the built-in phoenix_storybook catalog that ships with the repository.

## What it is

Pulsar ships an in-repository [phoenix_storybook](https://hexdocs.pm/phoenix_storybook)
catalog that serves as both a visual development environment and a living
reference for every component. The catalog is part of the test-support
infrastructure (`test/support/dev_app/`) and runs against the live Pulsar
source — no generation step required.

## Running locally

Start the dev app:

    mix dev_app.server

Then open [http://localhost:4002/storybook](http://localhost:4002/storybook).

The storybook recompiles story files on every request in development mode,
so changes to story files appear immediately on the next browser refresh.

### Do not run `mix dev.storybook`

`phoenix_storybook` ships a `mix dev.storybook` task that gets exposed as a
top-level Mix task once the dep is fetched. It is **not** for Pulsar
contributors. The task assumes a PSB git checkout with source `assets/` and
runs `npm ci` / `mix assets.build` against the dep — both fail because the
hex package strips `assets/` from its tarball (only `priv/`, `lib`, `guides`,
etc. are published) and ships prebuilt JS/CSS under `priv/static/`.

For Pulsar, `mix dev_app.server` is the only command you need. PSB's
prebuilt assets are served directly from the hex package; no extra build
step is required.

## Story types

The catalog is organized into four sections:

| Section | Directory | Description |
|---------|-----------|-------------|
| Welcome | `test/support/dev_app/storybook/` | Single landing page |
| Components | `test/support/dev_app/storybook/components/` | One story per Pulsar component (19 total) |
| Foundations | `test/support/dev_app/storybook/foundations/` | Colors, typography, spacing, dark mode |
| Examples | `test/support/dev_app/storybook/examples/` | Real-UI compositions (login, dashboard, settings) |

## File layout

```
test/support/dev_app/storybook/
├── welcome.story.exs
├── components/
│   ├── badge.story.exs
│   ├── button.story.exs
│   ├── card.story.exs
│   ├── checkbox.story.exs
│   ├── divider.story.exs
│   ├── field.story.exs
│   ├── flash.story.exs
│   ├── flash_group.story.exs
│   ├── header.story.exs
│   ├── icon.story.exs
│   ├── input.story.exs
│   ├── label.story.exs
│   ├── link.story.exs
│   ├── list.story.exs
│   ├── radio_group.story.exs
│   ├── select.story.exs
│   ├── switch.story.exs
│   ├── table.story.exs
│   └── textarea.story.exs
├── foundations/
│   ├── colors.story.exs
│   ├── dark_mode.story.exs
│   ├── spacing.story.exs
│   └── typography.story.exs
└── examples/
    ├── dashboard.story.exs
    ├── login.story.exs
    └── settings_panel.story.exs
```

The storybook backend module lives at `test/support/dev_app/storybook.ex`
and the dev-app router wires it up at `/storybook`.

## Adding a new component story

1. Copy an existing story that is close to your component type.
   For a component with simple attribute variations, `badge.story.exs` is a
   good starting point. For a form-integrated component, `input.story.exs`
   or `select.story.exs` is closer.

2. Name the new file `test/support/dev_app/storybook/components/<name>.story.exs`
   and update the module name to match (e.g. `Pulsar.DevApp.Storybook.Components.MyComp`).

3. Set `def function, do: &Pulsar.Components.MyComp.my_comp/1` (or the
   relevant function reference).

4. Define `def attributes` and `def slots` to match the component's `attr`
   and `slot` declarations.

5. Add at least one `%Variation{}` (or `%VariationGroup{}` for grouping
   related states) under `def variations`.

6. Run `mix dev_app.server` and navigate to the new story to verify it
   renders correctly.

A minimal component story looks like:

```elixir
defmodule Pulsar.DevApp.Storybook.Components.MyComp do
  use PhoenixStorybook.Story, :component

  def function, do: &Pulsar.Components.MyComp.my_comp/1

  def attributes do
    [
      %Attr{id: :variant, type: :string, default: "primary",
            values: ~w[primary secondary], doc: "Visual variant"}
    ]
  end

  def variations do
    [
      %Variation{id: :default, description: "Default", attrs: %{variant: "primary"}},
      %Variation{id: :secondary, description: "Secondary", attrs: %{variant: "secondary"}}
    ]
  end
end
```

## Tailwind class scanning

The dev app's `test/support/dev_app/assets/app.css` includes:

```css
@source "../../storybook";
```

This tells Tailwind to scan the storybook directory for utility classes.
However, dynamically assembled class names (e.g. building a color name from
a variable at runtime) are **not** detected by the scanner.

If a story uses a dynamically constructed Tailwind class, add a safelist
comment that contains the literal class strings:

```elixir
# Safelisted for Tailwind scanning: bg-primary-500 bg-secondary-500 bg-success-500
```

The comment can live anywhere in the story file — Tailwind's scanner picks
up any string that looks like a utility class. This pattern was established
during the `colors.story.exs` foundation page (Phase 4).

## Generator workflow for consumers

Consumers of the Pulsar package can generate their own storybook stories
alongside the component source. There are three entry points:

- **`mix pulsar.install --storybook`** — install all components and generate
  matching storybook stories in one step.
- **`mix pulsar.gen.<component> --storybook`** — generate a single component
  plus its story.
- **`mix pulsar.gen.storybook`** — generate stories for all components that
  are already installed (useful when upgrading an existing project).

All three generators write stories under `lib/<app>_web/storybook/` and
print setup instructions for wiring `phoenix_storybook` into the router
(since consumers must add the dependency and route themselves).

See `Mix.Tasks.Pulsar.Gen.Storybook` for the full list of options.

## Accessibility testing

The storybook itself is axe-tested in CI. The integration test at
`test/integration/a11y/storybook_axe_test.exs` visits `/storybook` in both
light and dark themes and asserts zero axe-core violations.

Run it locally with:

    mix test test/integration/a11y/storybook_axe_test.exs --include integration

(Requires Playwright npm packages installed in
`test/support/dev_app/assets/node_modules`.)
