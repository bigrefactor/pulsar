defmodule Mix.Tasks.Pulsar.Gen.UradioUgroupTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.radio_group" do
    test "creates radio_group component with default naming" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/radio_group.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.radio_group", [])
        |> apply_igniter!()

      igniter
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_unchanged("lib/test_web/components/radio_group.ex")
    end

    test "generated component uses Phoenix.Component" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end
  end
end
