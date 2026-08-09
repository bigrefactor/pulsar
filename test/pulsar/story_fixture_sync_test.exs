defmodule Pulsar.StoryFixtureSyncTest do
  use ExUnit.Case, async: true

  alias Pulsar.StoryFixtureSync

  describe "pairs/0" do
    test "discovers every story template and maps it into the dev app" do
      pairs = StoryFixtureSync.pairs()

      assert length(pairs) > 40,
             "expected the story templates to be discovered, found #{length(pairs)}"

      for {template, fixture} <- pairs do
        assert File.exists?(template), "missing template at #{template}"
        assert String.starts_with?(fixture, "test/support/dev_app/storybook/")
        refute String.ends_with?(fixture, ".eex")
      end
    end

    test "covers the welcome, component, foundation, and example trees" do
      fixtures = StoryFixtureSync.pairs() |> Enum.map(&elem(&1, 1))

      assert "test/support/dev_app/storybook/welcome.story.exs" in fixtures
      assert "test/support/dev_app/storybook/components/button.story.exs" in fixtures
      assert "test/support/dev_app/storybook/foundations/dark_mode.story.exs" in fixtures
      assert "test/support/dev_app/storybook/examples/login.story.exs" in fixtures
    end
  end

  describe "expected/1" do
    test "renders parseable source under the dev app namespace" do
      pair =
        Enum.find(StoryFixtureSync.pairs(), fn {template, _fixture} ->
          String.ends_with?(template, "components/button.story.exs.eex")
        end)

      expected = StoryFixtureSync.expected(pair)

      assert expected =~ "defmodule Pulsar.DevApp.Storybook.Components.Button do"
      assert {:ok, _} = Code.string_to_quoted(expected)
    end

    test "distinguishes meaningfully different templates" do
      pairs = StoryFixtureSync.pairs()
      button = Enum.find(pairs, fn {t, _} -> String.ends_with?(t, "components/button.story.exs.eex") end)
      input = Enum.find(pairs, fn {t, _} -> String.ends_with?(t, "components/input.story.exs.eex") end)

      refute StoryFixtureSync.expected(button) == StoryFixtureSync.expected(input),
             "expected/1 collapsed two distinct templates — drift detection is no longer load-bearing"
    end
  end
end
