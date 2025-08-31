import Config

# Start Pulsar's endpoint in development by default
config :pulsar, start_endpoint: true

# Configure the endpoint for development
config :pulsar, PulsarWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  adapter: Bandit.PhoenixAdapter,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "A" <> String.duplicate("B", 63),
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:pulsar, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:pulsar, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/pulsar_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"lib/pulsar/.*(ex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
