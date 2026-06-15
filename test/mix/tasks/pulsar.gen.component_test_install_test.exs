defmodule Mix.Tasks.Pulsar.Gen.ComponentTestInstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.button test installation" do
    test "writes a component test file by default" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("test/test_web/components/button_test.exs")
      |> apply_igniter!()
    end

    test "--no-tests suppresses the component test file" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--no-tests"])

      refute Map.has_key?(igniter.rewrite.sources, "test/test_web/components/button_test.exs")
    end

    test "tolerates a trailing dot in --components-module when generating the test" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--components-module", "MyApp.CustomComponents."])
      |> assert_creates("test/my_app/custom_components/button_test.exs")
      |> apply_igniter!()
    end

    test "writes the test beside the component for a custom --components-module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> assert_creates("test/my_app/custom_components/button_test.exs")
      |> apply_igniter!()
    end
  end
end
