defmodule Mix.Tasks.Pulsar.Gen.AlertTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.alert" do
    test "creates alert component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.alert", [])
      |> assert_creates("lib/test_web/components/alert.ex")
      |> assert_generated_component("lib/test_web/components/alert.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.alert", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/alert.ex")
      |> assert_generated_component("lib/my_app/custom_components/alert.ex")
      |> apply_igniter!()
    end
  end
end
