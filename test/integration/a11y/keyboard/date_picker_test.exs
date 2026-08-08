defmodule Pulsar.Integration.A11y.Keyboard.DatePickerTest do
  @moduledoc """
  Real-browser keyboard tests for DatePicker. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "DatePicker interaction" do
    # The fixture at `/keyboard/date_picker` renders a single-mode DatePicker
    # with id "kbd-dp". After Fix 3 the container div carries id="kbd-dp-dp"
    # and the display input carries id="kbd-dp" (labelable). The DatePicker
    # composes a Popover (kbd-dp-pop) wrapping a Calendar (kbd-dp-cal).
    # Clicking the calendar-icon button opens the popover; clicking a day writes
    # the ISO value into the hidden input; typing a date in the display input and
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
      # After Fix 3: container id is kbd-dp-dp; display input id is kbd-dp.
      session =
        conn
        |> visit("/keyboard/date_picker")
        |> A11y.await_live_connected()
        |> click(~s|#kbd-dp-dp [aria-label="Open calendar"]|)
        |> assert_has(~s|#kbd-dp-pop[data-state="open"]|)
        |> A11y.await_animations("kbd-dp-pop")
        # The data-state flip alone can pass while the panel stays hidden (per
        # CLAUDE.md); assert the popover is actually visible before selecting.
        |> A11y.assert_visible("kbd-dp-pop")
        |> click(~s|#kbd-dp-cal [data-cal-day="2026-06-15"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        "document.querySelector('#kbd-dp-dp input[data-dp-value=\"single\"]').value",
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
      # After Fix 3: display input id is kbd-dp (it IS the display input).
      type_script = """
      (() => {
        const el = document.getElementById('kbd-dp');
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
        "document.querySelector('#kbd-dp-dp input[data-dp-value=\"single\"]').value",
        fn value ->
          assert value == "2026-06-22",
                 "expected hidden ISO input to have value '2026-06-22', got '#{value}'"
        end
      )
    end

    test "typing a date in en-GB locale writes the correct hidden ISO value", %{conn: conn} do
      # en-GB field order is day/month/year (d/m/y). Input "22/06/2026" must
      # parse to ISO "2026-06-22". Uses a separate fixture instance (kbd-dp-gb)
      # with locale="en-GB" so the hook's fieldOrder() uses en-GB ordering.
      # After Fix 3: container id is kbd-dp-gb-dp; display input id is kbd-dp-gb.
      type_script = """
      (() => {
        const el = document.getElementById('kbd-dp-gb');
        el.value = '22/06/2026';
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
        "document.querySelector('#kbd-dp-gb-dp input[data-dp-value=\"single\"]').value",
        fn value ->
          assert value == "2026-06-22",
                 "expected en-GB typed '22/06/2026' to produce ISO '2026-06-22', got '#{value}'"
        end
      )
    end
  end
end
