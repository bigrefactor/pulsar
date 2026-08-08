defmodule Pulsar.Integration.A11y.Keyboard.CollapsibleTest do
  @moduledoc """
  Real-browser keyboard tests for Collapsible. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Collapsible interaction" do
    # The fixture at `/keyboard/collapsible` renders a single collapsible
    # (`kbd-col`), closed by default, with trigger `[data-collapsible-trigger]`
    # and a unique panel body `kbd-col-body`. Behavior comes from the
    # `.PulsarCollapsible` colocated hook.
    #
    # These assert the panel actually OPENS (visible body), not just that
    # `aria-expanded` flips — the hook can toggle `data-expanded` while the panel
    # stays collapsed/hidden if the `group/collapsible` disclosure root is missing.
    #
    # Verification: remove `"group/collapsible"` from the container class in
    # `priv/templates/collapsible.ex.eex` (and re-sync + `MIX_ENV=test mix
    # assets.build`), re-run — `aria-expanded` still flips but `assert_visible`
    # fails because the panel never expands.

    test "clicking the trigger opens the panel (visible, not just aria)", %{conn: conn} do
      conn
      |> visit("/keyboard/collapsible")
      |> A11y.await_live_connected()
      |> A11y.refute_visible("kbd-col-body")
      |> click("#kbd-col [data-collapsible-trigger]")
      |> assert_has(~s|[data-collapsible-trigger][aria-expanded="true"]|)
      |> A11y.await_animations("kbd-col")
      |> A11y.assert_visible("kbd-col-body")
    end

    test "clicking again closes it", %{conn: conn} do
      conn
      |> visit("/keyboard/collapsible")
      |> A11y.await_live_connected()
      |> click("#kbd-col [data-collapsible-trigger]")
      |> assert_has(~s|[data-collapsible-trigger][aria-expanded="true"]|)
      |> click("#kbd-col [data-collapsible-trigger]")
      |> assert_has(~s|[data-collapsible-trigger][aria-expanded="false"]|)
      |> A11y.await_animations("kbd-col")
      |> A11y.refute_visible("kbd-col-body")
    end
  end
end
