defmodule Pulsar.Generator do
  @moduledoc """
  Provides core component generation functionality for Pulsar.

  This module handles the installation and generation of Pulsar components
  into Phoenix applications using Igniter's code generation capabilities.
  It manages component module creation, namespace resolution, and template rendering.
  """

  alias Igniter.Libs.Phoenix

  def install_component(igniter, component_name, assigns) do
    namespace = Igniter.Project.Module.parse(to_string(igniter.args.options[:components_module]))
    component = component_module(igniter, component_name)
    # Convert namespace to inspect format to avoid Elixir. prefix in templates
    namespace_inspected = inspect(namespace)

    # For core_components, we need both the web module and the components namespace
    # Core components module goes under web module, but it needs to alias components
    assigns =
      assigns
      |> Keyword.put_new(:component_namespace, namespace_inspected)
      |> Keyword.put_new(:components_namespace, get_components_namespace(igniter, namespace_inspected))

    contents = contents(component_name, assigns)
    {exists, igniter} = Igniter.Project.Module.module_exists(igniter, component)

    if exists do
      {igniter, source, _} = Igniter.Project.Module.find_module!(igniter, component)

      # Wrap template contents in module definition for existing files
      wrapped_contents = """
      defmodule #{inspect(component)} do
        #{contents}
      end
      """

      igniter
      |> backup_existing_component(source.path)
      |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
      |> Igniter.update_file(source.path, fn source ->
        Rewrite.Source.update(source, :content, wrapped_contents)
      end)
    else
      igniter
      |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
      |> Igniter.Project.Module.create_module(component, contents)
    end
  end

  defp backup_existing_component(igniter, path) do
    case Map.fetch(igniter.rewrite.sources, path) do
      {:ok, source} ->
        ts = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601(:basic)
        backup_path = "#{path}.bak.#{ts}"
        content = Rewrite.Source.get(source, :content)

        Igniter.create_new_file(igniter, backup_path, content)

      :error ->
        igniter
    end
  end

  def set_default_component_module(igniter) do
    igniter = Igniter.compose_task(igniter, "igniter.add_extension", ["phoenix"])
    default = Phoenix.web_module_name(igniter, "Components")

    update_in(igniter.args.options, fn opts ->
      opts = opts || []
      Keyword.put_new(opts, :components_module, default)
    end)
  end

  defp component_module(igniter, component_name) do
    namespace = namespace(igniter)

    Module.concat(namespace, Macro.camelize(to_string(component_name)))
  end

  defp namespace(igniter) do
    Igniter.Project.Module.parse(to_string(igniter.args.options[:components_module]))
  end

  defp get_components_namespace(igniter, _namespace_inspected) do
    # Get the default components namespace (e.g., MyAppWeb.Components)
    default = Phoenix.web_module_name(igniter, "Components")
    inspect(default)
  end

  defp contents(component_name, assigns) do
    template =
      :pulsar
      |> :code.priv_dir()
      |> Path.join("templates")
      |> Path.join("#{component_name}.ex.eex")

    EEx.eval_file(template, assigns: assigns, engine: EEx.SmartEngine)
  end
end
