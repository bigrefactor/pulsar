defmodule Mix.Tasks.Pulsar.Gen.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.core_components" do
    test "creates core_components module with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", ["--components-module", "MyApp"])
      |> assert_creates("lib/my_app/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component includes Phoenix.Component usage" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component includes core utility functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
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
