defmodule Pulsar.Integration.A11y.StorybookAxeTest do
  @moduledoc """
  Axe-clean assertion for the phoenix_storybook landing route (/storybook).

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration` (requires Playwright npm packages installed
  under test/support/dev_app/assets/node_modules).
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  for theme <- [:light, :dark] do
    @theme theme

    test "/storybook is axe-clean in #{@theme} theme", %{conn: conn} do
      conn
      |> visit("/storybook")
      |> A11y.set_theme(@theme)
      |> A11y.assert_axe_clean()
    end
  end
end
