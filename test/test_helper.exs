# Boot the in-repo fixture app (test/support/test_app). Endpoint binds port 4002
# unconditionally in test env so phoenix_test_playwright can drive it; unit tests
# ignore the listener. Browser tests are tagged `:integration` and excluded by default.
#
# NOTE: We deliberately avoid `:browser` as the ExUnit tag because
# `PhoenixTest.Playwright.Case` merges ExUnit context keys into Playwright config,
# and `:browser` is a valid Playwright config key (expects a browser atom like
# `:chromium`, not `true`). Using `:integration` sidesteps that conflict.
{:ok, _} = Application.ensure_all_started(:phoenix_live_view)
{:ok, _} = Pulsar.TestApp.Application.start(:normal, [])

# Start the Playwright supervisor unconditionally. It's a cheap idle process
# when no integration tests run, and starting it always avoids subtle gating
# bugs (e.g. running a single browser test by file path, or unusual orderings
# of --include / --only flags).
{:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()

Application.put_env(:phoenix_test, :base_url, Pulsar.TestApp.Endpoint.url())

ExUnit.start(exclude: [:integration])
