defmodule Mix.Tasks.Pulsar.Gen.AlertTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.alert" do
    test "creates alert component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.alert", [])
      |> assert_creates("lib/test_web/components/alert.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.alert", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/alert.ex")
      |> apply_igniter!()
    end
  end
end
