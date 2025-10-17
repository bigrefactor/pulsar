defmodule Mix.Tasks.Pulsar.Gen.UbadgeTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.badge" do
    test "creates badge component with default naming" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.badge", [])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.badge", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/badge.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.badge", [])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.badge", [])
        |> apply_igniter!()

      igniter
      |> Igniter.compose_task("pulsar.gen.badge", [])
      |> assert_unchanged("lib/test_web/components/badge.ex")
    end

    test "generated component uses Phoenix.Component" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.badge", [])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> apply_igniter!()
    end
  end
end
