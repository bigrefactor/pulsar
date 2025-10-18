defmodule Mix.Tasks.Pulsar.Gen.TextareaTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.textarea" do
    test "creates textarea component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/textarea.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end
  end
end
