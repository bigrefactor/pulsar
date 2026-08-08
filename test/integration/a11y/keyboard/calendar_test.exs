defmodule Pulsar.Integration.A11y.Keyboard.CalendarTest do
  @moduledoc """
  Real-browser keyboard tests for Calendar. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

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
end
