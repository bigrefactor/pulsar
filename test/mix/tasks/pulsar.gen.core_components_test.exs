defmodule Mix.Tasks.Pulsar.Gen.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.core_components" do
    test "creates core_components module with default naming" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", ["--components-module", "MyApp"])
      |> assert_creates("lib/my_app/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component includes Phoenix.Component usage" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.core_components", [])
        |> apply_igniter!()

      igniter
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_unchanged("lib/test_web/components/core_components.ex")
    end

    test "generated component includes core utility functions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_creates("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end
  end
end
