defmodule Pulsar.Integration.A11y.Keyboard.RadioGroupTest do
  @moduledoc """
  Real-browser keyboard tests for RadioGroup. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

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

  describe "RadioGroup keyboard navigation (extended)" do
    # The fixture at `/keyboard/radio_group` provides an anchor `<button>`
    # before two radio groups: one with `value="2"` (option index 1
    # pre-checked) and one with `orientation="horizontal"`. Both groups
    # rely on browser-native radio-group semantics — Pulsar's
    # `.PulsarRadioGroup` hook only intercepts Home/End, so the
    # behaviors under test here come from the platform.
    #
    # Verification recipes:
    #   * Tab-to-checked: render unique `name` attributes per radio in
    #     `lib/pulsar/components/radio_group.ex` (e.g.
    #     `name={"#{@group.name}-#{@radio_id}"}`) and rebuild assets —
    #     the browser stops grouping the radios, every radio joins the
    #     tab sequence, and Tab from the anchor lands on
    #     `kbd-rg-checked-0` instead of `kbd-rg-checked-1`.
    #   * Horizontal arrow: temporarily add `disabled` to the rendered
    #     radio input — focus still moves but `:checked` never flips, so
    #     the assertion fails.

    test "Tab from outside the group lands on the pre-checked radio",
         %{conn: conn} do
      conn
      |> visit("/keyboard/radio_group")
      |> A11y.await_live_connected()
      |> press("#kbd-rg-before", "Tab")
      |> A11y.assert_focused("kbd-rg-checked-1")
    end

    test "ArrowRight on a horizontal group selects the next option",
         %{conn: conn} do
      # Asserts the positive direction only: a horizontal group accepts
      # Left/Right. We do NOT assert exclusivity — `<input type="radio">`
      # also accepts Up/Down by browser default, and Pulsar doesn't
      # currently constrain that. Tightening orientation handling would
      # require new hook logic.
      conn
      |> visit("/keyboard/radio_group")
      |> A11y.await_live_connected()
      |> press("#kbd-rg-horiz-0", "ArrowRight")
      |> assert_has("#kbd-rg-horiz-1:checked")
    end
  end
end
