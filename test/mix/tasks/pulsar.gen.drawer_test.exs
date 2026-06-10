defmodule Mix.Tasks.Pulsar.Gen.DrawerTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.drawer" do
    test "creates drawer component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.drawer", [])
      |> assert_creates("lib/test_web/components/drawer.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.drawer", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/drawer.ex")
      |> apply_igniter!()
    end
  end
end
