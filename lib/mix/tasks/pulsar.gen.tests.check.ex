defmodule Mix.Tasks.Pulsar.Gen.Tests.Check do
  @moduledoc false
  use Mix.Task

  alias Pulsar.ComponentDeps
  alias Pulsar.Generator.ComponentTest

  @dir "tmp/gen_test_check"

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    File.rm_rf!(@dir)
    File.mkdir_p!(@dir)

    components = Enum.filter(ComponentDeps.all(), &ComponentTest.generates_test?/1)

    Enum.each(components, fn component ->
      src = ComponentTest.render(component, "Pulsar.Components")
      File.write!(Path.join(@dir, "#{component}_test.exs"), src)
    end)

    Mix.shell().info(
      "Generated #{length(components)} component tests into #{@dir}. " <>
        "Run `mix test #{@dir}` to verify them."
    )
  end
end
