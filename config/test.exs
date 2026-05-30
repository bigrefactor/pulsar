import Config

alias Pulsar.DevApp.Endpoint
alias Pulsar.DevApp.ErrorHTML
alias Pulsar.DevApp.PubSub

# Print only warnings and errors during test
config :logger, level: :warning

# Playwright (and the playwright npm package) lives under the dev_app's assets
# directory, not the project's default `./assets`.
# Raise the default timeout to 60 s. The heavier fixture pages — most
# noticeably Select, which renders 288 styled widgets across the variant ×
# color × size × state matrix — push LiveView's mount + channel join + initial
# diff past 30 s on a 2-core CI runner. This timeout is the budget for
# `assert_has`/`await_live_connected` waits, not the per-page navigation, so a
# generous ceiling here is paid only when something is genuinely slow. Local
# runs finish well under 10 s, so the bump is a ceiling, not a floor.
config :phoenix_test, :playwright,
  assets_dir: "test/support/dev_app/assets",
  timeout: 60_000

# PhoenixTest.Playwright resolves the OTP app to find the endpoint module.
config :phoenix_test, otp_app: :pulsar

# In-repo fixture app endpoint (test/support/dev_app).
# `server: true` so phoenix_test_playwright can drive the real listener on every
# `mix test` invocation. Unit tests ignore the bind; browser tests rely on it.
# Side effect: the port is bound for the lifetime of any test run, so two
# concurrent `mix test` invocations on the same machine collide with
# `:eaddrinuse`. Run them serially, or set PULSAR_TEST_PORT to a free port (e.g.
# when a dev server already holds the default 4002).
config :pulsar, Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PULSAR_TEST_PORT", "4002"))],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: String.duplicate("pulsar-test-secret-key-base-padding-", 2),
  live_view: [signing_salt: "pulsar-test-salt"],
  pubsub_server: PubSub,
  check_origin: false,
  server: true,
  render_errors: [formats: [html: ErrorHTML], layout: false]
