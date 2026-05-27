# Boot the in-repo fixture app (test/support/dev_app). Endpoint binds port 4002
# unconditionally in test env so phoenix_test_playwright can drive it; unit tests
# ignore the listener. Browser tests are tagged `:integration` and excluded by default.
#
# NOTE: We deliberately avoid `:browser` as the ExUnit tag because
# `PhoenixTest.Playwright.Case` merges ExUnit context keys into Playwright config,
# and `:browser` is a valid Playwright config key (expects a browser atom like
# `:chromium`, not `true`). Using `:integration` sidesteps that conflict.
{:ok, _} = Application.ensure_all_started(:phoenix_live_view)
{:ok, _} = Pulsar.DevApp.Application.start(:normal, [])

# Start the Playwright supervisor whenever Playwright is installed under
# test/support/dev_app/assets. Gating on installation (rather than on the
# `:integration` ExUnit include-list) keeps the supervisor available for any
# invocation that could run a browser test — including single-file or
# unusual --include / --only orderings — without breaking environments that
# never install Playwright (e.g. the Code Quality CI job, which runs
# `mix test --cover` but does not run `npm install playwright`).
playwright_pkg_json =
  Path.join(["test/support/dev_app/assets", "node_modules", "playwright", "package.json"])

if File.exists?(playwright_pkg_json) do
  {:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
end

Application.put_env(:phoenix_test, :base_url, Pulsar.DevApp.Endpoint.url())

ExUnit.start(exclude: [:integration, :measure])
