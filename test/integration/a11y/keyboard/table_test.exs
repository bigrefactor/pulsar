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
  end
end
