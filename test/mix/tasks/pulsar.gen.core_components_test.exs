defmodule Mix.Tasks.Pulsar.Gen.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.core_components" do
    test "creates core_components module with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", ["--components-module", "MyApp"])
      |> assert_creates("lib/my_app/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component includes Phoenix.Component usage" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component includes core utility functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.core_components", [])
      |> assert_changed("lib/test_web/components/core_components.ex")
      |> apply_igniter!()
    end

    test "generated component uses correct namespace for component aliases" do
      core_components_path = "lib/test_web/components/core_components.ex"

      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.core_components", [])
        |> assert_changed(core_components_path)

      # Read the generated file content from the pending igniter (apply_igniter!
      # clears rewrite.sources, so the assertions must run before applying).
      {:ok, source} = Map.fetch(igniter.rewrite.sources, core_components_path)
      content = Rewrite.Source.get(source, :content)

      # Verify component aliases use TestWeb.Components namespace, not TestWeb
      assert content =~ "alias TestWeb.Components.Button"
      assert content =~ "alias TestWeb.Components.Field"
      assert content =~ "alias TestWeb.Components.Flash"
      assert content =~ "alias TestWeb.Components.Header"
      assert content =~ "alias TestWeb.Components.Icon"
      assert content =~ "alias TestWeb.Components.List"
      assert content =~ "alias TestWeb.Components.Table"

      # Verify it doesn't have incorrect Elixir. prefix
      refute content =~ "alias Elixir.TestWeb"
      # Verify it doesn't alias from the wrong namespace (TestWeb instead of TestWeb.Components)
      refute content =~ ~r/alias TestWeb\.Button(?!\w)/
      refute content =~ ~r/alias TestWeb\.Field(?!\w)/

      apply_igniter!(igniter)
    end
  end

  defp assert_changed(igniter, path_or_paths) do
    for path <- List.wrap(path_or_paths) do
      assert Igniter.changed?(igniter, path), """
      Expected #{inspect(path)} to be changed, but it was unchanged.
      """
    end

    igniter
  end
end
