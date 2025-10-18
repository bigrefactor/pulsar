defmodule Mix.Tasks.Pulsar.Gen.RadioUgroupTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.radio_group" do
    test "creates radio_group component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/radio_group.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.radio_group", [])
      |> assert_creates("lib/test_web/components/radio_group.ex")
      |> apply_igniter!()
    end
  end
end
