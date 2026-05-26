defmodule Mix.Tasks.Pulsar.Gen.StorybookTest do
  use ExUnit.Case, async: true

  import Igniter.Test

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
      source = igniter.rewrite.sources[story_path]
      refute is_nil(source), "Expected #{story_path} to have been created"
      content = Rewrite.Source.get(source, :content)

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
      button_story = igniter.rewrite.sources["lib/test_web/storybook/components/button.story.exs"]
      refute is_nil(button_story), "expected button story to be created"
      assert Rewrite.Source.get(button_story, :content) =~ "alias Custom.UI.Button"

      # Foundation/example stories (emitted by pulsar.gen.storybook --skip-components)
      # should also see Custom.UI — this is the bug Fix 3 addresses: argv_flags
      # must propagate from pulsar.install to the composed storybook task.
      spacing_story = igniter.rewrite.sources["lib/test_web/storybook/foundations/spacing.story.exs"]
      refute is_nil(spacing_story), "expected spacing foundation to be created"
      assert Rewrite.Source.get(spacing_story, :content) =~ "alias Custom.UI"

      login_story = igniter.rewrite.sources["lib/test_web/storybook/examples/login.story.exs"]
      refute is_nil(login_story), "expected login example to be created"
      assert Rewrite.Source.get(login_story, :content) =~ "alias Custom.UI"

      apply_igniter!(igniter)
    end
  end
end
