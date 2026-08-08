defmodule Mix.Tasks.Pulsar.Gen.SwitchTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.switch" do
    test "creates switch component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.switch", [])
      |> assert_creates("lib/test_web/components/switch.ex")
      |> assert_generated_component("lib/test_web/components/switch.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.switch", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/switch.ex")
      |> apply_igniter!()
    end
  end
end
