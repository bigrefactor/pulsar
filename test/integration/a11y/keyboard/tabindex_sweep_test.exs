defmodule Pulsar.Integration.A11y.Keyboard.TabindexSweepTest do
  @moduledoc """
  Real-browser keyboard tests for the fixture-cell tabindex sweep. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "tabindex=-1 sweep on fixture cells" do
    # A fast, broad sweep that catches accidental `tabindex="-1"` on any
    # element marked as a fixture interactive cell. Uses one
    # `querySelectorAll` per fixture instead of walking Tab through
    # hundreds of cells, which keeps mount budget within the
    # browser-CI levers.
    #
    # Verification: temporarily add `tabindex="-1"` to the Button host
    # element in `lib/pulsar/components/button.ex`, rebuild assets, and
    # re-run — the `/components/button` test reports a non-empty result
    # and the assertion fails with the offending elements listed.

    @traversal_fixtures [
      "/components/button",
      "/components/input/outline",
      "/components/checkbox",
      "/components/switch",
      "/components/link"
    ]

    for path <- @traversal_fixtures do
      test "no [data-fixture-cell] interactive element has tabindex=-1 at #{path}",
           %{conn: conn} do
        conn
        |> visit(unquote(path))
        |> A11y.await_live_connected()
        |> assert_no_negative_tabindex_on_fixture_cells()
      end
    end
  end

  # Reads `[data-fixture-cell][tabindex="-1"]` from the current page and
  # asserts the result is empty. Surfaces offending ids/tags so a failure
  # points at the specific regressed element.
  defp assert_no_negative_tabindex_on_fixture_cells(conn) do
    expr = """
    (() => {
      const els = document.querySelectorAll('[data-fixture-cell][tabindex="-1"]');
      return Array.from(els).map(el => ({
        id: el.id,
        tag: el.tagName.toLowerCase(),
        cell: el.getAttribute('data-fixture-cell')
      }));
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr, fn results ->
      if results != [] do
        raise ExUnit.AssertionError,
          message: "found [data-fixture-cell] elements with tabindex=-1: #{inspect(results)}"
      end
    end)
  end
end
