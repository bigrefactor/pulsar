import Config

alias Pulsar.DevApp.Endpoint
alias Pulsar.DevApp.ErrorHTML
alias Pulsar.DevApp.PubSub

# Print only warnings and errors during test
config :logger, level: :warning

# Playwright (and the playwright npm package) lives under the dev_app's assets
# directory, not the project's default `./assets`.
# Raise the default navigation timeout to 10 s — the fixture pages include
# Tailwind / LiveView assets that need a moment to load.
config :phoenix_test, :playwright,
  assets_dir: "test/support/dev_app/assets",
  timeout: 10_000

# PhoenixTest.Playwright resolves the OTP app to find the endpoint module.
config :phoenix_test, otp_app: :pulsar

# In-repo fixture app endpoint (test/support/dev_app).
# `server: true` so phoenix_test_playwright can drive the real listener on every
# `mix test` invocation. Unit tests ignore the bind; browser tests rely on it.
# Side effect: port 4002 is bound for the lifetime of any test run, so two
# concurrent `mix test` invocations on the same machine will collide with
# `:eaddrinuse`. Run them serially, or override the port via env config.
config :pulsar, Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: String.duplicate("pulsar-test-secret-key-base-padding-", 2),
  live_view: [signing_salt: "pulsar-test-salt"],
  pubsub_server: PubSub,
  check_origin: false,
  server: true,
  render_errors: [formats: [html: ErrorHTML], layout: false]
