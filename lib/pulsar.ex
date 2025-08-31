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
      import Pulsar.Components.Card
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

  All components support the full Stellar API plus additional styling props:

  - `Button` - Various styles and states
  - `Card` - Content containers
  - `Alert` - Notification messages
  - `Badge` - Status indicators
  - More coming soon...

  ## Theme Customization

  The theme uses CSS custom properties that reference Tailwind's color palette:

      @theme inline {
        /* Change primary from blue to indigo */
        --color-primary-500: var(--color-indigo-500);
      }

  See the theme file at `priv/static/themes/pulsar.css` for all available tokens.
  """

  use Application

  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: Pulsar.PubSub}
      ] ++ if start_endpoint?(), do: [PulsarWeb.Endpoint], else: []

    opts = [strategy: :one_for_one, name: Pulsar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Returns the version of Pulsar.
  """
  def version do
    Application.spec(:pulsar, :vsn) |> to_string()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PulsarWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp start_endpoint? do
    Application.get_env(:pulsar, :start_endpoint, false)
  end
end
