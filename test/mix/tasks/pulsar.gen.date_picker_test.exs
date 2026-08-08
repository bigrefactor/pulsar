defmodule Mix.Tasks.Pulsar.Gen.DatePickerTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  describe "pulsar.gen.date_picker" do
    test "creates date_picker component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.date_picker", [])
      |> assert_creates("lib/test_web/components/date_picker.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.date_picker", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/date_picker.ex")
      |> apply_igniter!()
    end

    test "generates missing dependencies transitively" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.date_picker", [])
      |> assert_creates("lib/test_web/components/date_picker.ex")
      |> assert_creates("lib/test_web/components/calendar.ex")
      |> assert_creates("lib/test_web/components/popover.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end

    test "generates dependencies under a custom components module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.date_picker", [
        "--components-module",
        "MyApp.CustomComponents"
      ])
      |> assert_creates("lib/my_app/custom_components/date_picker.ex")
      |> assert_creates("lib/my_app/custom_components/calendar.ex")
      |> apply_igniter!()
    end
  end
end
