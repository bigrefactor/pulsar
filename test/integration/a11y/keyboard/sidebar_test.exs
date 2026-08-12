defmodule Pulsar.Integration.A11y.Keyboard.SidebarTest do
  @moduledoc """
  Real-browser coverage for Sidebar's backdrop dismissal path.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration
  @moduletag browser_context_opts: [viewport: %{width: 768, height: 640}]

  test "the untargeted backdrop hide event reaches the sidebar hook", %{conn: conn} do
    session =
      conn
      |> visit("/components/sidebar")
      |> A11y.await_live_connected()
      |> click_button("Open navigation")
      |> assert_has(~s|#fixtures-sidebar[data-mobile="open"]|)

    PhoenixTest.Playwright.evaluate(
      session,
      "document.querySelector('#fixtures-sidebar [data-sidebar-backdrop]').click()"
    )

    assert_has(session, ~s|#fixtures-sidebar[data-mobile="closed"]|)
  end

  @tag browser_context_opts: [viewport: %{width: 1280, height: 720}]
  test "the panel is the direct flex item and preserves caller and peer utilities", %{conn: conn} do
    session =
      conn
      |> visit("/components/sidebar")
      |> A11y.await_live_connected()

    PhoenixTest.Playwright.evaluate(
      session,
      """
      (() => {
        const contract = document.getElementById('sidebar-layout-contract');
        const panel = document.getElementById('sidebar-layout-panel');
        const visualPanel = panel.querySelector('[data-sidebar-panel]');
        const main = contract.querySelector('[data-layout-main]');
        const panelStyle = getComputedStyle(panel);
        const visualPanelStyle = getComputedStyle(visualPanel);
        return {
          direct: panel.parentElement === contract,
          restOnPanel: panel.dataset.layoutSidebar === 'true',
          order: panelStyle.order,
          basis: panelStyle.flexBasis,
          alignSelf: panelStyle.alignSelf,
          width: panelStyle.width,
          panelOverflow: visualPanelStyle.overflow,
          panelFlexDirection: visualPanelStyle.flexDirection,
          peerOpacity: getComputedStyle(main).opacity,
          state: panel.dataset.state
        };
      })()
      """,
      fn state ->
        assert state == %{
                 "direct" => true,
                 "restOnPanel" => true,
                 "order" => "9999",
                 "basis" => "320px",
                 "alignSelf" => "stretch",
                 "width" => "320px",
                 "panelOverflow" => "visible",
                 "panelFlexDirection" => "row",
                 "peerOpacity" => "1",
                 "state" => "expanded"
               }
      end
    )

    session =
      session
      |> click("#sidebar-layout-toggle")
      |> assert_has(~s|#sidebar-layout-panel[data-state="collapsed"]|)

    PhoenixTest.Playwright.evaluate(
      session,
      """
      (async () => {
        const panel = document.getElementById('sidebar-layout-panel');
        const main = document.querySelector('#sidebar-layout-contract [data-layout-main]');
        while (panel.getBoundingClientRect().width > 64.01) {
          await new Promise(requestAnimationFrame);
        }
        const style = getComputedStyle(panel);
        return {
          basis: style.flexBasis,
          width: style.width,
          peerOpacity: getComputedStyle(main).opacity
        };
      })()
      """,
      fn state ->
        assert state == %{"basis" => "64px", "width" => "64px", "peerOpacity" => "0.5"}
      end
    )
  end
end
