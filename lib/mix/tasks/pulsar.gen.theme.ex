defmodule Mix.Tasks.Pulsar.Gen.Theme.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates Pulsar theme CSS files with semantic color tokens and design system"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.theme"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    This task sets up Pulsar's comprehensive theme system by generating:

    * `assets/css/theme.css` - Complete theme with semantic color tokens, design tokens (radius, spacing, typography), custom animations, and light/dark mode support
    * `assets/css/app.css` - Phoenix LiveView configuration that imports the theme
    * `assets/css/app.css.bak` - Backup of existing app.css (if it exists)

    The theme system provides:

    * **Semantic Colors**: Primary, secondary, success, warning, danger, info, and neutral colors
    * **Light/Dark Mode**: Complete token sets for both modes using data-theme attribute strategy
    * **Design Tokens**: Border radius, spacing, typography, shadows, and z-index layers
    * **Custom Animations**: Fade-in, slide-in, scale-in, and subtle pulse animations
    * **Accessibility**: Respects prefers-reduced-motion preferences

    ## Example

    ```sh
    #{example()}
    ```

    This will generate the theme files in your Phoenix project's assets/css directory.

    ## Theme Customization

    After generation, you can customize the theme by editing `assets/css/theme.css`:

    * Change color mappings (e.g., map --color-primary to indigo instead of blue)
    * Adjust design tokens (border radius, spacing, typography)
    * Add custom animations
    * Modify light/dark mode color values
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Theme do
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Libs.Phoenix
    alias Igniter.Mix.Task.Info

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :pulsar,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      theme_css_template =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("theme.css.eex")

      app_css_template =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("app.css.eex")

      web_dir = Phoenix.web_module(igniter) |> Macro.underscore()

      igniter
      |> Igniter.copy_template(theme_css_template, "assets/css/theme.css", web_directory: web_dir)
      |> then(fn ig ->
        # Only backup existing app.css if it exists
        if Igniter.exists?(ig, "assets/css/app.css") do
          Igniter.move_file(ig, "assets/css/app.css", "assets/css/app.css.bak")
        else
          ig
        end
      end)
      |> Igniter.copy_template(app_css_template, "assets/css/app.css", web_directory: web_dir)
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Theme do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.theme' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
