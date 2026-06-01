defmodule Pulsar.DevApp.Layouts do
  @moduledoc false

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: Pulsar.DevApp.Endpoint,
    router: Pulsar.DevApp.Router,
    statics: ~w(assets)

  import Phoenix.Controller, only: [get_csrf_token: 0]
  import Pulsar.DevApp.Components, only: [fixture_nav: 1, theme_toggle: 1]

  alias Pulsar.Components.Sidebar

  embed_templates "layouts/*"
end
