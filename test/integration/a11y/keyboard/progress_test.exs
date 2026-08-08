defmodule Pulsar.Integration.A11y.Keyboard.ProgressTest do
  @moduledoc """
  Real-browser keyboard tests for Progress CSP-safe fill. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Progress CSP-safe fill" do
    test "the determinate fill renders at the right width and animates", %{conn: conn} do
      session =
        conn
        |> visit("/components/progress")
        |> A11y.await_live_connected()

      # The fixture renders value={62} for each color; check the primary cell.
      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const cell = document.querySelector('[data-fixture-cell="linear-primary"]');
          const rect = cell.querySelector('rect');
          const svg = cell.querySelector('svg');
          return (rect.getBoundingClientRect().width / svg.getBoundingClientRect().width).toFixed(4);
        })()
        """,
        fn ratio ->
          assert_in_delta String.to_float(ratio),
                          0.62,
                          0.02,
                          "expected the fill rect to span 62% of the track, got #{ratio}"
        end
      )

      PhoenixTest.Playwright.evaluate(
        session,
        """
        (() => {
          const rect = document.querySelector('[data-fixture-cell="linear-primary"] rect');
          return getComputedStyle(rect).transitionProperty;
        })()
        """,
        fn property ->
          assert property =~ "width",
                 "expected the fill rect to declare a width transition, got '#{property}'"
        end
      )
    end
  end
end
