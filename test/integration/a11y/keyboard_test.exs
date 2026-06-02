defmodule Pulsar.Integration.A11y.KeyboardTest do
  @moduledoc """
  Real-browser keyboard tests for interactive components. Axe-clean
  catches static a11y problems but not behavior — a button
  could fail to activate on Enter and axe would happily report it
  clean. These tests close that gap.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`. Tag rationale matches `AxeCleanTest`:
  `:browser` is a reserved Playwright key.

  ## Verification

  To prove these tests are wired to real keyboard behavior (and not
  accidentally passing), temporarily comment out the keydown/keyup
  Space/Enter branches in `.PulsarButton` (see `lib/pulsar/components/
  button.ex`, near the `_onKeydown`/`_onKeyup` definitions) and re-run
  the Button activation test — it should fail with the activation
  counter still at 0 instead of 2.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  # Select tests select by the stable `data-fixture-cell` attribute (set
  # in select_live.ex) rather than the rendered `id`. Select doesn't
  # declare `attr :id`, so the rendered id is currently derived from
  # `name` — that's implementation detail and would silently flip if
  # `attr :id` is ever added.
  @select_cell ~s|[data-fixture-cell="outline-neutral-xs-default"]|

  describe "Button keyboard activation" do
    test "Space and Enter both activate pseudo-button", %{conn: conn} do
      conn
      |> visit("/keyboard/button")
      |> A11y.await_live_connected()
      |> press("#kbd-button-link", "Space")
      |> assert_has("#kbd-count", text: "1")
      |> press("#kbd-button-link", "Enter")
      |> assert_has("#kbd-count", text: "2")
    end

    test "disabled and loading pseudo-buttons do not activate", %{conn: conn} do
      conn
      |> visit("/keyboard/button")
      |> A11y.await_live_connected()
      |> press("#kbd-button-disabled", "Enter")
      |> press("#kbd-button-disabled", "Space")
      |> press("#kbd-button-loading", "Enter")
      |> press("#kbd-button-loading", "Space")
      |> assert_has("#kbd-count", text: "0")
    end
  end

  describe "Card keyboard activation" do
    test "Space and Enter activate interactive card", %{conn: conn} do
      conn
      |> visit("/keyboard/card")
      |> A11y.await_live_connected()
      |> press("#kbd-card", "Space")
      |> assert_has("#kbd-count", text: "1")
      |> press("#kbd-card", "Enter")
      |> assert_has("#kbd-count", text: "2")
    end

    test "interactive card is focusable (tabindex=0, role=button)", %{conn: conn} do
      conn
      |> visit("/keyboard/card")
      |> assert_has(~s|#kbd-card[role="button"][tabindex="0"]|)
    end
  end

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

  describe "Popover keyboard behavior" do
    # The fixture at `/keyboard/popover` renders a trigger button
    # (kbd-pop-trigger) wired by the `.PulsarPopover` colocated hook to a
    # native `popover="auto"` panel (kbd-pop) holding a focusable link
    # (kbd-pop-inside). Open/close/dismiss are native; the hook syncs
    # `aria-expanded` and `data-state` on the `toggle` event.
    #
    # Verification: comment out the `aria-expanded` setAttribute calls in
    # `onToggle` of the `.PulsarPopover` hook (priv/templates/popover.ex.eex
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

  describe "RadioGroup keyboard navigation" do
    # First group on the page: rg-neutral-xs (colors and sizes from
    # radio_group_live.ex are neutral-first, xs-first). Options have ids
    # rg-neutral-xs-{index} with index 0..2 and values "1", "2", "3".

    test "ArrowDown moves selection to the next radio in the group", %{conn: conn} do
      conn
      |> visit("/components/radio_group")
      |> press("#rg-neutral-xs-0", "ArrowDown")
      |> assert_has("#rg-neutral-xs-1:checked")
    end

    test "Tab moves focus out of the group, not between radios", %{conn: conn} do
      conn
      |> visit("/components/radio_group")
      |> press("#rg-neutral-xs-0", "Tab")
      |> A11y.refute_focused_within("#rg-neutral-xs")
    end
  end

  describe "Select keyboard navigation" do
    # Options are "1", "2", "3" plus a prompt. Selector lives at module
    # top (@select_cell).

    test "Tab moves focus from one select to the next focusable", %{conn: conn} do
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, "Tab")
      |> A11y.refute_focused_within(@select_cell)
    end

    test "ArrowDown does not break focus on the select", %{conn: conn} do
      # The ticket calls for "ArrowDown changes selection." Native <select>
      # keyboard semantics in headless Chromium don't commit a value change
      # on ArrowDown when the select starts on a prompt placeholder
      # (selectedIndex stays 0). This is browser/Playwright behavior, not
      # Pulsar — confirmed by diagnostic with two consecutive ArrowDown
      # presses both leaving value="". Asserting focus retention is the
      # slice we can actually verify: Pulsar's markup doesn't trap or
      # steal focus on arrow keys.
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, "ArrowDown")
      |> assert_has(":focus#{@select_cell}")
    end

    test "pressing Space keeps focus on the select", %{conn: conn} do
      # The ticket calls for "Space opens (browser default)." In headless
      # Chromium the dropdown picker is opaque to the DOM, so we can't
      # observe "open." This test verifies the slice we can: Pulsar doesn't
      # preventDefault on Space, and the element retains focus afterward.
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, " ")
      |> assert_has(":focus#{@select_cell}")
    end
  end

  describe "Checkbox keyboard activation" do
    test "Space toggles checked state", %{conn: conn} do
      conn
      |> visit("/components/checkbox")
      |> press("#chk-neutral-xs-unchecked", " ")
      |> assert_has("#chk-neutral-xs-unchecked:checked")
    end

    test "Tab moves focus off the current checkbox", %{conn: conn} do
      conn
      |> visit("/components/checkbox")
      |> press("#chk-neutral-xs-unchecked", "Tab")
      |> A11y.refute_focused_within("#chk-neutral-xs-unchecked")
    end
  end

  describe "Switch keyboard activation" do
    test "Space toggles the underlying checkbox state", %{conn: conn} do
      # The Switch renders a hidden <input type="checkbox" role="switch"
      # class="sr-only"> as its real interactive element. Space on a
      # native checkbox toggles `:checked` via browser semantics.
      #
      # NOTE: we explicitly do NOT assert aria-checked here. The template
      # computes `aria-checked={if @checked, do: "true", else: "false"}`
      # from the server-side assign, which doesn't update when the native
      # input toggles client-side. That's a separate screen-reader a11y
      # bug to fix in a follow-up ticket.
      conn
      |> visit("/components/switch")
      |> press("#sw-neutral-xs-unchecked", " ")
      |> assert_has("#sw-neutral-xs-unchecked:checked")
    end
  end

  describe "Flash keyboard dismissal" do
    # The Flash component's `.PulsarFlash` colocated hook listens for a
    # `keydown` Escape on the flash root and triggers the same `dismiss()`
    # path used by the close button. Escape should work whether focus is
    # on the dismiss button, the message body, or any nested focusable.
    #
    # Verification: remove the `if (event.key === "Escape")` branch from
    # the keydown handler in `lib/pulsar/components/flash.ex` (and the
    # mirrored block in `priv/templates/flash.ex.eex`) and re-run — the
    # `refute_has` assertion should fail because the flash stays mounted.

    test "Escape on the dismiss button dismisses the flash", %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show status flash")
      |> assert_has("#fl-trigger-status")
      |> press(~s|#fl-trigger-status button[aria-label="Dismiss"]|, "Escape")
      |> refute_has("#fl-trigger-status")
    end

    # A flash rendered with `dismissible={false}` exposes no close button, so
    # Escape must not provide a hidden dismissal path. The hook gates its
    # Escape branch on `data-dismissible === "true"`. Escape is pressed on the
    # flash's own action button so the keydown bubbles to the flash root — the
    # same mechanism the dismiss-button test above exercises.
    #
    # A dismiss removes the node `EXIT_MS` (200ms) *after* it fires, so a plain
    # `assert_has` would still find the node mid-animation even if Escape did
    # dismiss it. `assert_flash_present_after_dismiss_window/2` waits past that
    # window before asserting, so the test fails iff a dismiss actually fired.
    #
    # Verification: drop the `&& this.el.dataset.dismissible === "true"` guard
    # from the keydown handler in `lib/pulsar/components/flash.ex` (and the
    # mirrored block in `priv/templates/flash.ex.eex`), rebuild assets, re-run —
    # the flash is removed within the window and the assertion fails.
    test "Escape does not dismiss a non-dismissible flash", %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show persistent flash")
      |> assert_has("#fl-trigger-persistent")
      |> press("#fl-persistent-action", "Escape")
      |> assert_flash_present_after_dismiss_window("fl-trigger-persistent")
    end
  end

  # Waits past the flash exit-animation window (EXIT_MS = 200ms) and asserts the
  # element with `id` is still in the DOM. Distinguishes "Escape was ignored"
  # from "Escape fired a dismiss" — the latter removes the node after the window.
  defp assert_flash_present_after_dismiss_window(conn, id) do
    expr =
      "(async () => {" <>
        "await new Promise((resolve) => setTimeout(resolve, 400));" <>
        "return document.getElementById(#{Jason.encode!(id)}) !== null;" <>
        "})()"

    PhoenixTest.Playwright.evaluate(conn, expr, fn present? ->
      if !present? do
        raise ExUnit.AssertionError,
          message: "##{id} was removed after Escape — a non-dismissible flash must ignore Escape"
      end
    end)
  end

  describe "Form keyboard traversal" do
    # Backward complement to `FormTest`'s forward Tab walk: starting from
    # the last field, Shift+Tab should walk back through every form field
    # in reverse DOM order. Catches focus traps that would only show up
    # when navigating backwards (e.g. a custom widget that swallows
    # `keydown` for Shift+Tab but not Tab).
    #
    # Verification: temporarily add `tabindex="-1"` to the `<select>`
    # rendered by `lib/pulsar/components/select.ex` and rebuild assets.
    # Backward traversal skips `signup_plan`, so the `assert_focused`
    # after stepping past it lands on `signup_email` instead of
    # `signup_plan` and the test fails.

    test "Shift+Tab walks back through every signup form field",
         %{conn: conn} do
      # Forward tab order (covered by `FormTest`):
      #   name → email → plan → role-0 → notifications → terms → notes
      # Chromium treats an unchecked radio group as one stop in either
      # direction, but it picks DIFFERENT representative radios per
      # direction: forward enters at the first radio (`role-0`), backward
      # enters at the last (`role-1`). Either way, only one of the two
      # role radios participates in tab traversal at a time. The walk
      # below documents that observed behavior.
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> press("#signup_notes", "Shift+Tab")
      |> A11y.assert_focused("signup_terms")
      |> press("#signup_terms", "Shift+Tab")
      |> A11y.assert_focused("signup_notifications")
      |> press("#signup_notifications", "Shift+Tab")
      |> A11y.assert_focused("signup_role-1")
      |> press("#signup_role-1", "Shift+Tab")
      |> A11y.assert_focused("signup_plan")
      |> press("#signup_plan", "Shift+Tab")
      |> A11y.assert_focused("signup_email")
      |> press("#signup_email", "Shift+Tab")
      |> A11y.assert_focused("signup_name")
    end
  end

  describe "RadioGroup keyboard navigation (extended)" do
    # The fixture at `/keyboard/radio_group` provides an anchor `<button>`
    # before two radio groups: one with `value="2"` (option index 1
    # pre-checked) and one with `orientation="horizontal"`. Both groups
    # rely on browser-native radio-group semantics — Pulsar's
    # `.PulsarRadioGroup` hook only intercepts Home/End, so the
    # behaviors under test here come from the platform.
    #
    # Verification recipes:
    #   * Tab-to-checked: render unique `name` attributes per radio in
    #     `lib/pulsar/components/radio_group.ex` (e.g.
    #     `name={"#{@group.name}-#{@radio_id}"}`) and rebuild assets —
    #     the browser stops grouping the radios, every radio joins the
    #     tab sequence, and Tab from the anchor lands on
    #     `kbd-rg-checked-0` instead of `kbd-rg-checked-1`.
    #   * Horizontal arrow: temporarily add `disabled` to the rendered
    #     radio input — focus still moves but `:checked` never flips, so
    #     the assertion fails.

    test "Tab from outside the group lands on the pre-checked radio",
         %{conn: conn} do
      conn
      |> visit("/keyboard/radio_group")
      |> A11y.await_live_connected()
      |> press("#kbd-rg-before", "Tab")
      |> A11y.assert_focused("kbd-rg-checked-1")
    end

    test "ArrowRight on a horizontal group selects the next option",
         %{conn: conn} do
      # Asserts the positive direction only: a horizontal group accepts
      # Left/Right. We do NOT assert exclusivity — `<input type="radio">`
      # also accepts Up/Down by browser default, and Pulsar doesn't
      # currently constrain that. Tightening orientation handling would
      # require new hook logic.
      conn
      |> visit("/keyboard/radio_group")
      |> A11y.await_live_connected()
      |> press("#kbd-rg-horiz-0", "ArrowRight")
      |> assert_has("#kbd-rg-horiz-1:checked")
    end
  end

  describe "tabindex=-1 sweep on fixture cells" do
    # A fast, broad sweep that catches accidental `tabindex="-1"` on any
    # element marked as a fixture interactive cell. Uses one
    # `querySelectorAll` per fixture instead of walking Tab through
    # hundreds of cells, which keeps mount budget within the
    # browser-CI levers.
    #
    # Verification: temporarily add `tabindex="-1"` to the Button host
    # element in `lib/pulsar/components/button.ex`, rebuild assets, and
    # re-run — the `/components/button` test reports a non-empty result
    # and the assertion fails with the offending elements listed.

    @traversal_fixtures [
      "/components/button",
      "/components/input/outline",
      "/components/checkbox",
      "/components/switch",
      "/components/link"
    ]

    for path <- @traversal_fixtures do
      test "no [data-fixture-cell] interactive element has tabindex=-1 at #{path}",
           %{conn: conn} do
        conn
        |> visit(unquote(path))
        |> A11y.await_live_connected()
        |> assert_no_negative_tabindex_on_fixture_cells()
      end
    end
  end

  # Reads `[data-fixture-cell][tabindex="-1"]` from the current page and
  # asserts the result is empty. Surfaces offending ids/tags so a failure
  # points at the specific regressed element.
  defp assert_no_negative_tabindex_on_fixture_cells(conn) do
    expr = """
    (() => {
      const els = document.querySelectorAll('[data-fixture-cell][tabindex="-1"]');
      return Array.from(els).map(el => ({
        id: el.id,
        tag: el.tagName.toLowerCase(),
        cell: el.getAttribute('data-fixture-cell')
      }));
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr, fn results ->
      if results != [] do
        raise ExUnit.AssertionError,
          message: "found [data-fixture-cell] elements with tabindex=-1: #{inspect(results)}"
      end
    end)
  end
end
