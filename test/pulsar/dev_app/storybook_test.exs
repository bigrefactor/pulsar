defmodule Pulsar.DevApp.StorybookTest do
  @moduledoc """
  Smoke tests for the Pulsar dev-app storybook backend.

  Verifies that `Pulsar.DevApp.Storybook` compiles, exposes the expected
  content tree, and includes all 27 leaves (welcome + 19 components +
  4 foundations + 3 examples).
  """

  use ExUnit.Case, async: true

  alias Pulsar.DevApp.Storybook

  @expected_component_paths ~w[
    /components/badge
    /components/button
    /components/card
    /components/checkbox
    /components/divider
    /components/field
    /components/flash
    /components/flash_group
    /components/header
    /components/icon
    /components/input
    /components/label
    /components/link
    /components/list
    /components/radio_group
    /components/select
    /components/switch
    /components/table
    /components/textarea
  ]

  @expected_foundation_paths ~w[
    /foundations/colors
    /foundations/dark_mode
    /foundations/spacing
    /foundations/typography
  ]

  @expected_example_paths ~w[
    /examples/dashboard
    /examples/login
    /examples/settings_panel
  ]

  describe "content_tree/0" do
    test "returns a non-empty tree" do
      tree = Storybook.content_tree()
      assert not Enum.empty?(tree)
    end

    test "root entry is a FolderEntry" do
      [root | _] = Storybook.content_tree()
      assert %PhoenixStorybook.FolderEntry{} = root
    end
  end

  describe "leaves/0 paths" do
    test "includes the welcome story" do
      paths = leaf_paths()
      assert "/welcome" in paths
    end

    test "includes all 19 component stories" do
      paths = leaf_paths()

      for expected <- @expected_component_paths do
        assert expected in paths, "expected component story #{expected} to be present"
      end
    end

    test "includes all 4 foundation pages" do
      paths = leaf_paths()

      for expected <- @expected_foundation_paths do
        assert expected in paths, "expected foundation page #{expected} to be present"
      end
    end

    test "includes all 3 example stories" do
      paths = leaf_paths()

      for expected <- @expected_example_paths do
        assert expected in paths, "expected example story #{expected} to be present"
      end
    end
  end

  describe "leaves/0" do
    test "returns exactly 27 leaves" do
      assert length(Storybook.leaves()) == 27
    end

    test "all leaves are StoryEntry structs" do
      for entry <- Storybook.leaves() do
        assert %PhoenixStorybook.StoryEntry{} = entry,
               "expected StoryEntry, got: #{inspect(entry)}"
      end
    end
  end

  describe "find_entry_by_path/1" do
    test "finds the welcome story" do
      entry = Storybook.find_entry_by_path("/welcome")
      assert %PhoenixStorybook.StoryEntry{path: "/welcome"} = entry
    end

    test "finds a component story (button)" do
      entry = Storybook.find_entry_by_path("/components/button")
      assert %PhoenixStorybook.StoryEntry{path: "/components/button"} = entry
    end

    test "finds a foundation page (colors)" do
      entry = Storybook.find_entry_by_path("/foundations/colors")
      assert %PhoenixStorybook.StoryEntry{path: "/foundations/colors"} = entry
    end

    test "finds an example story (login)" do
      entry = Storybook.find_entry_by_path("/examples/login")
      assert %PhoenixStorybook.StoryEntry{path: "/examples/login"} = entry
    end

    test "returns nil for an unknown path" do
      assert Storybook.find_entry_by_path("/does/not/exist") == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp leaf_paths do
    Storybook.leaves() |> Enum.map(& &1.path)
  end
end
