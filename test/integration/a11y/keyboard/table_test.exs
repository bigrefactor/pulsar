defmodule Pulsar.Integration.A11y.Keyboard.TableTest do
  @moduledoc """
  Real-browser keyboard tests for Table rows. Axe-clean catches static a11y
  problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Table row keyboard activation" do
    test "Space and Enter select clickable rows", %{conn: conn} do
      conn
      |> visit("/keyboard/table")
      |> A11y.await_live_connected()
      |> press("#kbd-table-row-0", "Space")
      |> assert_has("#kbd-table-selection", text: "Ada")
      |> press("#kbd-table-row-1", "Enter")
      |> assert_has("#kbd-table-selection", text: "Grace")
    end

    test "row click listener follows updates without duplicate activation", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/table")
        |> A11y.await_live_connected()
        |> assert_has(~s|#kbd-table-lifecycle-row-0[data-row-click="false"]|)
        |> click("#kbd-table-toggle-row-click")
        |> assert_has(~s|#kbd-table-lifecycle-row-0[data-row-click="true"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const row = document.getElementById("kbd-table-lifecycle-row-0");
          const event = new KeyboardEvent("keydown", {bubbles: true, cancelable: true, code: "Space", key: " "});
          row.dispatchEvent(event);
          return event.defaultPrevented;
        })()
        """,
        fn default_prevented ->
          assert default_prevented
        end
      )

      session =
        session
        |> press("#kbd-table-lifecycle-row-0", "Space")
        |> assert_has("#kbd-table-selection", text: "Ada")
        |> assert_has("#kbd-table-activation-count", text: "1")
        |> click("#kbd-table-toggle-row-click")
        |> assert_has(~s|#kbd-table-lifecycle-row-0[data-row-click="false"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const row = document.getElementById("kbd-table-lifecycle-row-0");
          const event = new KeyboardEvent("keydown", {bubbles: true, cancelable: true, code: "Space", key: " "});
          row.dispatchEvent(event);
          return event.defaultPrevented;
        })()
        """,
        fn default_prevented ->
          refute default_prevented
        end
      )

      session
      |> click("#kbd-table-toggle-row-click")
      |> assert_has(~s|#kbd-table-lifecycle-row-0[data-row-click="true"]|)
      |> click("#kbd-table-toggle-row-click")
      |> assert_has(~s|#kbd-table-lifecycle-row-0[data-row-click="false"]|)
      |> click("#kbd-table-toggle-row-click")
      |> assert_has(~s|#kbd-table-lifecycle-row-1[data-row-click="true"]|)
      |> press("#kbd-table-lifecycle-row-1", "Enter")
      |> assert_has("#kbd-table-selection", text: "Grace")
      |> assert_has("#kbd-table-activation-count", text: "2")
    end
  end
end
