defmodule Pulsar.Integration.A11y.Keyboard.MenuTest do
  @moduledoc """
  Real-browser keyboard tests for Menu. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Menu keyboard navigation" do
    # The fixture at `/keyboard/menu` renders a vertical menu (items
    # kbd-v-home / kbd-v-inbox + a collapsed group kbd-v-grp) and a
    # horizontal menu with a dropdown group (kbd-h-grp). Behavior comes
    # from the `.PulsarMenu` colocated hook, which reads orientation from
    # the menu root's `data-orientation`.
    #
    # Verification: comment out the ArrowDown/ArrowUp branch in the
    # keydown handler of `.PulsarMenu` (see `lib/pulsar/components/menu.ex`,
    # near `handleKeydown`), rebuild assets, and re-run — the ArrowDown
    # test fails because focus stays on kbd-v-home.

    test "ArrowDown moves focus to the next item in a vertical menu",
         %{conn: conn} do
      conn
      |> visit("/keyboard/menu")
      |> A11y.await_live_connected()
      |> press("#kbd-v-home", "ArrowDown")
      |> A11y.assert_focused("kbd-v-inbox")
    end

    test "Enter on a group trigger expands the disclosure", %{conn: conn} do
      conn
      |> visit("/keyboard/menu")
      |> A11y.await_live_connected()
      |> press("#kbd-v-grp-trigger", "Enter")
      |> assert_has(~s|#kbd-v-grp-trigger[aria-expanded="true"]|)
    end

    test "Escape closes an open horizontal dropdown and restores focus to its trigger",
         %{conn: conn} do
      conn
      |> visit("/keyboard/menu")
      |> A11y.await_live_connected()
      |> press("#kbd-h-grp-trigger", "Enter")
      |> assert_has(~s|#kbd-h-grp-trigger[aria-expanded="true"]|)
      |> press("#kbd-h-grp-trigger", "Escape")
      |> assert_has(~s|#kbd-h-grp-trigger[aria-expanded="false"]|)
      |> A11y.assert_focused("kbd-h-grp-trigger")
    end
  end
end
