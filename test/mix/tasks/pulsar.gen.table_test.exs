defmodule Mix.Tasks.Pulsar.Gen.TableTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.table" do
    test "creates table component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.table", [])
      |> assert_creates("lib/test_web/components/table.ex")
      |> assert_generated_component("lib/test_web/components/table.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.table", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/table.ex")
      |> assert_generated_component("lib/my_app/custom_components/table.ex")
      |> apply_igniter!()
    end
  end
end
