defmodule Pulsar.Integration.A11y.AxeCleanTest do
  @moduledoc """
  Per-fixture axe-clean assertion. One test per (fixture LiveView, theme)
  combination — adding a fixture to `Pulsar.DevApp.Components.fixtures/0`
  automatically gets light + dark coverage here.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  NOTE: We use `:integration` rather than `:browser` because
  `PhoenixTest.Playwright.Case` merges ExUnit context tags into the Playwright
  config, and `:browser` is a reserved Playwright key that expects an atom
  like `:chromium`, not `true`. Using `:integration` avoids that conflict.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y
  alias Pulsar.DevApp.Components

  @moduletag :integration

  for {label, route} <- Components.fixtures(),
      theme <- [:light, :dark] do
    @label label
    @route route
    @theme theme

    test "#{@label} fixture (#{@route}) [#{@theme}] is axe-clean", %{conn: conn} do
      conn
      |> visit(@route)
      |> A11y.set_theme(@theme)
      |> A11y.assert_axe_clean()
    end
  end

  # The per-fixture scan above visits each route with every menu closed — a
  # closed `[popover]` is `display:none`, which axe skips — so it never measures
  # menu *items*. This opens the DropdownMenu keyboard fixture (which renders one
  # item per color) and scans the menu while it's in the top layer, gating the
  # contrast of each color's item text and the in-menu focus indicator in both
  # themes.
  #
  # `await_animations/2` is essential: the menu plays a `fade-in` (opacity 0 → 1)
  # on open, and axe composites the live pixel — sampling mid-fade reports the
  # item text blended ~50% into the surface, an artificially low contrast that
  # the settled colors clear comfortably (≥5:1 both themes).
  for theme <- [:light, :dark] do
    @open_theme theme

    test "open DropdownMenu items are axe-clean [#{@open_theme}]", %{conn: conn} do
      conn
      |> visit("/keyboard/dropdown_menu")
      |> A11y.await_live_connected()
      |> A11y.set_theme(@open_theme)
      |> click("#kbd-dm-trigger")
      |> assert_has(~s|#kbd-dm[data-state="open"]|)
      |> A11y.await_animations("kbd-dm")
      |> A11y.assert_axe_clean()
    end
  end
end
