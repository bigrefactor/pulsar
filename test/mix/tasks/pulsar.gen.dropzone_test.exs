defmodule Mix.Tasks.Pulsar.Gen.DropzoneTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  describe "pulsar.gen.dropzone" do
    test "creates dropzone component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.dropzone", [])
      |> assert_creates("lib/test_web/components/dropzone.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.dropzone", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/dropzone.ex")
      |> apply_igniter!()
    end
  end
end
