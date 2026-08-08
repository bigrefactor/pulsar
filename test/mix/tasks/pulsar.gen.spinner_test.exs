defmodule Mix.Tasks.Pulsar.Gen.SpinnerTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.spinner" do
    test "creates spinner component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.spinner", [])
      |> assert_creates("lib/test_web/components/spinner.ex")
      |> assert_generated_component("lib/test_web/components/spinner.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.spinner", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/spinner.ex")
      |> assert_generated_component("lib/my_app/custom_components/spinner.ex")
      |> apply_igniter!()
    end
  end
end
