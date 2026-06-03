import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Build pipeline for the in-repo fixture app (test/support/dev_app).
# Only loaded in dev/test; the :tailwind and :esbuild deps are themselves dev/test-only,
# so consumers of the library never see these profiles.
if config_env() in [:dev, :test] do
  node_path_sep =
    case :os.type() do
      {:win32, _} -> ";"
      _ -> ":"
    end

  esbuild_env = %{
    "NODE_PATH" =>
      Enum.join(
        [
          Path.expand("../deps", __DIR__),
          Path.expand("../_build/#{config_env()}", __DIR__)
        ],
        node_path_sep
      )
  }

  config :esbuild,
    version: "0.25.0",
    dev_app: [
      args: ~w(
        test/support/dev_app/assets/js/app.js
        --bundle
        --target=es2022
        --format=esm
        --outfile=test/support/dev_app/priv/static/assets/app.js
      ),
      cd: Path.expand("..", __DIR__),
      env: esbuild_env
    ],
    # PhoenixStorybook injects `js_path` as a classic <script> (text/javascript),
    # so its hook bundle must be a self-contained IIFE, not an ES module.
    dev_app_storybook: [
      args: ~w(
        test/support/dev_app/assets/js/storybook.js
        --bundle
        --target=es2022
        --format=iife
        --outfile=test/support/dev_app/priv/static/assets/storybook.js
      ),
      cd: Path.expand("..", __DIR__),
      env: esbuild_env
    ]

  config :tailwind,
    version: "4.1.12",
    dev_app: [
      args: ~w(
        --input=test/support/dev_app/assets/css/app.css
        --output=test/support/dev_app/priv/static/assets/app.css
      ),
      cd: Path.expand("..", __DIR__)
    ]
end

# Import environment specific config
import_config "#{config_env()}.exs"
