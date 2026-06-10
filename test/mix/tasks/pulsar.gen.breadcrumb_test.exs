defmodule Mix.Tasks.Pulsar.Gen.BreadcrumbTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.breadcrumb" do
    test "creates breadcrumb component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.breadcrumb", [])
      |> assert_creates("lib/test_web/components/breadcrumb.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.breadcrumb", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/breadcrumb.ex")
      |> apply_igniter!()
    end
  end
end
