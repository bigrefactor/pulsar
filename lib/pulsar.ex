defmodule Pulsar do
  @moduledoc """
  Pulsar - Styled Phoenix LiveView components built on Stellar.

  Pulsar provides production-ready, styled components that wrap Stellar's headless components
  with beautiful Tailwind CSS styling. Components use semantic color names and support both
  light and dark modes through CSS custom properties.

  ## Usage

  ### Library Mode

  Import components directly into your application:

      # In your component module
      import Pulsar.Components.Button
      import Pulsar.Components.Header
      # ... or use the convenience macro
      use PulsarWeb, :components

      # In your templates
      <.button variant="primary" size="lg">
        Save Changes
      </.button>

  ### Generator Mode

  Generate components into your project for full customization:

      mix pulsar.gen.button
      mix pulsar.gen.card
      # Or generate all components
      mix pulsar.gen.all

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible, headless components
  - **Tailwind CSS**: Utility-first styling with semantic color tokens  
  - **Dark Mode**: Automatic light/dark mode support via CSS custom properties
  - **TypeScript-like Docs**: Full attr documentation with `:values` validation
  - **Flexible**: Use as library or generate for customization
  - **Zero JavaScript**: Pure Phoenix LiveView with colocated hooks

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
   - `Table` - Data tables with LiveStream support, sorting, and actions
   - More components available...

  ## Theme Customization

  The theme uses CSS custom properties that reference Tailwind's color palette:

      @theme inline {
        /* Change primary from blue to indigo */
        --color-primary-500: var(--color-indigo-500);
      }

  See the theme file at `priv/static/themes/pulsar.css` for all available tokens.
  """

  @doc """
  Returns the version of Pulsar.
  """
  def version do
    Application.spec(:pulsar, :vsn) |> to_string()
  end
end
