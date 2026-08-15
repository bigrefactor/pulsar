defmodule Mix.Tasks.Pulsar.Gen.CommandTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  describe "pulsar.gen.command" do
    test "creates the command component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.command", [])
      |> assert_creates("lib/test_web/components/command.ex")
    end

    test "writes a component test file by default" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.command", [])
      |> assert_creates("test/test_web/components/command_test.exs")
      |> apply_igniter!()
    end

    test "--no-tests suppresses the component test file" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.command", ["--no-tests"])

      refute Map.has_key?(igniter.rewrite.sources, "test/test_web/components/command_test.exs")
    end

    test "also generates its icon and spinner dependencies" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.command", [])
      |> assert_creates("lib/test_web/components/icon.ex")
      |> assert_creates("lib/test_web/components/spinner.ex")
    end

    test "honors a custom components module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.command", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/command.ex")
    end
  end
end
