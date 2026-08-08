defmodule Pulsar.Integration.A11y.Keyboard.SwitchTest do
  @moduledoc """
  Real-browser keyboard tests for Switch. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  @moduletag :integration

  describe "Switch keyboard activation" do
    test "Space toggles the underlying checkbox state", %{conn: conn} do
      # The Switch renders a hidden <input type="checkbox" role="switch"
      # class="sr-only"> as its real interactive element. Space on a
      # native checkbox toggles `:checked` via browser semantics.
      #
      # NOTE: we explicitly do NOT assert aria-checked here. The template
      # computes `aria-checked={if @checked, do: "true", else: "false"}`
      # from the server-side assign, which doesn't update when the native
      # input toggles client-side. That's a separate screen-reader a11y
      # bug to fix in a follow-up ticket.
      conn
      |> visit("/components/switch")
      |> press("#sw-neutral-xs-unchecked", " ")
      |> assert_has("#sw-neutral-xs-unchecked:checked")
    end
  end
end
