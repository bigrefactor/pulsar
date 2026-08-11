defmodule Pulsar.GeneratorTestHelpers do
  @moduledoc false
  # Shared assertions for pulsar.gen.* task tests. source_content/2 reads the
  # Igniter rewrite first. After Igniter.Test.apply_igniter!/1 clears and
  # reloads rewrite state, it can read applied fixture content from
  # igniter.assigns[:test_files].

  import ExUnit.Assertions

  # Asserts the file at `path` defines the module that Igniter's path
  # convention maps it to (lib/my_app/foo/bar.ex -> MyApp.Foo.Bar), uses
  # Phoenix.Component, and defines its function component. The function name
  # defaults to the file basename; pass `function` when they differ
  # (link.ex defines a/1).
  def assert_generated_component(igniter, path, function \\ nil) do
    module =
      path
      |> Path.rootname(".ex")
      |> Path.relative_to("lib")
      |> Path.split()
      |> Enum.map_join(".", &Macro.camelize/1)

    function = function || Path.basename(path, ".ex")

    igniter
    |> assert_generated_source(path, "defmodule #{module} do")
    |> assert_generated_source(path, "use Phoenix.Component")
    |> assert_generated_source(path, "def #{function}(assigns)")
  end

  def assert_generated_source(igniter, path, expected) do
    assert source_content(igniter, path) =~ expected
    igniter
  end

  def source_content(igniter, path) do
    case Map.fetch(igniter.rewrite.sources, path) do
      {:ok, source} ->
        Rewrite.Source.get(source, :content)

      :error ->
        assert {:ok, content} = Map.fetch(igniter.assigns[:test_files] || %{}, path),
               "expected generated file #{path} in the igniter rewrite or test file map"

        content
    end
  end
end
