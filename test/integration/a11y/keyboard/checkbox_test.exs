defmodule Pulsar.Integration.A11y.Keyboard.CheckboxTest do
  @moduledoc """
  Real-browser keyboard tests for Checkbox. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Checkbox keyboard activation" do
    test "Space toggles checked state", %{conn: conn} do
      conn
      |> visit("/components/checkbox")
      |> press("#chk-neutral-xs-unchecked", " ")
      |> assert_has("#chk-neutral-xs-unchecked:checked")
    end

    test "Tab moves focus off the current checkbox", %{conn: conn} do
      conn
      |> visit("/components/checkbox")
      |> press("#chk-neutral-xs-unchecked", "Tab")
      |> A11y.refute_focused_within("#chk-neutral-xs-unchecked")
    end
  end
end
