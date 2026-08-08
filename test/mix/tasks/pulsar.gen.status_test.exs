defmodule Mix.Tasks.Pulsar.Gen.StatusTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.status" do
    test "creates status component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.status", [])
      |> assert_creates("lib/test_web/components/status.ex")
      |> assert_generated_component("lib/test_web/components/status.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.status", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/status.ex")
      |> apply_igniter!()
    end
  end
end
