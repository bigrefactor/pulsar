defmodule Pulsar.DevApp.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :pulsar

  alias Phoenix.LiveView.Socket
  alias Pulsar.DevApp.Router

  @session_options [
    store: :cookie,
    key: "_pulsar_dev_key",
    signing_salt: "pulsar-test-cookie-salt",
    same_site: "Lax"
  ]

  socket "/live", Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/assets",
    from: Path.expand("priv/static/assets", __DIR__),
    gzip: false,
    only: ~w(app.css app.js)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug Router
end
