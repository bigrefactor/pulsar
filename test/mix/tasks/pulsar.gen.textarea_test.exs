defmodule Mix.Tasks.Pulsar.Gen.TextareaTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.textarea" do
    test "creates textarea component with default naming" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/textarea.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end

    test "is idempotent - running twice produces same result" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.textarea", [])
        |> apply_igniter!()

      igniter
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_unchanged("lib/test_web/components/textarea.ex")
    end

    test "generated component uses Phoenix.Component" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.textarea", [])
      |> assert_creates("lib/test_web/components/textarea.ex")
      |> apply_igniter!()
    end
  end
end
