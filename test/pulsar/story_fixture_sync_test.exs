defmodule Pulsar.StoryFixtureSyncTest do
  use ExUnit.Case, async: true

  alias Pulsar.StoryFixtureSync

  describe "pairs/0" do
    test "discovers every story template and maps it into the dev app" do
      pairs = StoryFixtureSync.pairs()

      refute pairs == []

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
    test "renders under the dev app namespace" do
      pair =
        Enum.find(StoryFixtureSync.pairs(), fn {template, _fixture} ->
          String.ends_with?(template, "components/button.story.exs.eex")
        end)

      expected = StoryFixtureSync.expected(pair)

      assert expected =~ "defmodule Pulsar.DevApp.Storybook.Components.Button do"
    end

    test "distinguishes meaningfully different templates" do
      pairs = StoryFixtureSync.pairs()
      button = Enum.find(pairs, fn {t, _} -> String.ends_with?(t, "components/button.story.exs.eex") end)
      input = Enum.find(pairs, fn {t, _} -> String.ends_with?(t, "components/input.story.exs.eex") end)

      refute StoryFixtureSync.expected(button) == StoryFixtureSync.expected(input),
             "expected/1 collapsed two distinct templates — drift detection is no longer load-bearing"
    end
  end

  describe "current/1" do
    @tag :tmp_dir
    test "returns an unformattable fixture raw so it counts as drift instead of raising", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "broken.story.exs")
      File.write!(path, "defmodule Broken do\n<<<<<<< HEAD\nend\n")

      assert {:ok, content} = StoryFixtureSync.current({"unused-template-path", path})
      assert content =~ "<<<<<<< HEAD"
    end
  end

  describe "diff/0" do
    test "committed dev-app story fixtures are in sync with their templates" do
      drifted =
        StoryFixtureSync.diff()
        |> Enum.map(fn {{_template, fixture_path}, _expected} -> fixture_path end)

      assert drifted == [],
             "Run `mix pulsar.sync` — these story fixtures have drifted from their templates: " <>
               Enum.join(drifted, ", ")
    end
  end

  describe "orphans/0" do
    test "no committed fixture is orphaned by a deleted or renamed template" do
      assert StoryFixtureSync.orphans() == [],
             "Run `mix pulsar.sync` — these fixtures have no story template: " <>
               Enum.join(StoryFixtureSync.orphans(), ", ")
    end
  end
end
