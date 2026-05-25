defmodule Pulsar.DevApp.Web do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {Pulsar.DevApp.Layouts, :app}

      alias Pulsar.DevApp.Web

      on_mount({Web, :assign_current_path})

      unquote(html_helpers())
    end
  end

  def on_mount(:assign_current_path, _params, _session, socket) do
    socket =
      Phoenix.LiveView.attach_hook(
        socket,
        :assign_current_path,
        :handle_params,
        fn _params, uri, socket ->
          {:cont, Phoenix.Component.assign(socket, :current_path, URI.parse(uri).path)}
        end
      )

    {:cont, socket}
  end

  defp html_helpers do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import Pulsar.DevApp.Components, only: [fixture_page: 1, fixture_section: 1]

      alias Phoenix.LiveView.JS
      alias Pulsar.DevApp.Endpoint

      unquote(verified_routes())
    end
  end

  defp verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Pulsar.DevApp.Endpoint,
        router: Pulsar.DevApp.Router,
        statics: ~w(assets)
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
