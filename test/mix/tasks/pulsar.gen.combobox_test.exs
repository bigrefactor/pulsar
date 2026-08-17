defmodule Mix.Tasks.Pulsar.Gen.ComboboxTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  describe "pulsar.gen.combobox" do
    test "creates the combobox component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.combobox", [])
      |> assert_creates("lib/test_web/components/combobox.ex")
    end

    test "writes a component test file by default" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.combobox", [])
      |> assert_creates("test/test_web/components/combobox_test.exs")
      |> apply_igniter!()
    end

    test "--no-tests suppresses the component test file" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.combobox", ["--no-tests"])

      refute Map.has_key?(igniter.rewrite.sources, "test/test_web/components/combobox_test.exs")
    end

    test "also generates its badge, icon, popover, and spinner dependencies" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.combobox", [])
      |> assert_creates("lib/test_web/components/badge.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> assert_creates("lib/test_web/components/popover.ex")
      |> assert_creates("lib/test_web/components/spinner.ex")
    end

    test "honors a custom components module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.combobox", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/combobox.ex")
    end
  end
end
