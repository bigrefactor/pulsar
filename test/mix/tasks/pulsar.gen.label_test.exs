defmodule Mix.Tasks.Pulsar.Gen.LabelTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.label" do
    test "creates label component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.label", [])
      |> assert_creates("lib/test_web/components/label.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.label", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/label.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.label", [])
      |> assert_creates("lib/test_web/components/label.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.label", [])
      |> assert_creates("lib/test_web/components/label.ex")
      |> apply_igniter!()
    end
  end
end
