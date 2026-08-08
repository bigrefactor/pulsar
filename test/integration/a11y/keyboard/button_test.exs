defmodule Pulsar.Integration.A11y.Keyboard.ButtonTest do
  @moduledoc """
  Real-browser keyboard tests for Button. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

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
end
