defmodule Mix.Tasks.Pulsar.GeneratedVocabularyTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  @moduletag :igniter
  @moduletag timeout: 300_000

  @placeholder ~r/MyApp|my_app/

  describe "generated output" do
    test "never names the MyApp placeholder vocabulary" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", ["--storybook", "--yes"])

      swept = Enum.to_list(igniter.rewrite.sources)

      # phx_test_project/0 ships sources of its own, so a non-empty sweep proves
      # nothing. Anchor on paths only Pulsar generates — a component, a story,
      # and a stylesheet — to prove the sweep sees every family of output.
      for anchor <- [
            "lib/test_web/components/avatar.ex",
            "lib/test_web/storybook/components/avatar.story.exs",
            "assets/css/theme.css"
          ] do
        assert Enum.any?(swept, fn {path, _source} -> path == anchor end),
               "expected the sweep to find #{anchor}, a file only Pulsar generates — " <>
                 "its absence means the sweep isn't seeing Pulsar's output"
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
