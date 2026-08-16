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

    test "nested action buttons keep their keyboard activation", %{conn: conn} do
      conn
      |> visit("/keyboard/table")
      |> A11y.await_live_connected()
      |> press("#kbd-table-action-ada", "Enter")
      |> assert_has("#kbd-table-action-selection", text: "Ada")
      |> assert_has("#kbd-table-action-count", text: "1")
      |> assert_has("#kbd-table-selection", text: "None")
      |> assert_has("#kbd-table-activation-count", text: "0")
      |> press("#kbd-table-action-ada", "Space")
      |> assert_has("#kbd-table-action-count", text: "2")
      |> assert_has("#kbd-table-selection", text: "None")
      |> assert_has("#kbd-table-activation-count", text: "0")
    end

    test "a plain nested link does not activate its clickable row", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/table")
        |> A11y.await_live_connected()
        |> press("#kbd-table-link-ada", "Enter")
        |> assert_has("#kbd-table-selection", text: "None")
        |> assert_has("#kbd-table-activation-count", text: "0")

      PhoenixTest.Playwright.evaluate(session, "window.location.hash", fn hash ->
        assert hash == "#plain-link-target"
      end)
    end

    test "keypad Enter activates a clickable row", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/table")
        |> A11y.await_live_connected()

      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const row = document.getElementById("kbd-table-row-0");
          row.focus();
          row.dispatchEvent(new KeyboardEvent("keydown", {
            bubbles: true,
            cancelable: true,
            code: "NumpadEnter",
            key: "Enter"
          }));
        })()
        """
      )

      session
      |> assert_has("#kbd-table-selection", text: "Ada")
      |> assert_has("#kbd-table-activation-count", text: "1")
    end

    test "Space and Enter cycle a sortable column header", %{conn: conn} do
      conn
      |> visit("/keyboard/table")
      |> A11y.await_live_connected()
      |> assert_has(~s|#kbd-table-sortable th[aria-sort="none"] .hero-chevron-up-down|)
      |> press(~s|#kbd-table-sortable thead button|, "Enter")
      |> assert_has(~s|#kbd-table-sortable th[aria-sort="ascending"] .hero-chevron-up|)
      |> press(~s|#kbd-table-sortable thead button|, "Space")
      |> assert_has(~s|#kbd-table-sortable th[aria-sort="descending"] .hero-chevron-down|)
      |> press(~s|#kbd-table-sortable thead button|, "Enter")
      |> assert_has(~s|#kbd-table-sortable th[aria-sort="none"] .hero-chevron-up-down|)
    end

    test "a sortable header keeps focus across an async reload", %{conn: conn} do
      conn
      |> visit("/keyboard/table")
      |> A11y.await_live_connected()
      |> assert_has("#kbd-table-async-reloads", text: "0")
      |> press(~s|#kbd-table-async thead button|, "Enter")
      |> assert_has("#kbd-table-async-reloads", text: "1")
      |> assert_has(~s|#kbd-table-async th[aria-sort="ascending"]|)
      |> A11y.assert_focused("kbd-table-async-inner-sort-0")
    end

    test "a streamed table keeps its rows across a load", %{conn: conn} do
      conn
      |> visit("/keyboard/table")
      |> A11y.await_live_connected()
      |> assert_has("#kbd-table-stream tbody tr#people-ada")
      |> assert_has("#kbd-table-stream tbody tr#people-grace")
      |> click("#kbd-table-stream-reload")
      |> assert_has("#kbd-table-stream-reloads", text: "1")
      |> assert_has("#kbd-table-stream tbody tr#people-ada")
      |> assert_has("#kbd-table-stream tbody tr#people-grace")
      |> refute_has("#kbd-table-stream .animate-pulse-subtle")
    end

    test "a sortable header label aligns with its own data cells", %{conn: conn} do
      session =
        conn
        |> visit("/components/table/solid")
        |> A11y.await_live_connected()

      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const table = document.querySelector("table[data-fixture-cell='sortable-solid-neutral']");
          const edges = (el) => {
            const rect = el.getBoundingClientRect();
            const style = getComputedStyle(el);
            return [
              rect.left + parseFloat(style.paddingLeft),
              rect.right - parseFloat(style.paddingRight)
            ];
          };
          return [...table.querySelectorAll("thead th")].map((header) => {
            const [headerLeft, headerRight] = edges(header);
            const [buttonLeft, buttonRight] = edges(header.querySelector("button"));
            return [buttonLeft - headerLeft, buttonRight - headerRight];
          });
        })()
        """,
        fn deltas ->
          assert length(deltas) == 3

          for [left_delta, right_delta] <- deltas do
            assert_in_delta left_delta, 0, 0.5
            assert_in_delta right_delta, 0, 0.5
          end
        end
      )
    end

    test "row click listener follows updates without duplicate activation", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/table")
        |> A11y.await_live_connected()
        |> refute_has(~s|#kbd-table-lifecycle-row-0[data-row-click]|)
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
        |> refute_has(~s|#kbd-table-lifecycle-row-0[data-row-click]|)

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
      |> refute_has(~s|#kbd-table-lifecycle-row-0[data-row-click]|)
      |> click("#kbd-table-toggle-row-click")
      |> assert_has(~s|#kbd-table-lifecycle-row-1[data-row-click="true"]|)
      |> press("#kbd-table-lifecycle-row-1", "Enter")
      |> assert_has("#kbd-table-selection", text: "Grace")
      |> assert_has("#kbd-table-activation-count", text: "2")
    end
  end
end
