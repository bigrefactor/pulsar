defmodule Pulsar.GeneratorTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  describe "use Pulsar.Generator argument validation" do
    test ":component must be a non-nil atom" do
      assert_raise ArgumentError, ~r/:component to be an atom/, fn ->
        defmodule BadComponentString do
          use Pulsar.Generator,
            component: "button",
            example: "mix x",
            long_doc: "doc"
        end
      end

      assert_raise ArgumentError, ~r/:component to be an atom/, fn ->
        defmodule BadComponentNil do
          use Pulsar.Generator,
            component: nil,
            example: "mix x",
            long_doc: "doc"
        end
      end
    end

    test ":example must be a binary" do
      assert_raise ArgumentError, ~r/:example to be a binary/, fn ->
        defmodule BadExample do
          use Pulsar.Generator,
            component: :button,
            example: :not_a_binary,
            long_doc: "doc"
        end
      end
    end

    test ":long_doc must be a binary" do
      assert_raise ArgumentError, ~r/:long_doc to be a binary/, fn ->
        defmodule BadLongDoc do
          use Pulsar.Generator,
            component: :button,
            example: "mix x",
            long_doc: 123
        end
      end
    end

    test ":short_doc must be a binary or false" do
      assert_raise ArgumentError, ~r/:short_doc to be a binary or false/, fn ->
        defmodule BadShortDoc do
          use Pulsar.Generator,
            component: :button,
            example: "mix x",
            long_doc: "doc",
            short_doc: true
        end
      end
    end

    test "raises KeyError when a required option is missing" do
      assert_raise KeyError, fn ->
        defmodule MissingComponent do
          use Pulsar.Generator,
            example: "mix x",
            long_doc: "doc"
        end
      end
    end
  end

  describe "defoverridable" do
    defmodule OverridesIgniter do
      use Pulsar.Generator,
        component: :badge,
        example: "mix pulsar.gen.badge",
        long_doc: "test override"

      @impl Igniter.Mix.Task
      def igniter(igniter), do: igniter
    end

    test "downstream module can override igniter/1" do
      assert OverridesIgniter.igniter(:sentinel) == :sentinel
    end
  end

  describe "install_component (shared codepath)" do
    @describetag timeout: 180_000

    test "re-running over an unchanged component writes nothing" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_unchanged()
    end

    test "re-running does not reformat the component it already wrote" do
      first =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      path = "lib/test_web/components/button.ex"
      original = source_content(first, path)

      second =
        first
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      assert source_content(second, path) == original
      assert original =~ "\n  def button(assigns) do"
    end

    test "re-running creates no backup files" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])

      refute Enum.any?(igniter.rewrite.sources, fn {path, _} -> path =~ ".bak" end)
    end

    test "an edited component is overwritten with the current Pulsar version" do
      igniter =
        phx_test_project(
          files: %{
            "lib/test_web/components/button.ex" => """
            defmodule TestWeb.Components.Button do
              @moduledoc "hand-edited"
            end
            """
          }
        )
        |> Igniter.compose_task("pulsar.gen.button", [])

      assert_changed(igniter, "lib/test_web/components/button.ex")
      assert source_content(igniter, "lib/test_web/components/button.ex") =~ "def button(assigns) do"

      apply_igniter!(igniter)
    end

    test "raises a descriptive error when a template is missing" do
      igniter = phx_test_project()

      assert_raise ArgumentError, ~r/Pulsar template missing for component :__nonexistent__/, fn ->
        igniter
        |> Pulsar.Generator.set_default_component_module()
        |> Pulsar.Generator.install_component(:__nonexistent__, [])
      end
    end

    test "tolerates trailing dot in --components-module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [
        "--components-module",
        "MyApp.CustomComponents."
      ])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> apply_igniter!()
    end

    test "handles deeply nested --components-module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [
        "--components-module",
        "MyApp.Web.Live.Components.Generated"
      ])
      |> assert_creates("lib/my_app/web/live/components/generated/button.ex")
      |> apply_igniter!()
    end

    test "rejects empty --components-module" do
      assert_raise ArgumentError, ~r/non-empty module name/, fn ->
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--components-module", ""])
        |> apply_igniter!()
      end
    end

    test "rejects invalid module name in --components-module" do
      assert_raise ArgumentError, ~r/invalid module name/, fn ->
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [
          "--components-module",
          "123_not_a_module"
        ])
        |> apply_igniter!()
      end
    end
  end

  defp source_content(igniter, path) do
    {:ok, source} = Map.fetch(igniter.rewrite.sources, path)
    Rewrite.Source.get(source, :content)
  end

  defp assert_changed(igniter, path_or_paths) do
    for path <- List.wrap(path_or_paths) do
      assert Igniter.changed?(igniter, path), """
      Expected #{inspect(path)} to be changed, but it was unchanged.
      """
    end

    igniter
  end

  describe "use Pulsar.Generator component registration" do
    test "raises for a component not registered in Pulsar.ComponentDeps" do
      assert_raise ArgumentError, ~r/unregistered component/, fn ->
        defmodule UnregisteredComponent do
          use Pulsar.Generator,
            component: :not_a_real_component,
            example: "mix x",
            long_doc: "doc"
        end
      end
    end
  end

  describe "long_doc dependency section" do
    test "dep-carrying tasks document their generated dependencies" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} =
        Code.fetch_docs(Mix.Tasks.Pulsar.Gen.Dropzone)

      assert moduledoc =~ "## Dependencies"
      assert moduledoc =~ "icon"
      assert moduledoc =~ "progress"
    end

    test "dep-free tasks get no dependency section" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} =
        Code.fetch_docs(Mix.Tasks.Pulsar.Gen.Badge)

      refute moduledoc =~ "## Dependencies"
    end

    test "no gen task carries a duplicate Dependencies heading" do
      for component <- Pulsar.ComponentDeps.all() do
        module = Module.concat(Mix.Tasks.Pulsar.Gen, Macro.camelize(to_string(component)))
        {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(module)

        headings = moduledoc |> String.split("## Dependencies") |> length() |> Kernel.-(1)

        assert headings <= 1,
               "#{inspect(module)} moduledoc has #{headings} '## Dependencies' headings"
      end
    end
  end
end
