defmodule Mix.Tasks.Pulsar.Gen.ButtonTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.button" do
    test "creates button component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end
  end
end
