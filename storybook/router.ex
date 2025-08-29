defmodule Pulsar.Storybook.Router do
  @moduledoc """
  Router for the Pulsar component storybook.

  This provides a simple way to browse and test Pulsar components
  in development. Can be mounted in your Phoenix router like:

      # In your Phoenix router
      if Mix.env() == :dev do
        import Pulsar.Storybook.Router
        pulsar_storybook "/storybook"
      end

  Or used standalone for component development.
  """

  defmacro pulsar_storybook(path, opts \\ []) do
    quote do
      scope unquote(path), alias: false, as: false do
        import Phoenix.LiveView.Router
        
        live "/", Pulsar.Storybook.CatalogLive, unquote(opts)
        live "/catalog", Pulsar.Storybook.CatalogLive, unquote(opts)
        live "/catalog/:component", Pulsar.Storybook.CatalogLive, unquote(opts)
      end
    end
  end
end