defmodule Mix.Tasks.Pulsar.Gen.FlashGroupTest do
  use ExUnit.Case, async: false

  import Igniter.Test
  import Pulsar.GeneratorTestHelpers

  describe "pulsar.gen.flash_group" do
    test "creates flash_group component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.flash_group", [])
      |> assert_creates("lib/test_web/components/flash_group.ex")
      |> assert_generated_component("lib/test_web/components/flash_group.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.flash_group", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/flash_group.ex")
      |> assert_generated_component("lib/my_app/custom_components/flash_group.ex")
      |> apply_igniter!()
    end

    test "doc examples name the host web module, not a placeholder" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.flash_group", [])

      path = "lib/test_web/components/flash_group.ex"

      igniter
      |> assert_generated_source(path, "defmodule TestWeb.PageLive do")
      |> assert_generated_source(path, "use TestWeb, :live_view")
      |> assert_generated_source(path, "defmodule TestWeb.UserController do")
      |> assert_generated_source(path, "use TestWeb, :controller")
      |> assert_generated_source(path, ":telemetry.execute([:test, :flash, :dismissed]")

      refute source_content(igniter, path) =~ "Analytics.track"

      apply_igniter!(igniter)
    end
  end
end
