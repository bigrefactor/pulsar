defmodule Pulsar.Generator do
  @moduledoc """
  Provides core component generation functionality for Pulsar.

  This module handles the installation and generation of Pulsar components
  into Phoenix applications using Igniter's code generation capabilities.
  It manages component module creation, namespace resolution, and template rendering.
  """

  alias Igniter.Libs.Phoenix

  def install_component(igniter, component_name, assigns) do
    namespace = igniter.args.options[:components_module]
    component_module = component_name |> to_string() |> Macro.camelize()

    # Convert namespace to string and build module atom
    namespace_string = to_string(namespace)
    component = Module.concat(String.split(namespace_string, ".") ++ [component_module])

    contents = contents(component_name, Keyword.put_new(assigns, :component_namespace, namespace))

    igniter
    |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
    |> Igniter.Project.Module.create_module(component, contents)
  end

  def set_default_component_module(igniter) do
    igniter = Igniter.compose_task(igniter, "igniter.add_extension", ["phoenix"])
    default = Phoenix.web_module_name(igniter, "Components")

    update_in(igniter.args.options, fn opts ->
      opts = opts || []
      Keyword.put_new(opts, :components_module, default)
    end)
  end

  defp contents(component_name, assigns) do
    template =
      :pulsar
      |> :code.priv_dir()
      |> Path.join("templates")
      |> Path.join("#{component_name}.ex.eex")

    EEx.eval_file(template, assigns: assigns)
  end
end
