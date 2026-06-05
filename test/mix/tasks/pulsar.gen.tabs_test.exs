defmodule Mix.Tasks.Pulsar.Gen.TabsTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.tabs" do
    test "creates tabs component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.tabs", [])
      |> assert_creates("lib/test_web/components/tabs.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.tabs", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/tabs.ex")
      |> apply_igniter!()
    end
  end
end
