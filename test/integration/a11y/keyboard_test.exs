defmodule Pulsar.Integration.A11y.KeyboardTest do
  @moduledoc """
  Real-browser keyboard tests for interactive components. Axe-clean
  (PUL-11) catches static a11y problems but not behavior — a button
  could fail to activate on Enter and axe would happily report it
  clean. These tests close that gap.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`. Tag rationale matches `AxeCleanTest`:
  `:browser` is a reserved Playwright key.

  ## Verification

  To prove these tests are wired to real keyboard behavior (and not
  accidentally passing), temporarily comment out the keydown/keyup
  Space/Enter branches in `.PulsarButton` (see `lib/pulsar/components/
  button.ex`, near the `_onKeydown`/`_onKeyup` definitions) and re-run
  the Button activation test — it should fail with the activation
  counter still at 0 instead of 2.
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

  describe "RadioGroup keyboard navigation" do
    # First group on the page: rg-neutral-xs (colors and sizes from
    # radio_group_live.ex are neutral-first, xs-first). Options have ids
    # rg-neutral-xs-{index} with index 0..2 and values "1", "2", "3".

    test "ArrowDown moves selection to the next radio in the group", %{conn: conn} do
      conn
      |> visit("/components/radio_group")
      |> press("#rg-neutral-xs-0", "ArrowDown")
      |> assert_has("#rg-neutral-xs-1:checked")
    end

    test "Tab moves focus out of the group, not between radios", %{conn: conn} do
      conn
      |> visit("/components/radio_group")
      |> press("#rg-neutral-xs-0", "Tab")
      |> A11y.refute_focused_within("#rg-neutral-xs")
    end
  end

  describe "Select keyboard navigation" do
    # Options are "1", "2", "3" plus a prompt. Selector lives at module
    # top (@select_cell).

    test "Tab moves focus from one select to the next focusable", %{conn: conn} do
      conn
      |> visit("/components/select")
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
      |> visit("/components/select")
      |> press(@select_cell, "ArrowDown")
      |> assert_has(":focus#{@select_cell}")
    end

    test "pressing Space keeps focus on the select", %{conn: conn} do
      # The ticket calls for "Space opens (browser default)." In headless
      # Chromium the dropdown picker is opaque to the DOM, so we can't
      # observe "open." This test verifies the slice we can: Pulsar doesn't
      # preventDefault on Space, and the element retains focus afterward.
      conn
      |> visit("/components/select")
      |> press(@select_cell, " ")
      |> assert_has(":focus#{@select_cell}")
    end
  end

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
