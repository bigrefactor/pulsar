defmodule Pulsar.Integration.A11y.Keyboard.AccordionTest do
  @moduledoc """
  Real-browser keyboard tests for Accordion. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Accordion interaction" do
    # The fixture at `/keyboard/accordion` renders a single-mode accordion
    # (`kbd-acc`) with headers kbd-acc-{one,two,three}-header, item two disabled
    # (the disabled header is focusable but never opens), and unique panel
    # bodies kbd-acc-{one,three}-body. Behavior comes from the `.PulsarAccordion`
    # colocated hook.
    #
    # These assert the panel actually OPENS (visible body), not just that
    # `aria-expanded` flips — the hook can toggle `data-expanded` while the panel
    # stays collapsed/hidden if the `group/item` disclosure root is missing.
    #
    # Verification: remove `"group/item"` from the item wrapper class in
    # `priv/templates/accordion.ex.eex` (and re-sync + `MIX_ENV=test mix
    # assets.build`), re-run — `aria-expanded` still flips but `assert_visible`
    # fails because the panel never expands.

    test "clicking a header opens its panel (visible, not just aria)", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> A11y.refute_visible("kbd-acc-one-body")
      |> click("#kbd-acc-one-header")
      |> assert_has(~s|#kbd-acc-one-header[aria-expanded="true"]|)
      |> A11y.await_animations("kbd-acc")
      |> A11y.assert_visible("kbd-acc-one-body")
    end

    test "clicking an open header closes it again (collapsible single)", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> click("#kbd-acc-one-header")
      |> assert_has(~s|#kbd-acc-one-header[aria-expanded="true"]|)
      |> click("#kbd-acc-one-header")
      |> assert_has(~s|#kbd-acc-one-header[aria-expanded="false"]|)
      |> A11y.await_animations("kbd-acc")
      |> A11y.refute_visible("kbd-acc-one-body")
    end

    test "single mode: opening a second panel closes the first", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> click("#kbd-acc-one-header")
      |> assert_has(~s|#kbd-acc-one-header[aria-expanded="true"]|)
      |> click("#kbd-acc-three-header")
      |> assert_has(~s|#kbd-acc-three-header[aria-expanded="true"]|)
      |> assert_has(~s|#kbd-acc-one-header[aria-expanded="false"]|)
      |> A11y.await_animations("kbd-acc")
      |> A11y.assert_visible("kbd-acc-three-body")
      |> A11y.refute_visible("kbd-acc-one-body")
    end

    test "a disabled header is focusable but Enter leaves its panel closed", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> assert_has(~s|#kbd-acc-two-header[aria-disabled="true"][aria-expanded="false"]|)
      |> press("#kbd-acc-one-header", "ArrowDown")
      |> A11y.assert_focused("kbd-acc-two-header")
      |> press("#kbd-acc-two-header", "Enter")
      |> assert_has(~s|#kbd-acc-two-header[aria-expanded="false"]|)
      |> A11y.refute_visible("kbd-acc-two-body")
      |> press("#kbd-acc-two-header", "Space")
      |> assert_has(~s|#kbd-acc-two-header[aria-expanded="false"]|)
      |> A11y.refute_visible("kbd-acc-two-body")
    end

    test "ArrowDown roves through the disabled header to the next one", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> press("#kbd-acc-one-header", "ArrowDown")
      |> A11y.assert_focused("kbd-acc-two-header")
      |> press("#kbd-acc-two-header", "ArrowDown")
      |> A11y.assert_focused("kbd-acc-three-header")
    end
  end
end
