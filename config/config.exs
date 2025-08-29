import Config

# Configure the endpoint
config :pulsar, PulsarWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "A" <> String.duplicate("B", 63),
  render_errors: [formats: [html: PulsarWeb.ErrorHTML], layout: false],
  pubsub_server: Pulsar.PubSub,
  live_view: [signing_salt: "pulsar_signing_salt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.21.5",
  pulsar: [
    args:
      ~w(assets/js/app.js --bundle --target=es2022 --format=esm --outdir=priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.10",
  pulsar: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Import environment specific config
import_config "#{config_env()}.exs"