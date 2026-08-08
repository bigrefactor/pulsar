defmodule Mix.Tasks.Pulsar.Gen.FormTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.form" do
    test "creates form component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", [])
      |> assert_creates("lib/test_web/components/form.ex")
      |> assert_generated_component("lib/test_web/components/form.ex")
      |> assert_generated_source("lib/test_web/components/form.ex", ~s(name=".PulsarForm"))
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.form", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/form.ex")
      |> assert_generated_component("lib/my_app/custom_components/form.ex")
      |> apply_igniter!()
    end
  end
end
