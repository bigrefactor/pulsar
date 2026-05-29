import Config

alias Pulsar.DevApp.Endpoint
alias Pulsar.DevApp.ErrorHTML
alias Pulsar.DevApp.PubSub

# Print only warnings and errors during test
config :logger, level: :warning

# Playwright (and the playwright npm package) lives under the dev_app's assets
# directory, not the project's default `./assets`.
#
# `timeout`: navigation/action budget per call. 30 s tolerates CI cold-start
# pressure (LiveView mount + Tailwind paint on 2-core runners) without being
# noticeable locally.
#
# `browser_pools.size`: number of headless Chromium instances the pool may
# launch. Defaults to `ceil(System.schedulers_online() / 2)`, which is 1 on
# GitHub Actions' 2-core ubuntu-22.04 runner — and that's smaller than ExUnit's
# default `max_cases = schedulers * 2 = 4`, so 3 of every 4 async test modules
# starve waiting on `BrowserPool.checkout` and their `setup_all` times out at
# 60 s. Pin `size: 4` to match max_cases; each headless Chromium is ~200 MB so
# the cap matters on the 7 GB CI runner.
config :phoenix_test, :playwright,
  assets_dir: "test/support/dev_app/assets",
  timeout: 30_000,
  browser_pools: [[id: :default_pool, size: 4]]

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
