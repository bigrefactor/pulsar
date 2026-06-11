defmodule Mix.Tasks.Pulsar.Gen.CalendarTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.calendar" do
    test "creates calendar component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.calendar", [])
      |> assert_creates("lib/test_web/components/calendar.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.calendar", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/calendar.ex")
      |> apply_igniter!()
    end
  end
end
