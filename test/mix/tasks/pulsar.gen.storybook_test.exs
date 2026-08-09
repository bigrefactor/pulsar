defmodule Mix.Tasks.Pulsar.Gen.StorybookTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  @moduletag :igniter

  describe "pulsar.gen.storybook --skip-components" do
    test "emits welcome story" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.storybook", ["--skip-components"])
      |> assert_creates("lib/test_web/storybook/welcome.story.exs")
      |> apply_igniter!()
    end

    test "emits all foundation stories" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.storybook", ["--skip-components"])
      |> assert_creates("lib/test_web/storybook/foundations/colors.story.exs")
      |> assert_creates("lib/test_web/storybook/foundations/dark_mode.story.exs")
      |> assert_creates("lib/test_web/storybook/foundations/spacing.story.exs")
      |> assert_creates("lib/test_web/storybook/foundations/themes.story.exs")
      |> assert_creates("lib/test_web/storybook/foundations/typography.story.exs")
      |> apply_igniter!()
    end

    test "emits all example stories" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.storybook", ["--skip-components"])
      |> assert_creates("lib/test_web/storybook/examples/login.story.exs")
      |> assert_creates("lib/test_web/storybook/examples/dashboard.story.exs")
      |> assert_creates("lib/test_web/storybook/examples/settings_panel.story.exs")
      |> apply_igniter!()
    end

    test "does not emit component stories" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.storybook", ["--skip-components"])
      |> refute_creates("lib/test_web/storybook/components/button.story.exs")
      |> refute_creates("lib/test_web/storybook/components/badge.story.exs")
      |> apply_igniter!()
    end

    test "sandbox notes name the host storybook backend module" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.storybook", ["--skip-components"])

      for foundation <- ~w(colors dark_mode spacing themes typography) do
        path = "lib/test_web/storybook/foundations/#{foundation}.story.exs"

        assert_generated_source(
          igniter,
          path,
          "PhoenixStorybook backend module (e.g. TestWeb.Storybook)"
        )

        refute source_content(igniter, path) =~ "MyApp"
      end

      apply_igniter!(igniter)
    end
  end

  describe "pulsar.gen.storybook (catch-up mode)" do
    test "emits component story only for installed components" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button")
      |> Igniter.compose_task("pulsar.gen.storybook")
      |> assert_creates("lib/test_web/storybook/components/button.story.exs")
      |> refute_creates("lib/test_web/storybook/components/badge.story.exs")
      |> apply_igniter!()
    end

    test "emits foundations and examples regardless of installed components" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.storybook")
      |> assert_creates("lib/test_web/storybook/welcome.story.exs")
      |> assert_creates("lib/test_web/storybook/foundations/colors.story.exs")
      |> assert_creates("lib/test_web/storybook/examples/login.story.exs")
      |> apply_igniter!()
    end
  end

  describe "pulsar.gen.button --storybook" do
    test "emits component and story side by side" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/storybook/components/button.story.exs")
      |> apply_igniter!()
    end

    test "story uses correct web module namespace" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])

      story_path = "lib/test_web/storybook/components/button.story.exs"
      content = source_content(igniter, story_path)

      assert content =~ "defmodule TestWeb.Storybook.Components.Button"
      assert content =~ "alias TestWeb.Components.Button"

      apply_igniter!(igniter)
    end

    test "story without --storybook does not create story file" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> refute_creates("lib/test_web/storybook/components/button.story.exs")
      |> apply_igniter!()
    end

    test "does not recreate a story file that exists on disk but is not yet loaded" do
      story_path = "lib/test_web/storybook/components/button.story.exs"

      # Simulates a re-install: the story file is already present on disk
      # (test_files) but has not been read into this igniter's rewrite.
      igniter = phx_test_project()

      igniter =
        Igniter.assign(
          igniter,
          :test_files,
          Map.put(
            igniter.assigns.test_files,
            story_path,
            "defmodule TestWeb.Storybook.Components.Button do\nend\n"
          )
        )

      igniter
      |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
      |> assert_unchanged(story_path)
    end

    test "story file survives Igniter's post-write module-location normalization" do
      story_path = "lib/test_web/storybook/components/button.story.exs"
      renamed_path = "lib/test_web/storybook/components/button.exs"

      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
        |> apply_igniter!()

      assert Map.has_key?(igniter.assigns.test_files, story_path),
             "expected #{story_path} to still exist after apply"

      refute Map.has_key?(igniter.assigns.test_files, renamed_path),
             "expected Igniter not to rename the story file to #{renamed_path}"
    end

    test "re-running pulsar.gen.button --storybook over an applied project is a no-op" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
      |> assert_unchanged()
    end

    test "running the generator twice does not duplicate the dont_move_files entry" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--storybook"])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.badge", ["--storybook"])
        |> apply_igniter!()

      content = Map.fetch!(igniter.assigns.test_files, ".igniter.exs")

      occurrences = length(Regex.scan(~r/story/, content))

      assert occurrences == 1,
             "expected the story dont_move_files pattern to appear exactly once in .igniter.exs; got #{occurrences} occurrences of \"story\":\n\n#{content}"
    end
  end

  describe "pulsar.gen.badge --storybook" do
    test "emits badge component and story" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.badge", ["--storybook"])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> assert_creates("lib/test_web/storybook/components/badge.story.exs")
      |> apply_igniter!()
    end
  end

  describe "pulsar.install --storybook" do
    test "creates component + story for every installed component plus extras" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", ["--storybook", "--yes"])

      # Spot-check a couple of components get both files.
      refute is_nil(igniter.rewrite.sources["lib/test_web/components/button.ex"])
      refute is_nil(igniter.rewrite.sources["lib/test_web/storybook/components/button.story.exs"])
      refute is_nil(igniter.rewrite.sources["lib/test_web/components/badge.ex"])
      refute is_nil(igniter.rewrite.sources["lib/test_web/storybook/components/badge.story.exs"])

      # Foundations, examples, welcome get emitted by the composed
      # pulsar.gen.storybook --skip-components call.
      refute is_nil(igniter.rewrite.sources["lib/test_web/storybook/welcome.story.exs"])
      refute is_nil(igniter.rewrite.sources["lib/test_web/storybook/foundations/colors.story.exs"])
      refute is_nil(igniter.rewrite.sources["lib/test_web/storybook/examples/login.story.exs"])

      apply_igniter!(igniter)
    end

    test "forwards --components-module to component stories and storybook extras" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", [
          "--storybook",
          "--components-module",
          "Custom.UI",
          "--yes"
        ])

      # Component story (emitted by per-component generator) should alias Custom.UI.
      assert source_content(igniter, "lib/test_web/storybook/components/button.story.exs") =~
               "alias Custom.UI.Button"

      # Foundation/example stories (emitted by pulsar.gen.storybook --skip-components)
      # should also see Custom.UI — this is the bug Fix 3 addresses: argv_flags
      # must propagate from pulsar.install to the composed storybook task.
      assert source_content(igniter, "lib/test_web/storybook/foundations/spacing.story.exs") =~
               "alias Custom.UI"

      assert source_content(igniter, "lib/test_web/storybook/examples/login.story.exs") =~
               "alias Custom.UI"

      apply_igniter!(igniter)
    end
  end
end
