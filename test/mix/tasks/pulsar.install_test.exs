defmodule Mix.Tasks.Pulsar.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  alias Igniter.Project.Deps

  describe "pulsar.install" do
    test "installs all components by default with --all flag" do
      test_project()
      |> Igniter.compose_task("pulsar.install", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/input.ex")
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> assert_creates("lib/test_web/components/select.ex")
      |> apply_igniter!()
    end

    test "installs core_components by default" do
      test_project()
      |> Igniter.compose_task("pulsar.install", [])
      |> assert_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "can skip core_components with --no-core-components flag" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--no-core-components"])
      |> refute_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "installs specific components with --component flag" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "button,checkbox", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> refute_creates("lib/test_web/components/select.ex")
      |> refute_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.install", ["--component", "button", "--no-core-components", "--yes"])
        |> apply_igniter!()

      # Running the task a second time should not change files
      igniter
      |> Igniter.compose_task("pulsar.install", ["--component", "button", "--no-core-components", "--yes"])
      |> assert_unchanged("lib/test_web/components/button.ex")
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.install", [
        "--component",
        "button",
        "--components-module",
        "MyApp.CustomComponents",
        "--no-core-components",
        "--yes"
      ])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> apply_igniter!()
    end

    test "installs button with its link dependency" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "button", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/link.ex")
      |> apply_igniter!()
    end

    test "installs flash_group with its dependencies (flash and icon)" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "flash_group", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/flash_group.ex")
      |> assert_creates("lib/test_web/components/flash.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "installs field with all its dependencies" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "field", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/field.ex")
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> assert_creates("lib/test_web/components/input.ex")
      |> assert_creates("lib/test_web/components/label.ex")
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> assert_creates("lib/test_web/components/select.ex")
      |> assert_creates("lib/test_web/components/switch.ex")
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "installs select with badge dependency" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "select", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/select.ex")
      |> assert_creates("lib/test_web/components/badge.ex")
      |> apply_igniter!()
    end

    test "installs theme by default" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--yes"])
      |> assert_creates("assets/css/theme.css")
      |> assert_creates("assets/css/app.css")
      |> apply_igniter!()
    end

    test "can skip theme with --no-theme flag" do
      test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--no-theme", "--yes"])
      |> refute_creates("assets/css/theme.css")
      |> refute_creates("assets/css/app.css")
      |> apply_igniter!()
    end

    test "adds tailwind_merge as dependency to mix.exs" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--yes"])

      # Verify tailwind_merge dependency was added
      assert Deps.has_dep?(igniter, :tailwind_merge)
    end
  end
end
