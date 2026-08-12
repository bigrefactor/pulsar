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
      "document.querySelector('#fixtures-sidebar + [data-sidebar-backdrop]').click()"
    )

    assert_has(session, ~s|#fixtures-sidebar[data-mobile="closed"]|)
  end
end
