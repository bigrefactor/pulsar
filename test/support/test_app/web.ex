defmodule Pulsar.TestApp.Web do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {Pulsar.TestApp.Layouts, :app}

      alias Pulsar.TestApp.Web

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
      import Pulsar.TestApp.Components, only: [fixture_page: 1, fixture_section: 1]

      alias Phoenix.LiveView.JS
      alias Pulsar.TestApp.Endpoint

      unquote(verified_routes())
    end
  end

  defp verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Pulsar.TestApp.Endpoint,
        router: Pulsar.TestApp.Router,
        statics: ~w(assets)
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
