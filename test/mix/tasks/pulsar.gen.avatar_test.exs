defmodule Mix.Tasks.Pulsar.Gen.AvatarTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.avatar" do
    test "creates avatar component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.avatar", [])
      |> assert_creates("lib/test_web/components/avatar.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.avatar", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/avatar.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.avatar", [])
      |> assert_creates("lib/test_web/components/avatar.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.avatar", [])
      |> assert_creates("lib/test_web/components/avatar.ex")
      |> apply_igniter!()
    end
  end
end
