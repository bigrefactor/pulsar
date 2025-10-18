defmodule Mix.Tasks.Pulsar.Gen.UdividerTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.divider" do
    test "creates divider component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.divider", [])
      |> assert_creates("lib/test_web/components/divider.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.divider", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/divider.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.divider", [])
      |> assert_creates("lib/test_web/components/divider.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.divider", [])
      |> assert_creates("lib/test_web/components/divider.ex")
      |> apply_igniter!()
    end
  end
end
