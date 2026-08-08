defmodule Mix.Tasks.Pulsar.Gen.BadgeTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.badge" do
    test "creates badge component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.badge", [])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> assert_generated_component("lib/test_web/components/badge.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.badge", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/badge.ex")
      |> apply_igniter!()
    end
  end
end
