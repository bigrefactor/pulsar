defmodule Mix.Tasks.Pulsar.Gen.ListTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.list" do
    test "creates list component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.list", [])
      |> assert_creates("lib/test_web/components/list.ex")
      |> assert_generated_component("lib/test_web/components/list.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.list", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/list.ex")
      |> assert_generated_component("lib/my_app/custom_components/list.ex")
      |> apply_igniter!()
    end
  end
end
