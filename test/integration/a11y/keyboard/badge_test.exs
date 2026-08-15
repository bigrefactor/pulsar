defmodule Pulsar.Integration.A11y.Keyboard.BadgeTest do
  @moduledoc """
  Real-browser tests for a badge used as a two-action token: a label that opens
  a popover, plus a remove control. Static render assertions pass whether or not
  the panel actually opens, so these drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  @remove ~s|#kbd-badge button[aria-label="Remove filter Status"]|

  describe "two-action token" do
    # The fixture at `/keyboard/badge` renders an `as={:div}` badge holding a
    # popover (trigger `kbd-badge-trigger`, panel `kbd-badge-panel`) plus the
    # badge's own `on_remove` control.
    #
    # Verification, each confirmed to fail the test named beside it:
    # drop the `popovertarget` setAttribute calls from the `.PulsarPopover`
    # hook and run `MIX_ENV=test mix assets.build` (opens the panel); add
    # `tabindex="-1"` to badge's remove control (separate tab stops); drop
    # `phx-click={@on_remove}` from it (dismisses the token).

    test "the label trigger opens the popover panel hosted inside the badge", %{conn: conn} do
      conn
      |> visit("/keyboard/badge")
      |> A11y.await_live_connected()
      |> A11y.refute_visible("kbd-badge-panel")
      |> press("#kbd-badge-trigger", "Enter")
      |> assert_has(~s|#kbd-badge-trigger[aria-expanded="true"]|)
      |> A11y.await_animations("kbd-badge-panel")
      |> A11y.assert_visible("kbd-badge-panel")
    end

    test "the label trigger and the remove control are separate tab stops", %{conn: conn} do
      conn
      |> visit("/keyboard/badge")
      |> A11y.await_live_connected()
      |> press("#kbd-badge-before", "Tab")
      |> A11y.assert_focused("kbd-badge-trigger")
      |> press("#kbd-badge-trigger", "Tab")
      |> assert_has(@remove <> ":focus")
    end

    test "the remove control dismisses the token", %{conn: conn} do
      conn
      |> visit("/keyboard/badge")
      |> A11y.await_live_connected()
      |> assert_has("#kbd-badge")
      |> click(@remove)
      |> refute_has("#kbd-badge")
    end
  end
end
