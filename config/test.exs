import Config

alias Pulsar.TestApp.Endpoint
alias Pulsar.TestApp.ErrorHTML
alias Pulsar.TestApp.PubSub

# Print only warnings and errors during test
config :logger, level: :warning

# In-repo fixture app endpoint (test/support/test_app).
# `server: false` by default; phoenix_test_playwright (PUL-11) or `mix test_app.server`
# flips PHX_SERVER=1 to bind the HTTP listener.
config :pulsar, Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: String.duplicate("pulsar-test-secret-key-base-padding-", 2),
  live_view: [signing_salt: "pulsar-test-salt"],
  pubsub_server: PubSub,
  check_origin: false,
  server: System.get_env("PHX_SERVER") in ["1", "true"],
  render_errors: [formats: [html: ErrorHTML], layout: false]
