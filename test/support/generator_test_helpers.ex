defmodule Pulsar.GeneratorTestHelpers do
  @moduledoc false
  # Shared assertions for pulsar.gen.* task tests. Content is read from the
  # Igniter rewrite, so calls belong between assert_creates/2 and
  # apply_igniter!/1 in the pipe.

  import ExUnit.Assertions

  def assert_generated_component(igniter, path) do
    assert {:ok, source} = Map.fetch(igniter.rewrite.sources, path),
           "expected generated file #{path} in the igniter rewrite"

    content = Rewrite.Source.get(source, :content)
    assert content =~ "use Phoenix.Component"
    igniter
  end
end
