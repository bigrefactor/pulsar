defmodule Pulsar.Integration.A11y.Keyboard.TabsTest do
  @moduledoc """
  Real-browser keyboard tests for Tabs. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Tabs keyboard navigation" do
    # The fixture at `/keyboard/tabs` renders a horizontal tablist
    # (kbd-h-one / kbd-h-mid [disabled] / kbd-h-two) and a vertical
    # tablist (kbd-v-one / kbd-v-two). Roving focus + arrow/Home/End
    # navigation and the active-tab selection sync come from the
    # `.PulsarTabs` colocated hook, which reads orientation from the
    # tabs root's `data-orientation`. Disabled tabs are focusable but
    # never selected.
    #
    # Verification: comment out the ArrowRight/ArrowLeft branch in the
    # keydown handler of `.PulsarTabs` (see `lib/pulsar/components/tabs.ex`,
    # near the orientation/arrow handling), run `MIX_ENV=test mix
    # assets.build`, re-run — the ArrowRight test fails because focus and
    # selection stay on kbd-h-one.

    test "ArrowRight focuses a disabled tab without selecting it, then moves on", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "ArrowRight")
      |> A11y.assert_focused("kbd-h-mid")
      |> assert_has(~s|#kbd-h-mid[aria-selected="false"]|)
      |> assert_has(~s|#kbd-h-mid[tabindex="0"]|)
      |> assert_has(~s|#kbd-h-one[tabindex="-1"]|)
      |> assert_has(~s|#kbd-h-one[aria-selected="true"]|)
      |> assert_has("#kbd-h-one-panel", text: "One panel")
      |> press("#kbd-h-mid", "ArrowRight")
      |> A11y.assert_focused("kbd-h-two")
      |> assert_has(~s|#kbd-h-two[aria-selected="true"]|)
      |> assert_has("#kbd-h-two-panel", text: "Two panel")
    end

    test "Enter and Space on a focused disabled tab do not select it", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "ArrowRight")
      |> A11y.assert_focused("kbd-h-mid")
      |> press("#kbd-h-mid", "Enter")
      |> assert_has(~s|#kbd-h-mid[aria-selected="false"]|)
      |> assert_has(~s|#kbd-h-one[aria-selected="true"]|)
      |> press("#kbd-h-mid", "Space")
      |> assert_has(~s|#kbd-h-mid[aria-selected="false"]|)
      |> assert_has("#kbd-h-one-panel", text: "One panel")
    end

    test "ArrowLeft wraps from first to last", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "ArrowLeft")
      |> A11y.assert_focused("kbd-h-two")
    end

    test "Home and End jump to the first/last tab", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "End")
      |> A11y.assert_focused("kbd-h-two")
      |> press("#kbd-h-two", "Home")
      |> A11y.assert_focused("kbd-h-one")
    end

    test "vertical uses ArrowDown/ArrowUp", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-v-one", "ArrowDown")
      |> A11y.assert_focused("kbd-v-two")
      |> assert_has(~s|#kbd-v-two[aria-selected="true"]|)
    end

    # Pointer activation: clicking a tab must flip aria-selected (which drives
    # the active-indicator styling via the `aria-selected:` CSS variants) AND
    # swap the visible panel. Panel visibility is asserted by visible text, not
    # `[hidden]`, because Playwright locators don't match hidden elements.
    test "clicking a tab activates it and swaps the visible panel", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> assert_has(~s|#kbd-h-one[aria-selected="true"]|)
      |> assert_has("#kbd-h-one-panel", text: "One panel")
      |> click("#kbd-h-two")
      |> assert_has(~s|#kbd-h-two[aria-selected="true"]|)
      |> assert_has(~s|#kbd-h-one[aria-selected="false"]|)
      |> assert_has("#kbd-h-two-panel", text: "Two panel")
      |> refute_has("#kbd-h-one-panel", text: "One panel")
    end
  end
end
