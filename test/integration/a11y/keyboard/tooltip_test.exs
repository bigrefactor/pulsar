defmodule Pulsar.Integration.A11y.Keyboard.TooltipTest do
  @moduledoc """
  Real-browser keyboard tests for Tooltip. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Tooltip keyboard behavior" do
    # The fixture at `/keyboard/tooltip` renders a trigger button
    # (kbd-tip-trigger) wired by the `.PulsarPopover` colocated hook in hover
    # mode to a `popover="manual"` panel (kbd-tip) carrying role="tooltip".
    # Keyboard focus opens it immediately and the hook wires aria-describedby;
    # Escape dismisses it.
    #
    # Verification: comment out the `_openNow` focus listener in `setupHover`
    # of the `.PulsarPopover` hook (priv/templates/popover.ex.eex and the
    # synced lib file), run `MIX_ENV=test mix assets.build`, re-run — the
    # focus-show assertion fails.

    test "the trigger describes the tooltip via aria-describedby", %{conn: conn} do
      conn
      |> visit("/keyboard/tooltip")
      |> A11y.await_live_connected()
      |> assert_has(~s|#kbd-tip-trigger[aria-describedby="kbd-tip"]|)
    end

    test "keyboard focus opens the tooltip", %{conn: conn} do
      conn
      |> visit("/keyboard/tooltip")
      |> A11y.await_live_connected()
      |> A11y.focus("kbd-tip-trigger")
      |> assert_has(~s|#kbd-tip[data-state="open"]|)
    end

    test "the trigger keeps aria-describedby after a patch re-renders it", %{conn: conn} do
      conn
      |> visit("/keyboard/tooltip")
      |> A11y.await_live_connected()
      |> click("#kbd-tip-patch-bump")
      |> assert_has("#kbd-tip-patch-trigger", text: "Patched 1")
      |> assert_has(~s|#kbd-tip-patch-trigger[aria-describedby="kbd-tip-patch"]|)
      |> A11y.focus("kbd-tip-patch-trigger")
      |> assert_has(~s|#kbd-tip-patch[data-state="open"]|)
    end

    test "Escape dismisses the open tooltip", %{conn: conn} do
      conn
      |> visit("/keyboard/tooltip")
      |> A11y.await_live_connected()
      |> A11y.focus("kbd-tip-trigger")
      |> assert_has(~s|#kbd-tip[data-state="open"]|)
      |> press("#kbd-tip-trigger", "Escape")
      # A closed manual popover is display:none, so assert the open state is gone
      # rather than matching the now-hidden panel.
      |> refute_has(~s|#kbd-tip[data-state="open"]|)
    end
  end
end
