defmodule Mix.Tasks.Pulsar.Gen.IconTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.icon" do
    test "creates icon component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.icon", [])
      |> assert_creates("lib/test_web/components/icon.ex")
      |> assert_generated_component("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.icon", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/icon.ex")
      |> apply_igniter!()
    end
  end
end
