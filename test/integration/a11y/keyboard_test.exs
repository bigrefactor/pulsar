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

  describe "Calendar interaction" do
    test "clicking a day selects it and writes the hidden ISO value", %{conn: conn} do
      # Verify data-selected is flipped on the cell and the hidden input's value
      # is written. Hidden inputs are display:none — Playwright's assert_has checks
      # visibility, so we read the hidden input value via JS instead.
      session =
        conn
        |> visit("/keyboard/calendar")
        |> A11y.await_live_connected()
        |> click(~s|#kbd-cal [data-cal-day="2026-06-12"]|)
        |> assert_has(~s|#kbd-cal [data-cal-day="2026-06-12"][data-selected="true"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        "document.querySelector('#kbd-cal input[data-cal-value=\"single\"]').value",
        fn value ->
          assert value == "2026-06-12",
                 "expected hidden ISO input to have value '2026-06-12', got '#{value}'"
        end
      )
    end

    test "selecting a day notifies LiveView via phx-change (the dispatched input event)", %{conn: conn} do
      conn
      |> visit("/keyboard/calendar")
      |> A11y.await_live_connected()
      |> click(~s|#kbd-cal [data-cal-day="2026-06-12"]|)
      |> assert_has("#kbd-cal-received", text: "2026-06-12")
    end

    test "ArrowRight moves the focused cell and Enter selects it", %{conn: conn} do
      conn
      |> visit("/keyboard/calendar")
      |> A11y.await_live_connected()
      |> press(~s|#kbd-cal [data-cal-day="2026-06-10"]|, "ArrowRight")
      |> assert_has(~s|#kbd-cal [data-cal-day="2026-06-11"][tabindex="0"]|)
      |> press(~s|#kbd-cal [data-cal-day="2026-06-11"]|, "Enter")
      |> assert_has(~s|#kbd-cal [data-cal-day="2026-06-11"][data-selected="true"]|)
    end

    test "the disabled date cannot be selected", %{conn: conn} do
      # Disabled cells have aria-disabled="true" — Playwright's click will not
      # interact with them (it checks aria-disabled). Use JS to dispatch a raw
      # click event directly onto the cell, bypassing the actionability check, so
      # we can prove the click handler ignores the cell (data-selected stays false).
      session =
        conn
        |> visit("/keyboard/calendar")
        |> A11y.await_live_connected()

      assert_has(session, ~s|#kbd-cal [data-cal-day="2026-06-19"][data-disabled="true"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        "document.querySelector('#kbd-cal [data-cal-day=\"2026-06-19\"]').click()"
      )
      |> assert_has(~s|#kbd-cal [data-cal-day="2026-06-19"][data-selected="false"]|)
    end

    test "range mode: second click completes the range and marks in-between days", %{conn: conn} do
      conn
      |> visit("/keyboard/calendar")
      |> A11y.await_live_connected()
      |> click(~s|#kbd-cal-range [data-cal-day="2026-06-10"]|)
      |> click(~s|#kbd-cal-range [data-cal-day="2026-06-14"]|)
      |> assert_has(~s|#kbd-cal-range [data-cal-day="2026-06-10"][data-selected="true"]|)
      |> assert_has(~s|#kbd-cal-range [data-cal-day="2026-06-14"][data-selected="true"]|)
      |> assert_has(~s|#kbd-cal-range [data-cal-day="2026-06-12"][data-in-range="true"]|)
    end
  end

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

  describe "InputOTP keyboard entry" do
    # The real input is `#kbd-otp`; the painted slots live in the wrapper
    # `#kbd-otp-otp` ("{id}-otp"). The `.PulsarInputOtp` hook paints each
    # `[data-slot]` (char + data-filled) and marks the next empty slot active
    # on every keystroke — so these assertions only pass if the hook actually
    # received the keys.
    test "typing digits paints slots and auto-advances", %{conn: conn} do
      conn
      |> visit("/keyboard/input_otp")
      |> A11y.await_live_connected()
      |> press("#kbd-otp", "1")
      |> assert_has(~s|#kbd-otp-otp [data-slot="0"][data-filled="true"]|, text: "1")
      |> assert_has(~s|#kbd-otp-otp [data-slot="1"][data-active="true"]|)
      |> press("#kbd-otp", "2")
      |> assert_has(~s|#kbd-otp-otp [data-slot="1"][data-filled="true"]|, text: "2")
      |> assert_has(~s|#kbd-otp-otp [data-slot="2"][data-active="true"]|)
    end

    test "non-digits are ignored in numeric mode", %{conn: conn} do
      conn
      |> visit("/keyboard/input_otp")
      |> A11y.await_live_connected()
      |> press("#kbd-otp", "a")
      |> refute_has(~s|#kbd-otp-otp [data-slot="0"][data-filled="true"]|)
    end

    test "backspace clears the last digit", %{conn: conn} do
      conn
      |> visit("/keyboard/input_otp")
      |> A11y.await_live_connected()
      |> press("#kbd-otp", "1")
      |> press("#kbd-otp", "2")
      |> assert_has(~s|#kbd-otp-otp [data-slot="1"][data-filled="true"]|, text: "2")
      |> press("#kbd-otp", "Backspace")
      |> refute_has(~s|#kbd-otp-otp [data-slot="1"][data-filled="true"]|)
      |> assert_has(~s|#kbd-otp-otp [data-slot="0"][data-filled="true"]|, text: "1")
    end

    # Regression: the active-slot indicator tracks the caret, not value length.
    # After moving the caret into the middle of a partial code, the active ring
    # must mark the caret's slot (the real overwrite target). The old code keyed
    # off `v.length`, so it would have left slot 2 active here.
    test "moving the caret marks the caret's slot active, not next-empty", %{conn: conn} do
      conn
      |> visit("/keyboard/input_otp")
      |> A11y.await_live_connected()
      |> press("#kbd-otp", "1")
      |> press("#kbd-otp", "2")
      |> assert_has(~s|#kbd-otp-otp [data-slot="2"][data-active="true"]|)
      |> press("#kbd-otp", "ArrowLeft")
      |> assert_has(~s|#kbd-otp-otp [data-slot="1"][data-active="true"]|)
      |> refute_has(~s|#kbd-otp-otp [data-slot="2"][data-active="true"]|)
    end

    test "entering all six digits fires on_complete", %{conn: conn} do
      conn
      |> visit("/keyboard/input_otp")
      |> A11y.await_live_connected()
      |> press("#kbd-otp", "1")
      |> press("#kbd-otp", "2")
      |> press("#kbd-otp", "3")
      |> press("#kbd-otp", "4")
      |> press("#kbd-otp", "5")
      |> press("#kbd-otp", "6")
      |> assert_has("#kbd-otp-completes", text: "1")
    end

    # Regression: the painted slot boxes are an aria-hidden, pointer-transparent
    # overlay — clicking a box must fall through and focus the real input. (A
    # missing pointer-events-none made the boxes eat the click, so only Tab
    # focused the input, not a mouse click.)
    test "clicking a slot box focuses the real input", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/input_otp")
        |> A11y.await_live_connected()

      hit_test = """
      (() => {
        const slot = document.querySelector('#kbd-otp-otp [data-slot="0"]');
        const r = slot.getBoundingClientRect();
        const el = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
        return el && el.hasAttribute('data-otp-input') ? 'input' : 'blocked';
      })()
      """

      PhoenixTest.Playwright.evaluate(session, hit_test, fn hit ->
        assert hit == "input",
               "expected a click over a slot box to reach the real input, but the slot layer intercepted it (#{inspect(hit)}); the slot overlay must be pointer-events-none"
      end)

      session
      |> PhoenixTest.Playwright.click("#kbd-otp")
      |> A11y.assert_focused("kbd-otp")
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

  describe "Tabs keyboard navigation" do
    # The fixture at `/keyboard/tabs` renders a horizontal tablist
    # (kbd-h-one / kbd-h-mid [disabled] / kbd-h-two) and a vertical
    # tablist (kbd-v-one / kbd-v-two). Roving focus + arrow/Home/End
    # navigation and the active-tab selection sync come from the
    # `.PulsarTabs` colocated hook, which reads orientation from the
    # tabs root's `data-orientation`.
    #
    # Verification: comment out the ArrowRight/ArrowLeft branch in the
    # keydown handler of `.PulsarTabs` (see `lib/pulsar/components/tabs.ex`,
    # near the orientation/arrow handling), run `MIX_ENV=test mix
    # assets.build`, re-run — the ArrowRight test fails because focus and
    # selection stay on kbd-h-one.

    test "ArrowRight moves focus + selection and skips disabled", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "ArrowRight")
      |> A11y.assert_focused("kbd-h-two")
      |> assert_has(~s|#kbd-h-two[aria-selected="true"]|)
      |> assert_has(~s|#kbd-h-one[aria-selected="false"]|)
    end

    test "ArrowLeft wraps from first to last", %{conn: conn} do
      conn
      |> visit("/keyboard/tabs")
      |> A11y.await_live_connected()
      |> press("#kbd-h-one", "ArrowLeft")
      |> A11y.assert_focused("kbd-h-two")
    end

    test "Home and End jump to first/last enabled tab", %{conn: conn} do
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

  describe "DropdownMenu keyboard navigation" do
    # The fixture at `/keyboard/dropdown_menu` renders a trigger button
    # (kbd-dm-trigger) opening a `role="menu"` panel (kbd-dm) of items
    # (kbd-dm-profile, kbd-dm-settings) plus a submenu trigger
    # (kbd-dm-sub-trigger) owning a nested menu (kbd-dm-sub) with one item
    # (kbd-dm-email). The `.PulsarDropdownMenu` colocated hook drives roving
    # focus, opening from the trigger, and submenu navigation; open/close and
    # Escape come from the native `[popover]` it composes.
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
  end

  describe "Modal keyboard behavior" do
    # The fixture at `/keyboard/modal` renders a trigger button
    # (kbd-modal-open) that opens a native `<dialog>` (kbd-modal) via the
    # `.PulsarModal` colocated hook's `showModal()`. The dialog autofocuses
    # its text input (kbd-modal-input); the browser provides the modal focus
    # trap and Escape handling, and restores focus to the opener on close. A
    # second, `dismissable={false}` dialog (kbd-modal-locked) ignores Escape.
    #
    # Verification: comment out the `showModal()` call in the `.PulsarModal`
    # hook's `open()` (priv/templates/modal.ex.eex and the synced lib file),
    # run `MIX_ENV=test mix assets.build`, re-run — the open assertions fail.

    test "opening shows a modal dialog and moves focus inside", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-open", "Enter")
      |> assert_has(~s|#kbd-modal[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal")
      |> A11y.assert_focused("kbd-modal-input")
    end

    test "Escape closes a dismissable dialog and restores focus to the opener", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-open", "Enter")
      |> assert_has(~s|#kbd-modal[data-state="open"]|)
      |> press("#kbd-modal-input", "Escape")
      |> A11y.assert_focused("kbd-modal-open")
    end

    test "a non-dismissable dialog ignores Escape and stays open", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-locked-open", "Enter")
      |> assert_has(~s|#kbd-modal-locked[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal-locked")
      |> press("#kbd-modal-locked-input", "Escape")
      |> assert_has(~s|#kbd-modal-locked[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal-locked")
    end
  end

  describe "Drawer backdrop dismissal" do
    # The fixture at `/keyboard/drawer` mirrors the storybook drawer template:
    # the trigger and the drawer share one wrapper carrying the open dispatcher
    # (`phx-click={Drawer.open("kbd-drawer")}`). A backdrop click on the open
    # dialog bubbles up to that wrapper, so unless the `.PulsarModal` hook stops
    # the click after dismissing, the drawer closes and the bubbled click
    # immediately re-opens it — the reported "clicking outside does nothing" bug.
    #
    # Verification: drop the `e.stopPropagation()` line from `handleClick` in
    # `priv/templates/modal.ex.eex` (and the synced lib file), run
    # `MIX_ENV=test mix assets.build`, re-run — the dialog re-opens after the
    # backdrop click and the assertion fails.

    test "a backdrop click closes the drawer and does not re-open it", %{conn: conn} do
      conn
      |> visit("/keyboard/drawer")
      |> A11y.await_live_connected()
      |> click("#kbd-drawer-open")
      |> assert_has(~s|#kbd-drawer[data-state="open"]|)
      |> A11y.assert_modal("kbd-drawer")
      |> dispatch_backdrop_click("kbd-drawer")
      |> assert_dialog_closed("kbd-drawer")
    end
  end

  describe "Accordion interaction" do
    # The fixture at `/keyboard/accordion` renders a single-mode accordion
    # (`kbd-acc`) with headers kbd-acc-{one,two,three}-header, item two disabled,
    # and unique panel bodies kbd-acc-{one,three}-body. Behavior comes from the
    # `.PulsarAccordion` colocated hook.
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

    test "the disabled header renders disabled and its panel stays closed", %{conn: conn} do
      # A real <button disabled> can't be clicked (the browser blocks it), so the
      # closed state is asserted directly; keyboard-skip of the disabled header is
      # covered by the ArrowDown test below.
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> assert_has(~s|#kbd-acc-two-header[disabled][aria-expanded="false"]|)
      |> A11y.refute_visible("kbd-acc-two-body")
    end

    test "ArrowDown moves focus to the next enabled header (skips disabled)", %{conn: conn} do
      conn
      |> visit("/keyboard/accordion")
      |> A11y.await_live_connected()
      |> press("#kbd-acc-one-header", "ArrowDown")
      |> A11y.assert_focused("kbd-acc-three-header")
    end
  end

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

  # Dispatches a realistic backdrop click on the open dialog `id`: a
  # mousedown + click whose pointer lands outside the panel box (the modal hook
  # requires both the down and the click to target the dialog itself, which is
  # how the browser reports a `::backdrop` click). The coordinates are derived
  # from the live panel rect, so this works regardless of which edge the drawer
  # is anchored to or whether the slide-in animation has settled.
  defp dispatch_backdrop_click(conn, id) do
    expr = """
    (() => {
      const dlg = document.getElementById(#{Jason.encode!(id)});
      const r = dlg.getBoundingClientRect();
      const x = Math.max(2, Math.round(r.left / 2));
      const y = Math.round((r.top + r.bottom) / 2);
      const init = {bubbles: true, cancelable: true, view: window, clientX: x, clientY: y, button: 0};
      dlg.dispatchEvent(new MouseEvent("mousedown", init));
      dlg.dispatchEvent(new MouseEvent("click", init));
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr)
  end

  # Asserts the dialog `id` is closed (`HTMLDialogElement.open === false`).
  # Reads `.open` directly rather than `data-state`, because the bug's
  # fingerprint is `open === true` while `data-state` has already flipped to
  # "closed" (the close event fires after the bubbled re-open).
  defp assert_dialog_closed(conn, id) do
    expr = "Boolean(document.getElementById(#{Jason.encode!(id)}).open)"

    PhoenixTest.Playwright.evaluate(conn, expr, fn open? ->
      if open? do
        raise ExUnit.AssertionError,
          message: "expected ##{id} to be closed after a backdrop click, but it re-opened"
      end
    end)
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

  describe "DatePicker interaction" do
    # The fixture at `/keyboard/date_picker` renders a single-mode DatePicker
    # (kbd-dp) with a fixed June 2026 window. The DatePicker composes a
    # Popover (kbd-dp-pop) wrapping a Calendar (kbd-dp-cal). Clicking the
    # calendar-icon button opens the popover; clicking a day writes the ISO
    # value into the hidden input; typing a date in the display input and
    # blurring parses it back to ISO. Behavior comes from `.PulsarDatePicker`
    # (type-in + calendar sync) and `.PulsarCalendar` (day selection).
    #
    # Verification: comment out the `syncFromCalendar` call in `_onCalClick`
    # in `.PulsarDatePicker` (priv/templates/date_picker.ex.eex and synced lib),
    # run `MIX_ENV=test mix assets.build`, re-run — the calendar-click test
    # fails because the hidden ISO input stays empty after clicking a day.

    test "picking a day in the popover fills the hidden ISO input", %{conn: conn} do
      # Hidden inputs are display:none — Playwright's assert_has checks visibility,
      # so read the hidden input value via JS (same pattern as Calendar tests).
      session =
        conn
        |> visit("/keyboard/date_picker")
        |> A11y.await_live_connected()
        |> click(~s|#kbd-dp [aria-label="Open calendar"]|)
        |> assert_has(~s|#kbd-dp-pop[data-state="open"]|)
        |> A11y.await_animations("kbd-dp-pop")
        |> click(~s|#kbd-dp-cal [data-cal-day="2026-06-15"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        "document.querySelector('#kbd-dp input[data-dp-value=\"single\"]').value",
        fn value ->
          assert value == "2026-06-15",
                 "expected hidden ISO input to have value '2026-06-15', got '#{value}'"
        end
      )
    end

    test "typing a date writes the hidden ISO value", %{conn: conn} do
      # The hook parses on the 'change' event (not 'input'), and fill_in may not
      # fire change on blur, so set the value and dispatch 'change' via JS so the
      # hook's _onChange handler parses the typed date into ISO. en-US: MM/DD/YYYY.
      type_script = """
      (() => {
        const el = document.querySelector('#kbd-dp [data-dp-display="single"]');
        el.value = '06/22/2026';
        el.dispatchEvent(new Event('change', { bubbles: true }));
      })()
      """

      session =
        conn
        |> visit("/keyboard/date_picker")
        |> A11y.await_live_connected()

      PhoenixTest.Playwright.evaluate(session, type_script)

      PhoenixTest.Playwright.evaluate(
        session,
        "document.querySelector('#kbd-dp input[data-dp-value=\"single\"]').value",
        fn value ->
          assert value == "2026-06-22",
                 "expected hidden ISO input to have value '2026-06-22', got '#{value}'"
        end
      )
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
