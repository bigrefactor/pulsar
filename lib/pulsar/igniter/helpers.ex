defmodule Pulsar.Igniter.Helpers do
  @moduledoc """
  Helper functions for Pulsar Igniter tasks.

  Provides utilities for detecting project structure, resolving module names,
  and managing component generation paths.
  """

  alias Igniter.Libs.Phoenix

  @doc """
  List all available Pulsar components.
  """
  def list_available_components do
    [
      "badge",
      "button",
      "card",
      "checkbox",
      "divider",
      "field",
      "flash",
      "flash_group",
      "header",
      "icon",
      "input",
      "label",
      "link",
      "list",
      "radio_group",
      "select",
      "switch",
      "table",
      "textarea"
    ]
  end

  @doc """
  Detect the web module using Igniter's Phoenix library.
  """
  def detect_web_module(igniter) do
    case Phoenix.web_module(igniter) do
      {:ok, web_module} -> web_module
      {:error, _} -> nil
    end
  end

  @doc """
  Get the app name using Igniter's Application library.
  """
  def detect_app_name(igniter) do
    case Igniter.Project.Application.app_name(igniter) do
      {:ok, app_name} -> app_name
      {:error, _} -> nil
    end
  end

  @doc """
  Resolve the destination path for a component using Igniter's Module library.

  ## Options

  - `:subdir` - Subdirectory name (default: "ui")
  - `:flat` - When true, no subdirectory is used

  ## Examples

      iex> resolve_component_path(igniter, "button", "MyAppWeb", subdir: "ui")
      "lib/my_app_web/components/ui/button.ex"
  """
  def resolve_component_path(igniter, component_name, web_module, opts \\ []) do
    module_name = resolve_module_name(component_name, web_module, opts)

    case Igniter.Project.Module.proper_location(igniter, module_name) do
      {:ok, path} ->
        # Adjust path based on options
        adjust_path_for_options(path, opts)

      {:error, _} ->
        # Fallback to manual calculation
        fallback_component_path(component_name, web_module, opts)
    end
  end

  defp adjust_path_for_options(path, opts) do
    if opts[:flat] do
      # Remove subdirectory from path
      path
      |> Path.split()
      # Replace ui with components
      |> List.replace_at(-2, "components")
      |> Path.join()
    else
      path
    end
  end

  defp fallback_component_path(component_name, web_module, opts) do
    app_name = web_module |> String.replace("Web", "") |> Macro.underscore()

    base_path = "lib/#{app_name}_web/components"

    subdir =
      cond do
        opts[:flat] -> ""
        opts[:subdir] -> opts[:subdir]
        true -> "ui"
      end

    path_parts =
      [base_path, subdir, "#{component_name}.ex"]
      |> Enum.reject(&(&1 == ""))

    Path.join(path_parts)
  end

  @doc """
  Resolve the module name for a component.

  ## Examples

      iex> resolve_module_name("button", "MyAppWeb", subdir: "ui")
      "MyAppWeb.Components.Button"
      
      iex> resolve_module_name("button", "MyAppWeb", flat: true)
      "MyAppWeb.Components.Button"
  """
  def resolve_module_name(component_name, web_module, _opts \\ []) do
    # Module names are always clean, regardless of file organization
    "#{web_module}.Components.#{String.capitalize(component_name)}"
  end

  @doc """
  Parse component arguments from command line.

  Returns a list of component names. If --all is specified, returns all available components.
  """
  def parse_component_args(args) do
    if "--all" in args do
      list_available_components()
    else
      args
      |> Enum.reject(&String.starts_with?(&1, "--"))
      |> Enum.map(&String.downcase/1)
      |> Enum.filter(&(&1 in list_available_components()))
    end
  end

  @doc """
  Parse installation options from command line arguments.
  """
  def parse_install_options(args) do
    %{
      flat: "--flat" in args,
      keep_core_components: "--keep-core-components" in args,
      module: parse_module_override(args),
      replace_core_components: "--replace-core-components" in args,
      subdir: parse_subdir(args)
    }
  end

  defp parse_subdir(args) do
    case Enum.find_index(args, &(&1 == "--subdir")) do
      nil ->
        nil

      index ->
        case Enum.at(args, index + 1) do
          nil -> nil
          subdir when is_binary(subdir) -> subdir
          _ -> nil
        end
    end
  end

  defp parse_module_override(args) do
    case Enum.find_index(args, &(&1 == "--module")) do
      nil ->
        nil

      index ->
        case Enum.at(args, index + 1) do
          nil -> nil
          module when is_binary(module) -> module
          _ -> nil
        end
    end
  end

  @doc """
  Get the current Pulsar version.
  """
  def pulsar_version do
    :pulsar
    |> Application.spec()
    |> Keyword.get(:vsn)
    |> to_string()
  end

  @doc """
  Generate a timestamp for template metadata.
  """
  def current_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
  end

  @doc """
  Format a success message for installation.
  """
  def format_success_message(installed_components, opts) do
    component_count = length(installed_components)

    message = [
      "\n✨ Pulsar installed successfully!\n",
      "\n📦 Installed components:",
      "   ✓ #{component_count} components in lib/#{opts.app_name}_web/components/#{opts.subdir || "ui"}/",
      "   ✓ Theme CSS in assets/css/pulsar.css",
      "   ✓ TailwindMerge dependency added",
      "\n📝 Next steps:",
      "   • Start using components: <.button variant=\"primary\">Click me</.button>",
      "   • Customize theme colors in assets/css/pulsar.css",
      "   • Edit components in lib/#{opts.app_name}_web/components/#{opts.subdir || "ui"}/",
      "   • Read the docs: https://hexdocs.pm/pulsar",
      "\n💡 Tip: Run mix pulsar.update to update components later"
    ]

    Enum.join(message, "\n")
  end
end
