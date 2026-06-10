defmodule Mix.Tasks.Pulsar.Gen.SpinnerTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.spinner" do
    test "creates spinner component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.spinner", [])
      |> assert_creates("lib/test_web/components/spinner.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.spinner", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/spinner.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.spinner", [])
      |> assert_creates("lib/test_web/components/spinner.ex")
      |> apply_igniter!()
    end
  end
end
