# Boot the in-repo fixture app (test/support/test_app). Endpoint defaults to
# `server: false` (set in config/test.exs) so `mix test` runs don't bind a port;
# phoenix_test_playwright (PUL-11) and `mix test_app.server` flip PHX_SERVER=1.
{:ok, _} = Application.ensure_all_started(:phoenix_live_view)
{:ok, _} = Pulsar.TestApp.Application.start(:normal, [])

ExUnit.start()
