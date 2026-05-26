defmodule Mix.Tasks.Pulsar.Gen.FormTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.form" do
    test "creates form component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", [])
      |> assert_creates("lib/test_web/components/form.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/form.ex")
      |> apply_igniter!()
    end

    test "generated component includes the PulsarForm colocated hook" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", [])
      |> assert_creates("lib/test_web/components/form.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", [])
      |> assert_creates("lib/test_web/components/form.ex")
      |> apply_igniter!()
    end
  end
end
