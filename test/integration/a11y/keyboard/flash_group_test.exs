defmodule Pulsar.Integration.A11y.Keyboard.FlashGroupTest do
  @moduledoc """
  Real-browser keyboard tests for FlashGroup CSP-safe stagger. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "FlashGroup CSP-safe stagger" do
    test "every staggered flash settles fully opaque", %{conn: conn} do
      session =
        conn
        |> visit("/components/flash_group")
        |> A11y.await_live_connected()

      # The longest stagger in the fixture is index 3 (300ms) plus a 200ms
      # entry, so poll past that rather than sampling once.
      poll = """
      async () => {
        const cell = document.querySelector('[data-fixture-cell="position-top-right"]');
        const read = () => Array.from(cell.querySelectorAll('[role="alert"], [role="status"]'));
        const deadline = performance.now() + 1500;

        while (performance.now() < deadline) {
          const flashes = read();
          if (flashes.length && flashes.every((f) => getComputedStyle(f).opacity === '1')) {
            return String(flashes.length) + ':' + String(flashes.length);
          }
          await new Promise((r) => setTimeout(r, 50));
        }

        const flashes = read();
        return String(flashes.length) + ':' +
          String(flashes.filter((f) => getComputedStyle(f).opacity === '1').length);
      }
      """

      PhoenixTest.Playwright.evaluate(
        session,
        poll,
        [is_function: true, timeout: 3_000],
        fn result ->
          [total, opaque] = String.split(result, ":")

          assert total == "4", "expected the fixture to render 4 flashes, got #{total}"

          assert opaque == total,
                 "expected all #{total} flashes to settle at opacity 1, only #{opaque} did"
        end
      )
    end
  end
end
