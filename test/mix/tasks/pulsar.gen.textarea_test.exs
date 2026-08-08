defmodule Mix.Tasks.Pulsar.Gen.TextareaTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.textarea" do
    test "creates textarea component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> assert_generated_component("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/textarea.ex")
      |> apply_igniter!()
    end
  end
end
