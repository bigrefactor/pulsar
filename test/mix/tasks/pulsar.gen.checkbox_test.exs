defmodule Mix.Tasks.Pulsar.Gen.UcheckboxTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.checkbox" do
    test "creates checkbox component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/checkbox.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.checkbox", [])
      |> assert_creates("lib/test_web/components/checkbox.ex")
      |> apply_igniter!()
    end
  end
end
