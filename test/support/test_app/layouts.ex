defmodule Pulsar.TestApp.Layouts do
  @moduledoc false

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: Pulsar.TestApp.Endpoint,
    router: Pulsar.TestApp.Router,
    statics: ~w(assets)

  import Phoenix.Controller, only: [get_csrf_token: 0]
  import Pulsar.TestApp.Components, only: [fixture_nav: 1, theme_toggle: 1]

  embed_templates "layouts/*"
end
