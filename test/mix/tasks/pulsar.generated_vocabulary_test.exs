defmodule Mix.Tasks.Pulsar.GeneratedVocabularyTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  @moduletag :igniter
  @moduletag timeout: 300_000

  # Generator output only. Other gen tests legitimately pass
  # `--components-module MyApp.CustomComponents`, so the sweep stays scoped to
  # the paths a default-naming install writes.
  @swept_prefixes [
    "lib/test_web/components/",
    "lib/test_web/storybook/",
    "test/test_web/components/"
  ]

  @placeholder ~r/MyApp|\bmy_app\b/

  describe "generated output" do
    test "never names the MyApp placeholder vocabulary" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", ["--storybook", "--yes"])

      swept =
        for {path, source} <- igniter.rewrite.sources,
            String.starts_with?(path, @swept_prefixes) do
          {path, source}
        end

      for prefix <- @swept_prefixes do
        assert Enum.any?(swept, fn {path, _source} -> String.starts_with?(path, prefix) end),
               "expected the sweep to find at least one generated source under #{prefix}, " <>
                 "but none was present — an empty match set would make the placeholder " <>
                 "assertion below pass vacuously"
      end

      offenders =
        for {path, source} <- swept,
            line <- String.split(Rewrite.Source.get(source, :content), "\n"),
            Regex.match?(@placeholder, line) do
          "#{path}: #{String.trim(line)}"
        end

      assert offenders == [],
             "generated files still name the MyApp placeholder:\n" <>
               Enum.join(offenders, "\n")

      apply_igniter!(igniter)
    end
  end
end
