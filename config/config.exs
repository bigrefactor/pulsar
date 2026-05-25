import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Build pipeline for the in-repo fixture app (test/support/test_app).
# Only loaded in dev/test; the :tailwind and :esbuild deps are themselves dev/test-only,
# so consumers of the library never see these profiles.
if config_env() in [:dev, :test] do
  config :esbuild,
    version: "0.25.0",
    test_app: [
      args: ~w(
        test/support/test_app/assets/js/app.js
        --bundle
        --target=es2022
        --format=esm
        --outfile=priv/static/assets/app.js
      ),
      cd: Path.expand("..", __DIR__),
      env: %{
        "NODE_PATH" =>
          Enum.join(
            [
              Path.expand("../deps", __DIR__),
              Path.expand("../_build/#{config_env()}", __DIR__)
            ],
            ":"
          )
      }
    ]

  config :tailwind,
    version: "4.1.12",
    test_app: [
      args: ~w(
        --input=test/support/test_app/assets/css/app.css
        --output=priv/static/assets/app.css
      ),
      cd: Path.expand("..", __DIR__)
    ]
end

# Import environment specific config
import_config "#{config_env()}.exs"
