defmodule Pulsar.Integration.A11y.Keyboard.CardTest do
  @moduledoc """
  Real-browser keyboard tests for Card. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

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
end
