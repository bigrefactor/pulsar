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
end
