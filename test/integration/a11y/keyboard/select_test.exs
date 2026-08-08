defmodule Pulsar.Integration.A11y.Keyboard.SelectTest do
  @moduledoc """
  Real-browser keyboard tests for Select. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  # Select tests select by the stable `data-fixture-cell` attribute (set
  # in select_live.ex) rather than the rendered `id`. Select doesn't
  # declare `attr :id`, so the rendered id is currently derived from
  # `name` — that's implementation detail and would silently flip if
  # `attr :id` is ever added.
  @select_cell ~s|[data-fixture-cell="outline-neutral-xs-default"]|

  describe "Select keyboard navigation" do
    # Options are "1", "2", "3" plus a prompt. Selector lives at module
    # top (@select_cell).

    test "Tab moves focus from one select to the next focusable", %{conn: conn} do
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, "Tab")
      |> A11y.refute_focused_within(@select_cell)
    end

    test "ArrowDown does not break focus on the select", %{conn: conn} do
      # The ticket calls for "ArrowDown changes selection." Native <select>
      # keyboard semantics in headless Chromium don't commit a value change
      # on ArrowDown when the select starts on a prompt placeholder
      # (selectedIndex stays 0). This is browser/Playwright behavior, not
      # Pulsar — confirmed by diagnostic with two consecutive ArrowDown
      # presses both leaving value="". Asserting focus retention is the
      # slice we can actually verify: Pulsar's markup doesn't trap or
      # steal focus on arrow keys.
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, "ArrowDown")
      |> assert_has(":focus#{@select_cell}")
    end

    test "pressing Space keeps focus on the select", %{conn: conn} do
      # The ticket calls for "Space opens (browser default)." In headless
      # Chromium the dropdown picker is opaque to the DOM, so we can't
      # observe "open." This test verifies the slice we can: Pulsar doesn't
      # preventDefault on Space, and the element retains focus afterward.
      conn
      |> visit("/components/select/outline")
      |> press(@select_cell, " ")
      |> assert_has(":focus#{@select_cell}")
    end
  end
end
