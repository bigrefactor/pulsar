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

### `mix dev.storybook` and `mix dev_app.server` are equivalent

Both commands boot the in-repo dev app on port 4002. `mix dev.storybook` is
a Pulsar alias that delegates to `mix dev_app.server`.

The alias exists because `phoenix_storybook` ships its own `mix dev.storybook`
task — intended for PSB contributors working against a git checkout — that
fails against the hex package. PSB's version runs `npm ci` and
`mix assets.build` inside `deps/phoenix_storybook/assets/`, but the hex tarball
strips that directory (only `priv/`, `lib`, `guides`, etc. are published) and
ships prebuilt JS/CSS under `priv/static/`. Pulsar's `mix.exs` shadows the
broken task with an alias to `dev_app.server` so the command behaves the way
contributors intuitively expect.

### Sandbox styling

PhoenixStorybook renders stories inline and scopes its own Tailwind
preflight to `.psb`. To prevent its reset from affecting your components,
PSB wraps every story container in a sandbox class — `pulsar-sandbox`
in our case, declared via `sandbox_class:` in
`test/support/dev_app/storybook.ex`. The host app is responsible for
providing the baseline styling (font, color, etc.) inside that wrapper.

The dev app does this in two places:

- `test/support/dev_app/assets/css/app.css` defines
  `.pulsar-sandbox { font-family: var(--font-sans); ... }` plus a
  child `*` rule so descendants inherit the font.
- `test/support/dev_app/layouts/root.html.heex` puts `pulsar-sandbox`
  on the `<body>` element so non-storybook routes pick up the same
  baseline.

If you add a new globally-applied rule (font, base color, default
spacing), put it inside the `.pulsar-sandbox` block — not at the root
level — so it reaches story content.

See the PSB sandboxing guide for the full mechanism:
<https://hexdocs.pm/phoenix_storybook/sandboxing.html>

### Light/dark theme switcher

The dev app's `Pulsar.DevApp.Storybook` backend declares two themes via
PhoenixStorybook's `themes:` option — `light` and `dark`. Each carries a
`name:` (the dropdown label that PSB's template renders; the `label:`
key shown in PSB's theming guide is unused).

When the user picks a theme, PSB stamps a `theme-<id>` class onto the
same sandbox container that already wears `pulsar-sandbox`. Two CSS
mechanisms make that flip the box and its contents:

- `.theme-dark.pulsar-sandbox` in
  `test/support/dev_app/assets/css/app.css` paints the box itself with
  the dark surface + foreground tokens.
- The `@custom-variant dark` in the same file matches `.theme-dark *`,
  so every Pulsar component inside the box picks up its `dark:`
  utilities (`dark:bg-dark-primary`, etc.).

PSB's *chrome* color mode (the sidebar/header) is a separate setting
keyed on the `psb_selected_color_mode` localStorage entry and stays
independent. Flipping the app theme does not touch the chrome —
that's intentional for a dev tool.

PSB persists the selected theme via a `?theme=dark` URL parameter so
reloads keep the selection.

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
