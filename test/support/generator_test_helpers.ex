defmodule Pulsar.GeneratorTestHelpers do
  @moduledoc false

  # Shared assertions for pulsar.gen.* task tests. Content is read from the
  # Igniter rewrite, so calls belong between assert_creates/2 and
  # apply_igniter!/1 in the pipe.
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
    assert {:ok, source} = Map.fetch(igniter.rewrite.sources, path),
           "expected generated file #{path} in the igniter rewrite"

    Rewrite.Source.get(source, :content)
  end
end
