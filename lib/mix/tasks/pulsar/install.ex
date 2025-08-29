defmodule Mix.Tasks.Pulsar.Install do
  @shortdoc "Installs Pulsar components library"
  
  @moduledoc """
  Installs Pulsar components library in a Phoenix application.

  This task sets up Pulsar for use in your Phoenix LiveView application by:
  - Adding required dependencies
  - Installing the Pulsar theme CSS
  - Configuring Tailwind CSS
  - Creating example component usage

      mix pulsar.install

  ## Options

    * `--theme` - Theme to install (default: "pulsar")
      Available: pulsar
      
    * `--skip-deps` - Skip adding dependencies to mix.exs
    
    * `--skip-css` - Skip CSS theme installation

  ## What gets installed

  ### Dependencies
  - `stellar` - Headless component library
  - `tailwind_merge` - Intelligent CSS class merging
  
  ### Files  
  - Theme CSS file in assets/css/themes/
  - Updated app.css with theme import
  - Example component usage
  
  ### Configuration
  - Tailwind CSS configured for dark mode
  - Content paths updated for component files
  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :pulsar,
      example: "mix pulsar.install",
      positional: [],
      composes: [],
      schema: [
        theme: :string,
        skip_deps: :boolean,
        skip_css: :boolean
      ],
      aliases: []
    }
  end

  @impl Igniter.Mix.Task  
  def igniter(igniter) do
    argv = igniter.args
    {options, _argv} = OptionParser.parse!(argv, strict: [
      theme: :string,
      skip_deps: :boolean, 
      skip_css: :boolean
    ])
    
    theme = Keyword.get(options, :theme, "pulsar")
    skip_deps = Keyword.get(options, :skip_deps, false)
    skip_css = Keyword.get(options, :skip_css, false)
    
    igniter
    |> maybe_add_dependencies(skip_deps)
    |> maybe_install_theme(theme, skip_css)
    |> configure_tailwind()
    |> create_example_usage()
    |> add_success_message(theme)
  end

  # Add required dependencies unless skipped
  defp maybe_add_dependencies(igniter, true = _skip), do: igniter
  defp maybe_add_dependencies(igniter, false = _skip) do
    igniter
    |> Igniter.Project.Deps.add_dep({:pulsar, "~> 0.1"})
    |> Igniter.Project.Deps.add_dep({:stellar, "~> 0.1"})
    |> Igniter.Project.Deps.add_dep({:tailwind_merge, "~> 0.1"})
  end

  # Install theme CSS unless skipped
  defp maybe_install_theme(igniter, _theme, true = _skip), do: igniter
  defp maybe_install_theme(igniter, theme, false = _skip) do
    igniter
    |> install_theme_css(theme)
    |> update_app_css(theme)
  end

  # Install the theme CSS file
  defp install_theme_css(igniter, theme) do
    # Source theme file from Pulsar
    source_theme_path = Path.join([__DIR__, "..", "..", "..", "..", "priv", "static", "themes", "#{theme}.css"])
    
    # Target path in user's app
    target_theme_path = Path.join(["assets", "css", "themes", "#{theme}.css"])
    
    case File.read(source_theme_path) do
      {:ok, theme_content} ->
        igniter
        |> Igniter.create_new_file(target_theme_path, theme_content)
        
      {:error, _reason} ->
        # Generate a minimal theme if source not found
        minimal_theme = generate_minimal_theme()
        igniter
        |> Igniter.create_new_file(target_theme_path, minimal_theme)
    end
  end

  # Generate minimal theme if source not available
  defp generate_minimal_theme do
    """
    /* Pulsar Theme - Minimal */
    
    @import "tailwindcss";
    
    @theme inline {
      /* Primary - Blue */
      --color-primary-500: var(--color-blue-500);
      --color-primary-600: var(--color-blue-600);
      
      /* Semantic surface colors */
      --color-background: var(--color-white);
      --color-foreground: var(--color-gray-950);
      --color-dark-background: var(--color-gray-950);
      --color-dark-foreground: var(--color-gray-50);
    }
    """
  end

  # Update app.css to import the theme
  defp update_app_css(igniter, theme) do
    app_css_path = Path.join(["assets", "css", "app.css"])
    theme_import = "@import \"./themes/#{theme}.css\";\n"
    
    case Igniter.exists?(igniter, app_css_path) do
      true ->
        igniter
        |> Igniter.update_file(app_css_path, fn content ->
          # Add theme import at the top, after any existing imports
          lines = String.split(content, "\n")
          
          # Find where to insert (after existing @import statements)
          {imports, rest} = Enum.split_while(lines, &String.starts_with?(&1, "@import"))
          
          # Reassemble with our import added
          (imports ++ [String.trim(theme_import)] ++ rest)
          |> Enum.join("\n")
        end)
        
      false ->
        # Create basic app.css if it doesn't exist
        basic_css = """
        #{theme_import}
        @tailwind base;
        @tailwind components;
        @tailwind utilities;
        """
        
        igniter
        |> Igniter.create_new_file(app_css_path, basic_css)
    end
  end

  # Configure Tailwind for dark mode and content paths
  defp configure_tailwind(igniter) do
    tailwind_config_path = "tailwind.config.js"
    
    case Igniter.exists?(igniter, tailwind_config_path) do
      true ->
        update_tailwind_config(igniter, tailwind_config_path)
        
      false ->
        create_tailwind_config(igniter, tailwind_config_path)
    end
  end

  # Update existing tailwind.config.js
  defp update_tailwind_config(igniter, config_path) do
    igniter
    |> Igniter.update_file(config_path, fn content ->
      content
      |> ensure_dark_mode()
      |> ensure_content_paths()
    end)
  end

  # Create new tailwind.config.js
  defp create_tailwind_config(igniter, config_path) do
    config_content = """
    module.exports = {
      content: [
        "./lib/**/*.{ex,heex}",
        "./assets/css/themes/*.css"
      ],
      darkMode: 'class',
      theme: {
        extend: {},
      },
      plugins: [],
    }
    """
    
    igniter
    |> Igniter.create_new_file(config_path, config_content)
  end

  # Ensure darkMode: 'class' is set
  defp ensure_dark_mode(content) do
    if String.contains?(content, "darkMode") do
      content
    else
      # Add darkMode after content or at beginning of config
      content
      |> String.replace(
        ~r/content:\s*\[([^\]]+)\],/,
        "content: [\\1],\n  darkMode: 'class',"
      )
    end
  end

  # Ensure content paths include component files and themes
  defp ensure_content_paths(content) do
    required_paths = [
      "./lib/**/*.{ex,heex}",
      "./assets/css/themes/*.css"
    ]
    
    # This is a simple check - in a real implementation you'd parse the JS
    Enum.reduce(required_paths, content, fn path, acc ->
      if String.contains?(acc, path) do
        acc
      else
        # Simple string replacement - would need more robust JS parsing
        String.replace(acc, ~r/content:\s*\[/, "content: [\n    \"#{path}\",")
      end
    end)
  end

  # Create example component usage
  defp create_example_usage(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    
    example_path = Path.join(["lib", "#{app_name}_web", "components", "pulsar_examples.ex"])
    
    example_content = """
    defmodule #{web_module}.Components.PulsarExamples do
      @moduledoc \"\"\"
      Example usage of Pulsar components.
      
      Generated by `mix pulsar.install` - you can delete this file.
      \"\"\"
      
      use Phoenix.Component
      use PulsarWeb, :components
      
      @doc \"\"\"
      Example button showcase.
      \"\"\"
      def button_examples(assigns) do
        ~H\"\"\"
        <div class="space-y-4">
          <h3 class="text-lg font-semibold">Button Examples</h3>
          
          <div class="flex flex-wrap gap-2">
            <.button variant="primary">Primary</.button>
            <.button variant="secondary">Secondary</.button>
            <.button variant="success">Success</.button>
            <.button variant="error">Error</.button>
            <.button variant="warning">Warning</.button>
          </div>
          
          <div class="flex flex-wrap gap-2">
            <.button variant="ghost">Ghost</.button>
            <.button variant="outline">Outline</.button>
            <.button variant="link">Link</.button>
          </div>
          
          <div class="flex flex-wrap gap-2">
            <.button variant="primary" size="sm">Small</.button>
            <.button variant="primary" size="md">Medium</.button>
            <.button variant="primary" size="lg">Large</.button>
          </div>
        </div>
        \"\"\"
      end
    end
    """
    
    igniter
    |> Igniter.create_new_file(example_path, example_content)
  end

  # Add success message
  defp add_success_message(igniter, theme) do
    message = """
    
    ✨ Pulsar installed successfully!
    
    Theme: #{theme}
    
    What was installed:
    ✓ Dependencies (stellar, tailwind_merge)
    ✓ Theme CSS (assets/css/themes/#{theme}.css)
    ✓ Updated app.css with theme import
    ✓ Configured Tailwind for dark mode
    ✓ Created example components
    
    Next steps:
    1. Run `mix deps.get` to fetch dependencies
    2. Import components: `use PulsarWeb, :components`  
    3. Or generate individual components: `mix pulsar.gen.button`
    4. Try dark mode by adding `class="dark"` to your <html> element
    
    Example usage:
      <.button variant="primary" size="lg">
        Get Started
      </.button>
    
    Happy building! 🚀
    """
    
    Igniter.add_notice(igniter, message)
  end
end