defmodule Mix.Tasks.Pulsar.Gen.Storybook.Docs do
  @moduledoc false

  @doc false
  @spec short_doc() :: String.t()
  def short_doc do
    "Generates PhoenixStorybook story files for installed Pulsar components"
  end

  @doc false
  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.storybook"
  end

  @doc false
  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Generates PhoenixStorybook `.story.exs` files for all installed Pulsar components,
    plus foundation pages (colors, typography, spacing, dark mode), example pages
    (login, dashboard, settings), and a welcome page.

    This task is useful for adding storybook support AFTER components have already been
    installed with `mix pulsar.install`.

    ## Example

    ```sh
    # Catch-up: detect installed components, emit stories + foundations + examples + welcome
    #{example()}

    # Only emit foundations + examples + welcome (skip component stories)
    mix pulsar.gen.storybook --skip-components

    # With custom components module namespace
    mix pulsar.gen.storybook --components-module=MyAppWeb.UI
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    * `--skip-components` - Skip per-component stories (emit only foundations + examples + welcome)
    * `--yes` or `-y` - Auto-confirm prompts

    ## Notes

    - `phoenix_storybook` is NOT added to your deps automatically. Follow the printed
      setup instructions to wire it up in your application.
    - Story files are written to `lib/<app>_web/storybook/` and subdirectories.
    - The `sandbox_class` in the generated stories defaults to `pulsar-sandbox`. This
      must match the `sandbox_class` option in your PhoenixStorybook backend module.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Storybook do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Mix.Task.Info
    alias Pulsar.Generator.Storybook

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        group: :pulsar,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [],
        composes: [],
        schema: [
          components_module: :string,
          skip_components: :boolean,
          yes: :boolean
        ],
        defaults: [
          skip_components: false
        ],
        aliases: [
          M: :components_module,
          y: :yes
        ],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = igniter.args.options

      igniter
      |> Pulsar.Generator.set_default_component_module()
      |> maybe_install_component_stories(options[:skip_components])
      |> Storybook.install_foundations()
      |> Storybook.install_examples()
      |> Storybook.install_welcome()
      |> Storybook.print_setup_notice()
    end

    defp maybe_install_component_stories(igniter, true), do: igniter

    defp maybe_install_component_stories(igniter, _) do
      Storybook.install_detected_component_stories(igniter)
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Storybook do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.storybook' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
