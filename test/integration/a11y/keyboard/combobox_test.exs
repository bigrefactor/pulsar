defmodule Pulsar.Integration.A11y.Keyboard.ComboboxTest do
  @moduledoc """
  Real-browser keyboard tests for Combobox. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  # The fixture at `/keyboard/combobox` renders three comboboxes over
  # Alpha / Beta / Gamma [disabled] / Betamax: `kbd-form` bound to a form with
  # phx-change (echoing into `#kbd-form-received`), `kbd-solo` standalone with
  # no form, and `kbd-multi` in multiple mode.
  #
  # Verification: comment out the ArrowDown branch of the hook's keydown
  # handler (see `lib/pulsar/components/combobox.ex`), run
  # `MIX_ENV=test mix assets.build`, re-run — every Enter-after-arrow test
  # below fails, because Enter then picks Alpha rather than the arrowed-to row.

  describe "typing" do
    test "opens the list and filters to matches", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> fill_in("Pick an owner", with: "beta")
      |> A11y.assert_visible("kbd-form-listbox")
      |> assert_has(~s|#kbd-form[aria-expanded="true"]|)
      |> assert_has("#kbd-form-listbox", text: "Betamax")
      |> refute_has("#kbd-form-listbox", text: "Alpha")
    end

    test "an unmatched query shows the empty state", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> fill_in("Pick an owner", with: "zzzz")
      |> assert_has("#kbd-form-listbox", text: "No results found")
    end
  end

  describe "arrow keys and Enter" do
    test "Enter with no movement picks the first row", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-form")
      |> press("#kbd-form", "Enter")
      |> assert_has("#kbd-form-received", text: "alpha")
    end

    test "ArrowDown moves the active row and Enter picks it", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-form")
      |> press("#kbd-form", "ArrowDown")
      |> assert_has(~s|#kbd-form-option-1[data-active="true"]|)
      |> assert_has(~s|#kbd-form[aria-activedescendant="kbd-form-option-1"]|)
      |> press("#kbd-form", "Enter")
      |> assert_has("#kbd-form-received", text: "beta")
    end

    test "ArrowDown skips the disabled row", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-form")
      |> press("#kbd-form", "ArrowDown")
      |> press("#kbd-form", "ArrowDown")
      |> assert_has(~s|#kbd-form-option-3[data-active="true"]|)
      |> refute_has(~s|[aria-disabled="true"][data-active="true"]|)
    end

    test "Enter leaves the picked label in the still-focused input", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-form")
        |> press("#kbd-form", "ArrowDown")
        |> press("#kbd-form", "Enter")
        |> assert_has("#kbd-form-received", text: "beta")

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-form').value",
        fn value -> assert value == "Beta" end
      )
    end
  end

  describe "picking" do
    test "the input shows the picked label and the list closes", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-form")
        |> click("#kbd-form-option-1")
        |> A11y.refute_visible("kbd-form-listbox")

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-form').value",
        fn value -> assert value == "Beta" end
      )
    end

    test "a pick inside a form reaches the host through phx-change", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-form")
      |> click("#kbd-form-option-1")
      |> assert_has("#kbd-form-received", text: "beta")
    end

    test "a pick with no enclosing form still displays", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-solo")
        |> click("#kbd-solo-option-1")

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-solo').value",
        fn value -> assert value == "Beta" end
      )
    end

    test "Escape closes the list and restores the resting label", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-form")
        |> click("#kbd-form-option-1")
        |> assert_has("#kbd-form-received", text: "beta")
        |> click("#kbd-form")
        |> fill_in("Pick an owner", with: "zzz")
        |> press("#kbd-form", "Escape")
        |> A11y.refute_visible("kbd-form-listbox")

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-form').value",
        fn value -> assert value == "Beta" end
      )
    end
  end

  describe "host re-renders" do
    # LiveView pushes an enclosing form's phx-change for any input inside it, so
    # every keystroke in the query field also runs the host's `validate`. The
    # fixture's validate rebuilds the form with a changed revision, so the
    # rebuilt `field` really does reach the component's `update/2`.
    test "the open filtered list survives the host's validate", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> fill_in("Pick an owner", with: "beta")
      |> A11y.assert_visible("kbd-form-listbox")
      |> assert_has("#kbd-form-listbox", text: "Betamax")
      # The counter proves the host re-render landed before the list is checked;
      # without it the refute below can pass on the pre-validate render.
      |> assert_has("#kbd-form-validations", text: "1")
      |> refute_has("#kbd-form-listbox", text: "Alpha")
    end
  end

  describe "positioning" do
    # `trigger_mode="manual"` leaves the popover hook's `this.trigger` null, so a
    # panel positioned off the trigger alone would silently stay at the viewport
    # origin — and still pass every visibility assertion above. Measure the two
    # rects instead: the panel has to sit against the field it belongs to.
    test "the open list is anchored under the field, not at the viewport origin", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-form")
        |> A11y.assert_visible("kbd-form-pop")
        |> A11y.await_animations("kbd-form-pop")

      # Positioning runs on an animation frame, so settle two frames before
      # reading the rects.
      measure = """
      async () => {
        await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        const panel = document.getElementById("kbd-form-pop").getBoundingClientRect();
        const field = document.getElementById("kbd-form-field").getBoundingClientRect();
        return [panel.left - field.left, panel.top - field.bottom];
      }
      """

      PhoenixTest.Playwright.evaluate(conn, measure, [is_function: true], fn [dx, dy] ->
        assert abs(dx) <= 2,
               "expected the panel's left edge to line up with the field's, off by #{dx}px"

        assert abs(dy - 8) <= 2,
               "expected the panel to sit 8px under the field, off by #{dy - 8}px"
      end)
    end
  end

  describe "multiple" do
    test "picks accumulate as badges and the list stays open", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-multi")
      |> click("#kbd-multi-option-0")
      |> assert_has("#kbd-multi-field", text: "Alpha")
      |> A11y.assert_visible("kbd-multi-listbox")
      # The badge the pick added re-renders the field, and the server always
      # renders the closed state; the open state has to survive that patch.
      |> assert_has(~s|#kbd-multi[aria-expanded="true"]|)
      |> assert_has(~s|#kbd-multi[aria-activedescendant="kbd-multi-option-0"]|)
      |> click("#kbd-multi-option-1")
      |> assert_has("#kbd-multi-field", text: "Beta")
      |> assert_has("#kbd-multi-field", text: "Alpha")
    end

    # The badges come from the server pushes; only the enclosing form's
    # phx-change observes the hidden <select> the hook writes to.
    test "picks and removals reach the host form through phx-change", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-multi")
      |> click("#kbd-multi-option-0")
      |> assert_has("#kbd-multi-received", text: "alpha")
      |> click("#kbd-multi-option-1")
      |> assert_has("#kbd-multi-received", text: "alpha beta")
    end

    test "Backspace on an empty query removes the last badge", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-multi")
      |> click("#kbd-multi-option-0")
      |> assert_has("#kbd-multi-field", text: "Alpha")
      |> assert_has("#kbd-multi-received", text: "alpha")
      |> press("#kbd-multi", "Backspace")
      |> refute_has("#kbd-multi-field", text: "Alpha")
      |> refute_has("#kbd-multi-received", text: "alpha")
    end
  end

  describe "reopening" do
    test "a list closed without a pick reopens on the full list", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> click("#kbd-solo")
      |> fill_in("Pick a value", with: "zzz")
      |> assert_has("#kbd-solo-listbox", text: "No results found")
      |> press("#kbd-solo", "Escape")
      |> A11y.refute_visible("kbd-solo-listbox")
      |> click(~s|#kbd-solo-field [data-combobox-toggle]|)
      |> A11y.assert_visible("kbd-solo-listbox")
      |> assert_has("#kbd-solo-listbox", text: "Alpha")
      |> refute_has("#kbd-solo-listbox", text: "No results found")
    end
  end

  describe "affordances" do
    test "the chevron opens the list without typing", %{conn: conn} do
      conn
      |> visit("/keyboard/combobox")
      |> A11y.await_live_connected()
      |> A11y.refute_visible("kbd-solo-listbox")
      |> click(~s|#kbd-solo-field [data-combobox-toggle]|)
      |> A11y.assert_visible("kbd-solo-listbox")
    end

    test "the clear button empties the value", %{conn: conn} do
      conn =
        conn
        |> visit("/keyboard/combobox")
        |> A11y.await_live_connected()
        |> click("#kbd-solo")
        |> click("#kbd-solo-option-1")
        |> click(~s|#kbd-solo-field [data-combobox-clear]|)

      PhoenixTest.Playwright.evaluate(
        conn,
        "document.querySelector('#kbd-solo').value",
        fn value -> assert value == "" end
      )
    end
  end
end
