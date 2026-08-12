defmodule Pulsar.Integration.A11y.EventScopingTest do
  @moduledoc """
  Real-browser regressions for the nearest-owner contract of internal component
  events. An action inside a nested same-type hook must never reach its ancestor.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration
  @moduletag browser_context_opts: [viewport: %{width: 768, height: 640}]

  test "Select removal stops at the nearest Select hook", %{conn: conn} do
    session =
      conn
      |> visit("/components/event-scoping")
      |> A11y.await_live_connected()
      |> click(~s|#scope-select-inner-wrapper button[aria-label="Remove Inner shared option"]|)

    PhoenixTest.Playwright.evaluate(
      session,
      """
      ({
        outerSelected: document.querySelector('#scope-select-outer-control option').selected,
        innerSelected: document.querySelector('#scope-select-inner option').selected
      })
      """,
      fn state ->
        assert state == %{"outerSelected" => true, "innerSelected" => false}
      end
    )
  end

  test "Flash dismissal removes only the nearest Flash", %{conn: conn} do
    conn
    |> visit("/components/event-scoping")
    |> A11y.await_live_connected()
    |> click(~s|#scope-flash-inner button[aria-label="Dismiss"]|)
    |> refute_has("#scope-flash-inner")
    |> assert_has("#scope-flash-outer")
  end

  test "Modal close keeps its same-type ancestor open", %{conn: conn} do
    conn
    |> visit("/components/event-scoping")
    |> A11y.await_live_connected()
    |> click("#scope-modal-open-outer")
    |> assert_has(~s|#scope-modal-outer[data-state="open"]|)
    |> click("#scope-modal-open-inner")
    |> assert_has(~s|#scope-modal-inner[data-state="open"]|)
    |> click(~s|#scope-modal-inner button[aria-label="Close"]|)
    |> assert_has(~s|#scope-modal-outer[data-state="open"]|)
    |> then(fn session ->
      PhoenixTest.Playwright.evaluate(
        session,
        """
        (async () => {
          const inner = document.getElementById('scope-modal-inner');
          while (inner.dataset.state !== 'closed') {
            await new Promise(requestAnimationFrame);
          }
          return {innerOpen: inner.open, innerState: inner.dataset.state};
        })()
        """,
        fn state -> assert state == %{"innerOpen" => false, "innerState" => "closed"} end
      )
    end)
  end

  test "nested Sidebar backdrop state belongs only to its Sidebar", %{conn: conn} do
    session =
      conn
      |> visit("/components/event-scoping")
      |> A11y.await_live_connected()
      |> click("#scope-sidebar-open-outer")
      |> assert_has(~s|#scope-sidebar-outer[data-mobile="open"]|)
      |> assert_has(~s|#scope-sidebar-inner[data-mobile="closed"]|)

    PhoenixTest.Playwright.evaluate(
      session,
      """
      (async () => {
        const outerBackdrop = document.querySelector('#scope-sidebar-outer > [data-sidebar-backdrop]');
        const innerBackdrop = document.querySelector('#scope-sidebar-inner > [data-sidebar-backdrop]');

        for (let frame = 0; frame < 120 && getComputedStyle(outerBackdrop).opacity !== '1'; frame++) {
          await new Promise(requestAnimationFrame);
        }

        const style = getComputedStyle(innerBackdrop);
        return {opacity: style.opacity, pointerEvents: style.pointerEvents};
      })()
      """,
      fn state -> assert state == %{"opacity" => "0", "pointerEvents" => "none"} end
    )

    session =
      session
      |> click("#scope-sidebar-open-inner")
      |> assert_has(~s|#scope-sidebar-inner[data-mobile="open"]|)
      |> click("#scope-sidebar-inner > [data-sidebar-backdrop]")
      |> assert_has(~s|#scope-sidebar-inner[data-mobile="closed"]|)
      |> assert_has(~s|#scope-sidebar-outer[data-mobile="open"]|)

    PhoenixTest.Playwright.evaluate(
      session,
      """
      (async () => {
        const backdrop = document.querySelector('#scope-sidebar-inner > [data-sidebar-backdrop]');

        for (let frame = 0; frame < 120 && getComputedStyle(backdrop).opacity !== '0'; frame++) {
          await new Promise(requestAnimationFrame);
        }

        const style = getComputedStyle(backdrop);
        return {opacity: style.opacity, pointerEvents: style.pointerEvents};
      })()
      """,
      fn state -> assert state == %{"opacity" => "0", "pointerEvents" => "none"} end
    )

    session
    |> click("#scope-sidebar-outer > [data-sidebar-backdrop]")
    |> assert_has(~s|#scope-sidebar-outer[data-mobile="closed"]|)
  end
end
