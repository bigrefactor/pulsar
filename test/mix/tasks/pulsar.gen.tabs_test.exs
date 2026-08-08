defmodule Mix.Tasks.Pulsar.Gen.TabsTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.tabs" do
    test "creates tabs component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.tabs", [])
      |> assert_creates("lib/test_web/components/tabs.ex")
      |> assert_generated_component("lib/test_web/components/tabs.ex")
      |> assert_generated_source("lib/test_web/components/tabs.ex", ~s(name=".PulsarTabs"))
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.tabs", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/tabs.ex")
      |> assert_generated_component("lib/my_app/custom_components/tabs.ex")
      |> apply_igniter!()
    end
  end
end
