defmodule Pulsar.Integration.A11y.Keyboard.ResizableTest do
  @moduledoc """
  Real-browser keyboard tests for Resizable CSP-safe sizing. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Resizable CSP-safe sizing" do
    test "the hook resolves a real flex-basis on the second panel", %{conn: conn} do
      session =
        conn
        |> visit("/components/resizable/horizontal")
        |> A11y.await_live_connected()

      PhoenixTest.Playwright.evaluate(
        session,
        "getComputedStyle(document.querySelector('#rz-horizontal-basic')).getPropertyValue('--pulsar-resizable-size').trim()",
        fn value ->
          assert value == "30%",
                 "expected the hook to set --pulsar-resizable-size to 30%, got '#{value}'"
        end
      )

      PhoenixTest.Playwright.evaluate(
        session,
        "getComputedStyle(document.querySelector('#rz-horizontal-basic-panel-2')).flexBasis",
        fn value ->
          refute value == "auto",
                 "expected the second panel to resolve a real flex-basis, got 'auto' — the custom property did not reach the class"
        end
      )
    end
  end
end
