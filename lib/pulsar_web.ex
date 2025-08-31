defmodule PulsarWeb do
  @moduledoc """
  Convenience module for importing Pulsar components.

  This module provides a `use` macro that makes it easy to import all
  Pulsar components at once, similar to how Phoenix provides `use MyAppWeb, :html`.

  ## Usage

      defmodule MyAppWeb.SomeLive do
        use Phoenix.LiveView
        use PulsarWeb, :components
        
        # Now you can use all Pulsar components
        def render(assigns) do
          ~H\"\"\"
          <.button variant="primary">Click me</.button>
          <.card>
            <:header>Card Title</:header>
            Card content here
          </.card>
          \"\"\"
        end
      end

  ## Available Imports

  - `:components` - Imports all Pulsar components
  - `:button` - Imports only the Button component
  - `:card` - Imports only the Card component
  - `:alert` - Imports only the Alert component
  - `:badge` - Imports only the Badge component

  You can also import individual components directly:

      import Pulsar.Components.Button
      import Pulsar.Components.Card
  """

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @doc """
  Imports all available Pulsar components.
  """
  def components do
    quote do
      import Pulsar.Components.Button
      import Pulsar.Components.Input
      # More components will be added here as they're implemented

      # Define forwarding functions so component functions are available
      # on the using module (helps introspection and ergonomics)
      def button(assigns), do: Pulsar.Components.Button.button(assigns)
      def input(assigns), do: Pulsar.Components.Input.input(assigns)
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  def html do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import PulsarWeb.Layouts
      unquote(verified_routes())
    end
  end

  defp verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PulsarWeb.Endpoint,
        router: PulsarWeb.Router,
        statics: ~w(assets fonts images favicon.ico robots.txt)
    end
  end

  @doc """
  Imports only the Button component.
  """
  def button do
    quote do
      import Pulsar.Components.Button

      # Define a forwarding function to expose :button on the caller
      def button(assigns), do: Pulsar.Components.Button.button(assigns)
    end
  end

  @doc """
  Imports only the Card component.
  """
  def card do
    quote do
      import Pulsar.Components.Card
    end
  end

  @doc """
  Imports only the Alert component.
  """
  def alert do
    quote do
      import Pulsar.Components.Alert
    end
  end

  @doc """
  Imports only the Badge component.
  """
  def badge do
    quote do
      import Pulsar.Components.Badge
    end
  end
end
