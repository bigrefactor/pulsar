defmodule Mix.Tasks.Pulsar.Gen.CardTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.card" do
    test "creates card component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.card", [])
      |> assert_creates("lib/test_web/components/card.ex")
      |> assert_generated_component("lib/test_web/components/card.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.card", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/card.ex")
      |> assert_generated_component("lib/my_app/custom_components/card.ex")
      |> apply_igniter!()
    end
  end
end
