defmodule Pulsar do
  @moduledoc """
  Pulsar — production-ready Phoenix LiveView components.

  Pulsar is a self-contained component library for Phoenix LiveView. It ships
  accessible, styled components with all WAI-ARIA behavior built in and only
  Twm as a runtime dependency. Components are designed to be generated into
  your application, giving you full ownership of the source and predictable
  Tailwind class purging.

  ## Installation

  Add Pulsar to your `mix.exs` dependencies:

      def deps do
        [
          {:pulsar, "~> 0.1"},
          {:twm, "~> 0.1"}
        ]
      end

  Then install components and the theme into your Phoenix app:

      mix pulsar.install

  This generates the theme CSS, every component, and a `core_components`
  module under your app's namespace (default `YourAppWeb.Components`). See
  `Mix.Tasks.Pulsar.Install` for selective options such as
  `--component=button,input` or `--no-theme`. Individual generators are also
  available:

      mix pulsar.gen.button
      mix pulsar.gen.card

  ## Usage

  Import the generated components in your LiveViews or component modules:

      import YourAppWeb.Components.Button

      <.button variant="primary" size="lg">
        Save Changes
      </.button>

  Components can also be used directly from Pulsar without generation
  (`import Pulsar.Components.Button`), but generation is recommended for
  production: the generated source lives in your project, Tailwind picks up
  the classes automatically, and you can customize freely.

  ## Features

  - **Self-Contained**: All accessibility and behavior inlined; only
    Twm as a runtime dependency
  - **Tailwind CSS**: Utility-first styling with semantic color tokens
  - **Dark Mode**: Automatic light/dark mode support via CSS custom properties
  - **Documented Attrs**: Full attr documentation with `:values` validation
  - **Flexible**: Use as library or generate for customization
  - **No external JS**: Uses `Phoenix.LiveView.JS` and colocated hooks

  ## Components

  All components support semantic styling with variants, colors, and sizes:

  - `Button` - Interactive buttons with multiple variants and states
  - `Header` - Page headers with titles, subtitles, breadcrumbs, and actions
  - `Badge` - Status indicators and labels with addons
  - `Input` - Text inputs with decorators and validation
  - `Select` - Dropdown selects with multi-select badge display
  - `Checkbox` - Checkboxes with card variants and form integration
  - `Switch` - Toggle switches with proper ARIA semantics
  - `Link` - Secure navigation links with XSS protection
  - `Icon` - Heroicons with flexible sizing and semantic colors
  - `Table` - Data tables with LiveStream support and actions
  - More components available...

  ## Theme Customization

  `mix pulsar.gen.theme` (run as part of `mix pulsar.install`) writes
  `assets/css/theme.css` into your project. Edit that file to remap semantic
  tokens to any Tailwind palette:

      @theme inline {
        /* Change primary from blue to indigo */
        --color-primary-500: var(--color-indigo-500);
      }

  See `Mix.Tasks.Pulsar.Gen.Theme` for the complete set of tokens the task
  generates.
  """

  @doc """
  Returns the version of Pulsar.
  """
  def version do
    Application.spec(:pulsar, :vsn) |> to_string()
  end
end
