defmodule Pulsar.Integration.A11y.Keyboard.PopoverTest do
  @moduledoc """
  Real-browser keyboard tests for Popover. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Popover keyboard behavior" do
    # The fixture at `/keyboard/popover` renders a trigger button
    # (kbd-pop-trigger) wired by the `.PulsarPopover` colocated hook to a
    # native `popover="auto"` panel (kbd-pop) holding a focusable link
    # (kbd-pop-inside). Open/close/dismiss are native; the hook syncs
    # `aria-expanded` and `data-state` on the `toggle` event.
    #
    # Verification: comment out the `aria-expanded` setAttribute calls in
    # `onStateChange` of the `.PulsarPopover` hook (priv/templates/popover.ex.eex
    # and the synced lib file), run `MIX_ENV=test mix assets.build`, re-run —
    # the open/close aria-expanded assertions fail.

    test "Enter on the trigger opens the panel and reflects expanded state", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> assert_has(~s|#kbd-pop[data-state="open"]|)
    end

    test "Escape closes the panel, restores focus to the trigger, and resets expanded", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> press("#kbd-pop-inside", "Escape")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="false"]|)
      |> A11y.assert_focused("kbd-pop-trigger")
    end

    test "Tab from inside the open panel is not trapped", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> press("#kbd-pop-inside", "Tab")
      |> A11y.refute_focused_within("#kbd-pop")
    end
  end
end
