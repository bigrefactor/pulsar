defmodule Pulsar.Integration.A11y.Keyboard.CommandTest do
  @moduledoc """
  Real-browser keyboard tests for Command. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  # The fixture at `/keyboard/command` renders one command (`kbd-cmd`) over
  # Alpha / Beta / Gamma [disabled] / Betamax, echoing the selected value into
  # `#kbd-cmd-received` and the cancel into `#kbd-cmd-cancelled`. Filtering,
  # roving `aria-activedescendant`, and Enter/Escape come from the
  # `.PulsarCommand` colocated hook.
  #
  # Verification: comment out the ArrowDown branch of the hook's keydown
  # handler (see `lib/pulsar/components/command.ex`), run
  # `MIX_ENV=test mix assets.build`, re-run — every Enter test below fails,
  # because Enter then selects Alpha rather than the arrowed-to row.

  describe "typing" do
    test "filters the rows to matches only", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> fill_in("Search commands", with: "beta")
      |> assert_has("#kbd-cmd-listbox", text: "Beta")
      |> assert_has("#kbd-cmd-listbox", text: "Betamax")
      |> refute_has("#kbd-cmd-listbox", text: "Alpha")
    end

    test "an unmatched query shows the empty state", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> fill_in("Search commands", with: "zzzz")
      |> assert_has("#kbd-cmd-listbox", text: "No results found")
      |> refute_has("#kbd-cmd-listbox", text: "Alpha")
    end

    test "selecting a row with Enter clears the typed query from the input", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/command")
        |> A11y.await_live_connected()
        |> fill_in("Search commands", with: "beta")
        |> press("#kbd-cmd-input", "Enter")
        |> assert_has("#kbd-cmd-received", text: "beta")

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-cmd-input').value",
        fn value ->
          assert value == ""
        end
      )
    end
  end

  describe "arrow keys" do
    test "Enter with no movement selects the first row", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "Enter")
      |> assert_has("#kbd-cmd-received", text: "alpha")
    end

    test "ArrowDown moves the active row, and Enter selects it", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "ArrowDown")
      |> assert_has(~s|#kbd-cmd-option-1[data-active="true"]|)
      |> assert_has(~s|#kbd-cmd-input[aria-activedescendant="kbd-cmd-option-1"]|)
      |> press("#kbd-cmd-input", "Enter")
      |> assert_has("#kbd-cmd-received", text: "beta")
    end

    test "ArrowDown skips the disabled row", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "ArrowDown")
      |> press("#kbd-cmd-input", "ArrowDown")
      |> refute_has(~s|[aria-disabled="true"][data-active="true"]|)
      |> press("#kbd-cmd-input", "Enter")
      |> assert_has("#kbd-cmd-received", text: "betamax")
    end

    test "ArrowUp from the first row wraps to the last enabled row", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "ArrowUp")
      |> press("#kbd-cmd-input", "Enter")
      |> assert_has("#kbd-cmd-received", text: "betamax")
    end

    test "End jumps to the last enabled row and Home returns to the first", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "End")
      |> assert_has(~s|#kbd-cmd-input[aria-activedescendant="kbd-cmd-option-3"]|)
      |> press("#kbd-cmd-input", "Home")
      |> press("#kbd-cmd-input", "Enter")
      |> assert_has("#kbd-cmd-received", text: "alpha")
    end
  end

  describe "Escape" do
    test "runs the cancel callback", %{conn: conn} do
      conn
      |> visit("/keyboard/command")
      |> A11y.await_live_connected()
      |> press("#kbd-cmd-input", "Escape")
      |> assert_has("#kbd-cmd-cancelled", text: "cancelled")
    end
  end
end
