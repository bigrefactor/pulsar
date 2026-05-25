defmodule Pulsar.Integration.A11y.AxeCleanTest do
  @moduledoc """
  Per-fixture axe-clean assertion. One test per (fixture LiveView, theme)
  combination — adding a fixture to `Pulsar.TestApp.Components.fixtures/0`
  automatically gets light + dark coverage here.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  NOTE: We use `:integration` rather than `:browser` because
  `PhoenixTest.Playwright.Case` merges ExUnit context tags into the Playwright
  config, and `:browser` is a reserved Playwright key that expects an atom
  like `:chromium`, not `true`. Using `:integration` avoids that conflict.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.TestApp.A11y
  alias Pulsar.TestApp.Components

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
end
