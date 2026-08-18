defmodule Pulsar.Integration.A11y.Keyboard.InputOtpTest do
  @moduledoc """
  Real-browser keyboard tests for InputOTP. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

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

  describe "InputOTP paste" do
    # Regression: a `maxlength` sized to the code length clipped a grouped
    # paste before the hook could strip the separator, so `ABCDE-FGHJK` landed
    # as nine characters and the field looked full.
    #
    # This has to go through `execCommand("insertText")`: it routes the value
    # through the browser's insertion path, which is where the truncation
    # happened. `fill_in` assigns `.value` directly and sails past any
    # `maxlength`, so it would pass against the broken component.
    test "a separator-bearing paste keeps every code character", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/input_otp")
        |> A11y.await_live_connected()

      paste = """
      (() => {
        const input = document.querySelector('#kbd-otp-grouped');
        input.focus();
        input.setSelectionRange(0, input.value.length);
        document.execCommand('insertText', false, 'ABCDE-FGHJK');
        return input.value;
      })()
      """

      PhoenixTest.Playwright.evaluate(session, paste, fn value ->
        assert value == "ABCDEFGHJK",
               "expected the hook to strip the separator and keep all ten code characters, got #{inspect(value)}"
      end)

      session
      |> assert_has(~s|#kbd-otp-grouped-otp [data-slot="0"][data-filled="true"]|, text: "A")
      |> assert_has(~s|#kbd-otp-grouped-otp [data-slot="5"][data-filled="true"]|, text: "F")
      |> assert_has(~s|#kbd-otp-grouped-otp [data-slot="9"][data-filled="true"]|, text: "K")
    end
  end
end
