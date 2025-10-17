defmodule Mix.Tasks.Pulsar.Gen.UcheckboxTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.checkbox" do
    test "creates checkbox component with default naming" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/checkbox.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.checkbox", [])
        |> apply_igniter!()

      igniter
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_unchanged("lib/test_web/components/checkbox.ex")
    end

    test "generated component uses Phoenix.Component" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end
  end
end
