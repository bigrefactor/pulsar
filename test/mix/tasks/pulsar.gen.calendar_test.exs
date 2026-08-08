defmodule Mix.Tasks.Pulsar.Gen.CalendarTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.calendar" do
    test "creates calendar component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.calendar", [])
      |> assert_creates("lib/test_web/components/calendar.ex")
      |> assert_generated_component("lib/test_web/components/calendar.ex")
      |> assert_generated_source("lib/test_web/components/calendar.ex", ~s(name=".PulsarCalendar"))
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.calendar", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/calendar.ex")
      |> assert_generated_component("lib/my_app/custom_components/calendar.ex")
      |> apply_igniter!()
    end
  end
end
