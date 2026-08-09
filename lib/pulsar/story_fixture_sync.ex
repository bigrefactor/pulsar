defmodule Pulsar.StoryFixtureSync do
  @moduledoc """
  Maintainer/repo-internal helper that treats `priv/templates/storybook/**/*.exs.eex`
  as the single source of truth for the dev-app storybook fixtures.

  Each story lives once, as an EEx template shipped to user apps by
  `mix pulsar.install --storybook`. The committed
  `test/support/dev_app/storybook/**/*.exs` fixtures are *generated* from those
  templates by `mix pulsar.sync` — rendered with the dev app's assigns and run
  through the project formatter — so the two never need to be hand-mirrored.

  Discovery is glob-driven: every story template is covered automatically, and
  a template without a committed fixture counts as drift.

  This is build tooling for the Pulsar repository itself — it is not part of
  the public, generated-into-your-app surface.
  """

  alias Mix.Tasks.Format

  @assigns [web_module: "Pulsar.DevApp", components_module: "Pulsar.Components"]
  @fixture_root "test/support/dev_app/storybook"

  @typedoc "`{template_path, fixture_path}` — absolute template path, repo-relative fixture path."
  @type pair :: {String.t(), String.t()}

  @doc """
  Every story template paired with the dev-app fixture it generates.

  `priv/templates/storybook/<rel>.eex` maps to
  `test/support/dev_app/storybook/<rel>`.
  """
  @spec pairs() :: [pair()]
  def pairs do
    root = templates_root()

    root
    |> Path.join("**/*.exs.eex")
    |> Path.wildcard()
    |> Enum.map(fn template ->
      rel = template |> Path.relative_to(root) |> String.replace_suffix(".eex", "")
      {template, Path.join(@fixture_root, rel)}
    end)
  end

  @doc """
  Renders the fixture content a given `pair` should have, from its template.

  Renders with the dev app's assigns and runs the result through the project
  formatter so it matches a `mix format`-clean committed fixture byte for byte.
  """
  @spec expected(pair()) :: String.t()
  def expected({template_path, fixture_path}) do
    template_path
    |> EEx.eval_file(assigns: @assigns, engine: EEx.SmartEngine)
    |> format(fixture_path)
  end

  @doc """
  Reads the committed fixture for a `pair` and formats it for comparison.

  Returns `{:error, :enoent}` if the fixture does not exist yet.
  """
  @spec current(pair()) :: {:ok, String.t()} | {:error, File.posix()}
  def current({_template_path, fixture_path}) do
    case File.read(fixture_path) do
      {:ok, content} -> {:ok, format(content, fixture_path)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the pairs whose committed fixture has drifted from its template.

  A missing fixture counts as drift. Each entry is `{pair, expected_content}`
  so callers can report or rewrite the file.
  """
  @spec diff() :: [{pair(), String.t()}]
  def diff do
    pairs()
    |> Enum.map(fn pair -> {pair, expected(pair)} end)
    |> Enum.filter(fn {pair, expected} -> current(pair) != {:ok, expected} end)
  end

  defp templates_root do
    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates/storybook")
  end

  defp format(content, fixture_path) do
    {formatter, _opts} = Format.formatter_for_file(fixture_path)

    content
    |> formatter.()
    |> String.replace(~r/[ \t]+$/m, "")
    |> String.trim_trailing("\n")
  end
end
