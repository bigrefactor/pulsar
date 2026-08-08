defmodule Mix.Tasks.Pulsar.Gen.ProgressTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.progress" do
    test "creates progress component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.progress", [])
      |> assert_creates("lib/test_web/components/progress.ex")
      |> assert_generated_component("lib/test_web/components/progress.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.progress", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/progress.ex")
      |> assert_generated_component("lib/my_app/custom_components/progress.ex")
      |> apply_igniter!()
    end
  end
end
