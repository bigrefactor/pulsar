defmodule Mix.Tasks.Pulsar.Gen.InputTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.input" do
    test "creates input component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.input", [])
      |> assert_creates("lib/test_web/components/input.ex")
      |> assert_generated_component("lib/test_web/components/input.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.input", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/input.ex")
      |> assert_generated_component("lib/my_app/custom_components/input.ex")
      |> apply_igniter!()
    end
  end
end
