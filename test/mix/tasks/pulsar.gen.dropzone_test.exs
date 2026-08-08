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

    test "generates missing icon and progress dependencies with their smoke tests" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.dropzone", [])
      |> assert_creates("lib/test_web/components/dropzone.ex")
      |> assert_creates("lib/test_web/components/icon.ex")
      |> assert_creates("lib/test_web/components/progress.ex")
      |> assert_creates("test/test_web/components/icon_test.exs")
      |> assert_creates("test/test_web/components/progress_test.exs")
      |> apply_igniter!()
    end

    test "does not overwrite an existing dependency component" do
      sentinel = """
      defmodule TestWeb.Components.Icon do
        def sentinel, do: :untouched
      end
      """

      phx_test_project()
      |> Igniter.create_new_file("lib/test_web/components/icon.ex", sentinel)
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.gen.dropzone", [])
      |> assert_creates("lib/test_web/components/dropzone.ex")
      |> assert_creates("lib/test_web/components/progress.ex")
      |> assert_unchanged("lib/test_web/components/icon.ex")
      |> apply_igniter!()
    end
  end
end
