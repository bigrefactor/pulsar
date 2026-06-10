defmodule Mix.Tasks.Pulsar.Gen.StatusTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.status" do
    test "creates status component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.status", [])
      |> assert_creates("lib/test_web/components/status.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.status", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/status.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.status", [])
      |> assert_creates("lib/test_web/components/status.ex")
      |> apply_igniter!()
    end
  end
end
