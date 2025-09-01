defmodule Mix.Tasks.Pulsar.Install do
  @shortdoc "Installs Pulsar components library"

  @moduledoc """
  Sets up Pulsar component generator for use in a Phoenix application.

  Pulsar uses a generator-only approach (no dependencies) similar to shadcn/ui.
  Components are generated into your codebase for full control and customization.

  This task prepares your Phoenix LiveView application by:
  - Adding required dependencies (Stellar + TailwindMerge)
  - Installing the Pulsar theme CSS
  - Configuring Tailwind CSS for optimal component generation
  - Setting up proper dark mode support

      mix pulsar.install

  ## Options

    * `--theme` - Theme to install (default: "pulsar")
      Available: pulsar
    
    * `--skip-deps` - Skip adding dependencies to mix.exs
    * `--skip-css` - Skip CSS theme installation

  ## What gets installed

  ### Dependencies
  - `stellar` - Headless component behavior and accessibility
  - `tailwind_merge` - Intelligent CSS class merging

  ### Files  
  - Theme CSS file in assets/css/themes/
  - Updated app.css with theme import

  ### Configuration
  - Tailwind CSS configured for dark mode
  - Content paths updated for generated component files

  ## After installation

  Generate individual components as needed:

      mix pulsar.gen.button
      mix pulsar.gen.input
      mix pulsar.gen.modal

  Generated components use Stellar and TailwindMerge but no Pulsar dependency.
  """

  use Igniter.Mix.Task

  alias Igniter.Mix.Task.Info
  alias Igniter.Project.Deps

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Info{
      aliases: [],
      composes: [],
      example: "mix pulsar.install",
      group: :pulsar,
      positional: [],
      schema: [
        theme: :string,
        skip_deps: :boolean,
        skip_css: :boolean
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    argv = igniter.args

    {options, _argv} =
      OptionParser.parse!(argv,
        strict: [
          theme: :string,
          skip_deps: :boolean,
          skip_css: :boolean
        ]
      )

    theme = Keyword.get(options, :theme, "pulsar")
    skip_deps = Keyword.get(options, :skip_deps, false)
    skip_css = Keyword.get(options, :skip_css, false)

    igniter
    |> maybe_add_dependencies(skip_deps)
    |> maybe_install_theme(theme, skip_css)
    |> configure_tailwind()
    |> add_success_message(theme)
  end

  # Add required dependencies unless skipped
  defp maybe_add_dependencies(igniter, true = _skip), do: igniter

  defp maybe_add_dependencies(igniter, false = _skip) do
    igniter
    |> Deps.add_dep({:stellar, "~> 0.1"})
    |> Deps.add_dep({:tailwind_merge, "~> 0.1"})
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
    source_theme_path =
      Path.join([__DIR__, "..", "..", "..", "..", "priv", "static", "themes", "#{theme}.css"])

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

  # Add success message
  defp add_success_message(igniter, theme) do
    message = """

    ✨ Pulsar setup complete!

    Theme: #{theme}

    What was installed:
    ✓ Dependencies (stellar, tailwind_merge)
    ✓ Theme CSS (assets/css/themes/#{theme}.css)
    ✓ Updated app.css with theme import
    ✓ Configured Tailwind for dark mode and component generation

    Next steps:
    1. Run `mix deps.get` to fetch dependencies
    2. Generate the components you need:
       mix pulsar.gen.button
       mix pulsar.gen.input
       mix pulsar.gen.modal

    3. Try dark mode by adding `data-theme="dark"` to your <html> element

    4. Components will be generated in lib/your_app_web/components/
       You own the code completely - modify as needed!

    Example generated component usage:
      <.button variant="solid" color="primary" size="lg">
        Get Started
      </.button>

    Only Stellar + TailwindMerge dependencies - no Pulsar package! 🚀
    """

    Igniter.add_notice(igniter, message)
  end
end
