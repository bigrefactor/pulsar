defmodule Mix.Tasks.Pulsar.A11y.Measure do
  @moduledoc """
  Browser-based WCAG 2.2 AA measurement runner for the Pulsar component
  library. Drives the dev_app fixture LiveViews via `phoenix_test_playwright`,
  injects `priv/a11y/measure.js` against each fixture × theme, and writes
  a markdown report per `(component, theme)` to
  `docs/a11y/measurements/<component>-<theme>.md`.

  This is the automation harness behind the PUL-19 browser audit. It does
  not pass/fail — it produces measurement artifacts that humans (or the
  later doc-update phase) interpret. The tests themselves live at
  `test/integration/a11y/measure_test.exs` under the `:measure` tag, which
  is excluded from `mix test` and `mix test --only integration` by default.

  ## Usage

      mix pulsar.a11y.measure                       # all components × both themes
      mix pulsar.a11y.measure --component button    # one component, both themes
      mix pulsar.a11y.measure --theme light         # all components, one theme
      mix pulsar.a11y.measure --component button --theme dark

  ## Filtering

  Filters are forwarded to the underlying ExUnit run via environment
  variables (`PULSAR_A11Y_COMPONENT`, `PULSAR_A11Y_THEME`) which the
  measurement test reads at runtime — ExUnit selects every generated test
  by tag but the matching test bodies short-circuit if filters don't apply.
  """

  use Mix.Task

  @switches [
    component: :string,
    theme: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: @switches)

    if opts[:theme] && opts[:theme] not in ["light", "dark"] do
      Mix.raise("--theme must be `light` or `dark`, got: #{inspect(opts[:theme])}")
    end

    env =
      []
      |> maybe_put_env("PULSAR_A11Y_COMPONENT", opts[:component])
      |> maybe_put_env("PULSAR_A11Y_THEME", opts[:theme])

    Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

    # Run the measurement-tagged tests. `:measure` is in the default
    # exclude list (test/test_helper.exs); `--only measure` includes them
    # while excluding everything else.
    Mix.Task.run("test", [
      "--only",
      "measure",
      "--no-cover",
      "test/integration/a11y/measure_test.exs"
    ])
  end

  defp maybe_put_env(env, _key, nil), do: env
  defp maybe_put_env(env, key, value), do: [{key, value} | env]
end
