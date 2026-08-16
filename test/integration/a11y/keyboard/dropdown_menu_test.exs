defmodule Pulsar.Integration.A11y.Keyboard.DropdownMenuTest do
  @moduledoc """
  Real-browser keyboard tests for DropdownMenu. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "DropdownMenu keyboard navigation" do
    # The fixture at `/keyboard/dropdown_menu` renders a trigger button
    # (kbd-dm-trigger) opening a `role="menu"` panel (kbd-dm) of items
    # (kbd-dm-profile, kbd-dm-settings) plus a submenu trigger
    # (kbd-dm-sub-trigger) owning a nested menu (kbd-dm-sub) with one item
    # (kbd-dm-email). The `.PulsarDropdownMenu` colocated hook drives roving
    # focus, opening from the trigger, and submenu navigation; open/close and
    # Escape come from the native `[popover]` it composes.
    # A third menu (kbd-dm3) holds disabled items for the reachable-but-inert tests.
    #
    # Verification: comment out the ArrowDown/ArrowUp branch in
    # `handleTriggerKeydown` of `.PulsarDropdownMenu` (priv/templates/
    # dropdown_menu.ex.eex and the synced lib file), run
    # `MIX_ENV=test mix assets.build`, re-run — the "ArrowDown opens" test
    # fails because the menu never opens from the keyboard.

    test "ArrowDown on the trigger opens the menu and focuses the first item", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm-trigger", "ArrowDown")
      |> assert_has(~s|#kbd-dm-trigger[aria-expanded="true"]|)
      |> assert_has(~s|#kbd-dm[data-state="open"]|)
      |> A11y.assert_focused("kbd-dm-profile")
    end

    test "clicking the trigger opens the menu and moves focus to the first item", %{conn: conn} do
      # The mouse path: a click opens the menu (and on Safari/Firefox the trigger
      # button isn't even focused on click), so the hook must move focus into the
      # menu on the toggle. Arrow keys then rove.
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> click("#kbd-dm-trigger")
      |> assert_has(~s|#kbd-dm[data-state="open"]|)
      |> A11y.assert_focused("kbd-dm-profile")
      |> press("#kbd-dm-profile", "ArrowDown")
      |> A11y.assert_focused("kbd-dm-settings")
    end

    test "Enter on the trigger opens the menu and moves focus to the first item", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm-trigger", "Enter")
      |> assert_has(~s|#kbd-dm[data-state="open"]|)
      |> A11y.assert_focused("kbd-dm-profile")
    end

    test "ArrowDown moves roving focus to the next item", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm-trigger", "ArrowDown")
      |> A11y.assert_focused("kbd-dm-profile")
      |> press("#kbd-dm-profile", "ArrowDown")
      |> A11y.assert_focused("kbd-dm-settings")
    end

    test "Escape closes the menu and restores focus to the trigger", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm-trigger", "Enter")
      |> assert_has(~s|#kbd-dm-trigger[aria-expanded="true"]|)
      |> press("#kbd-dm-profile", "Escape")
      |> assert_has(~s|#kbd-dm-trigger[aria-expanded="false"]|)
      |> A11y.assert_focused("kbd-dm-trigger")
    end

    test "ArrowRight on a submenu item opens its submenu and focuses the first child", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm-trigger", "ArrowDown")
      |> press("#kbd-dm-profile", "ArrowDown")
      |> press("#kbd-dm-settings", "ArrowDown")
      |> A11y.assert_focused("kbd-dm-sub-trigger")
      |> press("#kbd-dm-sub-trigger", "ArrowRight")
      |> A11y.assert_focused("kbd-dm-email")
    end

    # A link item must still navigate. The hook intercepts clicks on
    # [data-menu-item] to close the menu; if it ever preventDefault'd ordinary
    # activation, every link item — including a non-GET `method=` one — would
    # silently stop working while aria-expanded and the item markup still
    # looked correct.
    #
    # Verification: add `e.preventDefault()` to `handleClick` in
    # `.PulsarDropdownMenu` (priv/templates/dropdown_menu.ex.eex and the synced
    # lib file), run `MIX_ENV=test mix assets.build`, re-run — this fails
    # because the browser never leaves /keyboard/dropdown_menu.
    test "clicking a link item navigates to its href", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> click("#kbd-dm2-trigger")
      |> assert_has(~s|#kbd-dm2[data-state="open"]|)
      |> click("#kbd-dm2-nav")
      |> assert_path("/keyboard/menu")
      |> assert_has("#kbd-vmenu")
    end

    # Disabled items (kbd-dm3: Edit / Delete[disabled] / Share submenu[disabled]
    # / Archive[disabled]) must stay REACHABLE by every keyboard path — arrows,
    # Home/End, typeahead — so screen-reader users can discover them, while
    # activation (Enter/Space/click) and submenu opening stay blocked.
    test "arrow keys reach a disabled item; Enter and Space do not activate it", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm3-trigger", "ArrowDown")
      |> A11y.assert_focused("kbd-dm3-edit")
      |> press("#kbd-dm3-edit", "ArrowDown")
      |> A11y.assert_focused("kbd-dm3-delete")
      |> press("#kbd-dm3-delete", "Enter")
      |> assert_has(~s|#kbd-dm3[data-state="open"]|)
      |> assert_path("/keyboard/dropdown_menu")
      |> press("#kbd-dm3-delete", "Space")
      |> assert_has(~s|#kbd-dm3[data-state="open"]|)
      |> assert_path("/keyboard/dropdown_menu")
    end

    test "End lands on a disabled last item and typeahead reaches a disabled item", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm3-trigger", "ArrowDown")
      |> press("#kbd-dm3-edit", "End")
      |> A11y.assert_focused("kbd-dm3-archive")
      |> press("#kbd-dm3-archive", "Home")
      |> A11y.assert_focused("kbd-dm3-edit")
      |> press("#kbd-dm3-edit", "d")
      |> A11y.assert_focused("kbd-dm3-delete")
    end

    test "a disabled submenu trigger is reachable but never opens its submenu", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> press("#kbd-dm3-trigger", "ArrowDown")
      |> press("#kbd-dm3-edit", "ArrowDown")
      |> press("#kbd-dm3-delete", "ArrowDown")
      |> A11y.assert_focused("kbd-dm3-sub-trigger")
      |> press("#kbd-dm3-sub-trigger", "ArrowRight")
      |> A11y.refute_visible("kbd-dm3-email")
      |> press("#kbd-dm3-sub-trigger", "Enter")
      |> A11y.refute_visible("kbd-dm3-email")
    end

    # `dropdown_menu` renders its panel through `popover`, passing its own id
    # straight through, so `Popover.hide/1` closes the menu. The reopen guards
    # against a close that leaves the panel stranded in the top layer.

    test "Popover.hide closes the menu and the trigger still reopens it", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> click("#kbd-dm-trigger")
      |> A11y.assert_visible("kbd-dm")
      |> PhoenixTest.Playwright.evaluate(
        ~s|document.getElementById("kbd-dm").dispatchEvent(new CustomEvent("pulsar:popover-hide", {bubbles: true}))|
      )
      |> A11y.refute_visible("kbd-dm")
      |> assert_has(~s|#kbd-dm-trigger[aria-expanded="false"]|)
      |> click("#kbd-dm-trigger")
      |> A11y.assert_visible("kbd-dm")
    end
  end
end
