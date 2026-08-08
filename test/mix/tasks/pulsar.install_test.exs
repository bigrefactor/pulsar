defmodule Mix.Tasks.Pulsar.InstallTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  alias Igniter.Project.Deps

  @moduletag timeout: 180_000

  describe "pulsar.install" do
    test "installs all components by default with --all flag" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/input.ex")
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> assert_creates("lib/test_web/components/select.ex")
      |> apply_igniter!()
    end

    test "installs core_components by default" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "can skip core_components with --no-core-components flag" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--no-core-components"])
      |> refute_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "installs specific components with --component flag" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "button,checkbox", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> refute_creates("lib/test_web/components/select.ex")
      |> refute_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
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

    test "installs button with its transitive link and icon dependencies" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "button", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/button.ex")
      |> assert_creates("lib/test_web/components/link.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "installs date_picker with its transitive dependencies" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "date_picker", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/date_picker.ex")
      |> assert_creates("lib/test_web/components/calendar.ex")
      |> assert_creates("lib/test_web/components/popover.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "installs flash_group with its dependencies (flash and icon)" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "flash_group", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/flash_group.ex")
      |> assert_creates("lib/test_web/components/flash.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "installs field with all its dependencies" do
      phx_test_project()
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

    test "installs select with badge and icon dependencies" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "select", "--no-core-components", "--yes"])
      |> assert_creates("lib/test_web/components/select.ex")
      |> assert_creates("lib/test_web/components/badge.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "installs theme by default" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--yes"])
      |> assert_creates("assets/css/theme.css")
      |> assert_changed("assets/css/app.css")
      |> apply_igniter!()
    end

    test "can skip theme with --no-theme flag" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--no-theme", "--yes"])
      |> refute_creates("assets/css/theme.css")
      |> refute_creates("assets/css/app.css")
      |> apply_igniter!()
    end

    test "adds twm as dependency to mix.exs" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", ["--component", "badge", "--no-core-components", "--yes"])

      # Verify twm dependency was added
      assert Deps.has_dep?(igniter, :twm)
    end

    test "re-running the installer over an installed project writes nothing" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--yes"])
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.install", ["--yes"])
      |> assert_unchanged()
    end

    test "re-running the installer with --storybook writes nothing" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.install", ["--yes", "--storybook"])
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.install", ["--yes", "--storybook"])
      |> assert_unchanged()
    end

    test "re-running the installer creates no backup files" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.install", ["--yes"])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.install", ["--yes"])

      refute Enum.any?(igniter.rewrite.sources, fn {path, _} -> path =~ ".bak" end)
    end
  end

  defp assert_changed(igniter, path_or_paths) do
    for path <- List.wrap(path_or_paths) do
      assert Igniter.changed?(igniter, path), """
      Expected #{inspect(path)} to be changed, but it was unchanged.
      """
    end

    igniter
  end
end
