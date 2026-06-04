defmodule Mix.Tasks.Pulsar.Gen.SkeletonTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.skeleton" do
    test "creates skeleton component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.skeleton", [])
      |> assert_creates("lib/test_web/components/skeleton.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.skeleton", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/skeleton.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.skeleton", [])
      |> assert_creates("lib/test_web/components/skeleton.ex")
      |> apply_igniter!()
    end
  end
end
