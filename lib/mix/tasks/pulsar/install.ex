defmodule Mix.Tasks.Pulsar.Install do
  @moduledoc """
  Install Pulsar components into your Phoenix application.

  ## Examples

      # Install all components
      mix pulsar.install --all

      # Install specific components
      mix pulsar.install button input checkbox

      # Install to flat structure (no ui/ subdirectory)
      mix pulsar.install --all --flat

      # Install to custom subdirectory
      mix pulsar.install --all --subdir design_system

      # Replace existing core_components.ex
      mix pulsar.install --all --replace-core-components

      # Keep existing core_components.ex
      mix pulsar.install --all --keep-core-components

  ## Options

  - `--all` - Install all available components
  - `--flat` - Install directly in /components (no subdirectory)
  - `--subdir <name>` - Custom subdirectory name (default: "ui")
  - `--replace-core-components` - Replace existing core_components.ex
  - `--keep-core-components` - Keep existing core_components.ex
  - `--module <name>` - Override web module detection

  All standard Igniter flags are also supported:
  - `--yes` - Accept all prompts automatically
  - `--dry-run` - Show what would be done without making changes
  - `--verbose` - Show detailed output
  """

  use Igniter.Mix.Task

  alias Igniter.Libs.Phoenix
  alias Igniter.Mix.Task.Info
  alias Igniter.Project.Deps
  alias Pulsar.Igniter.Helpers

  @impl Igniter.Mix.Task
  def info(_argv, _source) do
    %Info{
      group: :pulsar,
      # Only run if we can detect a Phoenix app
      only_if: &Phoenix.installed?/1,
      # Compose with individual component generators
      composes: [
        {"pulsar.gen.badge", "Generate Badge component"},
        {"pulsar.gen.button", "Generate Button component"},
        {"pulsar.gen.card", "Generate Card component"},
        {"pulsar.gen.checkbox", "Generate Checkbox component"},
        {"pulsar.gen.divider", "Generate Divider component"},
        {"pulsar.gen.field", "Generate Field component"},
        {"pulsar.gen.flash", "Generate Flash component"},
        {"pulsar.gen.flash_group", "Generate FlashGroup component"},
        {"pulsar.gen.header", "Generate Header component"},
        {"pulsar.gen.icon", "Generate Icon component"},
        {"pulsar.gen.input", "Generate Input component"},
        {"pulsar.gen.label", "Generate Label component"},
        {"pulsar.gen.link", "Generate Link component"},
        {"pulsar.gen.list", "Generate List component"},
        {"pulsar.gen.radio_group", "Generate RadioGroup component"},
        {"pulsar.gen.select", "Generate Select component"},
        {"pulsar.gen.switch", "Generate Switch component"},
        {"pulsar.gen.table", "Generate Table component"},
        {"pulsar.gen.textarea", "Generate Textarea component"}
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Parse arguments and options
    {argv, _parsed} =
      OptionParser.parse!(igniter.args,
        switches: [
          all: :boolean,
          flat: :boolean,
          subdir: :string,
          replace_core_components: :boolean,
          keep_core_components: :boolean,
          module: :string
        ]
      )

    # Get components to install
    components = Helpers.parse_component_args(argv)

    if Enum.empty?(components) do
      Mix.shell().error(
        "No components specified. Use --all to install all components or specify individual components."
      )

      Mix.shell().info("Available components: #{Enum.join(Helpers.list_available_components(), ", ")}")
      exit(1)
    end

    # Parse installation options
    options = Helpers.parse_install_options(argv)

    # Detect project structure
    web_module = options.module || Helpers.detect_web_module(igniter)
    app_name = Helpers.detect_app_name(igniter)

    if !web_module do
      Mix.shell().error("Could not detect web module. Use --module to specify it manually.")
      exit(1)
    end

    if !app_name do
      Mix.shell().error("Could not detect application name.")
      exit(1)
    end

    # Build installation context
    install_context = %{
      app_name: app_name,
      components: components,
      options: options,
      web_module: web_module
    }

    # Execute installation steps
    igniter
    |> add_tailwind_merge_dependency()
    |> install_components(install_context)
    |> install_theme(install_context)
    |> handle_core_components(install_context)
    |> display_success_message(install_context)
  end

  # Add TailwindMerge dependency
  defp add_tailwind_merge_dependency(igniter) do
    Deps.add_dependency(igniter, {:tailwind_merge, "~> 0.2"})
  end

  # Install all specified components
  defp install_components(igniter, context) do
    Enum.reduce(context.components, igniter, fn component, acc ->
      install_component(acc, component, context)
    end)
  end

  # Install a single component
  defp install_component(igniter, component_name, context) do
    module_name = Helpers.resolve_module_name(component_name, context.web_module, context.options)
    component_path = Helpers.resolve_component_path(igniter, component_name, context.web_module, context.options)

    # Read template and render with variables
    template_content = render_component_template(component_name, context)

    # Create the component file
    Igniter.Project.Module.create_module(igniter, module_name, template_content)
  end

  # Render component template with variables
  defp render_component_template(component_name, context) do
    template_path = Path.join([:code.priv_dir(:pulsar), "templates", "#{component_name}.ex.eex"])

    if File.exists?(template_path) do
      template_content = File.read!(template_path)

      # Template variables
      assigns = %{
        app_name: context.app_name,
        component_name: String.capitalize(component_name),
        generated_at: Helpers.current_timestamp(),
        module_name: Helpers.resolve_module_name(component_name, context.web_module, context.options),
        pulsar_version: Helpers.pulsar_version(),
        web_module: context.web_module
      }

      EEx.eval_string(template_content, assigns: assigns)
    else
      # Fallback: read from current component and convert
      convert_component_to_template(component_name, context)
    end
  end

  # Fallback: convert existing component to template
  defp convert_component_to_template(component_name, context) do
    source_path = Path.join([:code.lib_dir(:pulsar), "pulsar", "components", "#{component_name}.ex"])

    if File.exists?(source_path) do
      content = File.read!(source_path)

      # Replace module name and add version tracking
      module_name = Helpers.resolve_module_name(component_name, context.web_module, context.options)

      content
      |> String.replace(
        "defmodule Pulsar.Components.#{String.capitalize(component_name)}",
        "defmodule #{module_name}"
      )
      |> add_version_tracking(component_name, context)
    else
      raise "Component template not found: #{component_name}"
    end
  end

  # Add version tracking comments
  defp add_version_tracking(content, component_name, context) do
    version_comment = """
    # Generated by Pulsar v#{Helpers.pulsar_version()} on #{Helpers.current_timestamp()}
    # Component: #{String.capitalize(component_name)}
    # DO NOT EDIT THESE COMMENTS - Used for version tracking
    """

    version_comment <> "\n" <> content
  end

  # Install theme CSS
  defp install_theme(igniter, context) do
    # Copy theme CSS
    source_theme = Path.join([:code.lib_dir(:pulsar), "..", "themes", "pulsar.css"])
    dest_theme = "assets/css/pulsar.css"

    if File.exists?(source_theme) do
      theme_content = File.read!(source_theme)
      Igniter.Project.File.create_new_file(igniter, dest_theme, theme_content)
    else
      igniter
    end
    |> update_app_css()
  end

  # Update app.css with imports
  defp update_app_css(igniter) do
    case Igniter.Project.File.read(igniter, "assets/css/app.css") do
      {:ok, content} ->
        updated_content = ensure_pulsar_imports(content)
        Igniter.Project.File.write(igniter, "assets/css/app.css", updated_content)

      {:error, _} ->
        igniter
    end
  end

  # Ensure Pulsar imports are present in app.css
  defp ensure_pulsar_imports(content) do
    content
    |> ensure_import("./pulsar.css")
    |> ensure_dark_variant()
  end

  defp ensure_import(content, import_path) do
    import_line = "@import \"#{import_path}\";"

    if String.contains?(content, import_line) do
      content
    else
      # Add after @import "tailwindcss" or at the beginning
      case String.split(content, "\n") do
        [first | rest] when String.contains?(first, "@import \"tailwindcss\"") ->
          first <> "\n" <> import_line <> "\n" <> Enum.join(rest, "\n")

        lines ->
          import_line <> "\n" <> Enum.join(lines, "\n")
      end
    end
  end

  defp ensure_dark_variant(content) do
    dark_variant = ~s{@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));}

    if String.contains?(content, "@custom-variant dark") do
      content
    else
      content <> "\n\n" <> dark_variant
    end
  end

  # Handle core_components.ex (only if explicitly requested)
  defp handle_core_components(igniter, context) do
    # Only handle core_components if explicitly requested
    if context.options.replace_core_components || context.options.keep_core_components do
      core_module = "#{context.web_module}.CoreComponents"

      case Igniter.Project.Module.find_module(igniter, core_module) do
        {:ok, _} ->
          handle_existing_core_components(igniter, context, core_module)

        {:error, _} ->
          # No existing core_components, nothing to do
          igniter
      end
    else
      igniter
    end
  end

  defp handle_existing_core_components(igniter, context, core_module) do
    if context.options.replace_core_components do
      replace_core_components(igniter, context, core_module)
    else
      # keep_core_components - do nothing
      igniter
    end
  end

  defp replace_core_components(igniter, context, core_module) do
    # Backup original
    backup_path = "lib/#{context.app_name}_web/core_components.ex.backup"

    Igniter.Project.File.read(igniter, "lib/#{context.app_name}_web/core_components.ex")
    |> case do
      {:ok, content} ->
        Igniter.Project.File.create_new_file(igniter, backup_path, content)

      {:error, _} ->
        igniter
    end

    # Generate delegating module
    generate_delegating_core_components(igniter, context, core_module)
  end

  defp generate_delegating_core_components(igniter, context, core_module) do
    delegates =
      context.components
      |> Enum.map_join("\n", fn component ->
        module_name = Helpers.resolve_module_name(component, context.web_module, context.options)
        "  defdelegate #{component}(assigns), to: #{module_name}"
      end)

    imports =
      context.components
      |> Enum.map_join("\n", fn component ->
        module_name = Helpers.resolve_module_name(component, context.web_module, context.options)
        "  import #{module_name}"
      end)

    module_content = """
    defmodule #{core_module} do
      @moduledoc \"\"\"
      Core UI components powered by Pulsar.
      
      Original core_components.ex backed up to core_components.ex.backup
      To customize, edit files in lib/#{context.app_name}_web/components/#{context.options.subdir || "ui"}/
      \"\"\"
      
    #{imports}

    # Delegate for backwards compatibility
    #{delegates}
    end
    """

    Igniter.Project.Module.create_module(igniter, core_module, module_content)
  end

  # Display success message
  defp display_success_message(igniter, context) do
    message = format_success_message(context)
    Igniter.Util.IO.puts(message)
    igniter
  end

  defp format_success_message(context) do
    component_count = length(context.components)
    subdir = context.options.subdir || "ui"

    message = [
      "\n✨ Pulsar installed successfully!\n",
      "\n📦 Components installed to:",
      "   lib/#{context.app_name}_web/components/#{subdir}/",
      "\n📝 To use components, import them in your LiveViews:",
      "",
      "   import #{context.web_module}.Components.Button",
      "   import #{context.web_module}.Components.Input",
      "",
      "   <.button variant=\"primary\">Click me</.button>",
      "",
      "💡 Or add to lib/#{context.app_name}_web.ex for app-wide access:",
      "",
      "   def html_helpers do",
      "     quote do",
      "       # Your existing imports...",
      "       import #{context.web_module}.Components.Button",
      "       import #{context.web_module}.Components.Input",
      "     end",
      "   end",
      "",
      "🎨 Theme CSS installed to assets/css/pulsar.css",
      "📦 TailwindMerge dependency added",
      "",
      "💡 Tip: Run mix pulsar.update to update components later"
    ]

    Enum.join(message, "\n")
  end
end
