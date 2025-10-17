defmodule Mix.Tasks.Pulsar.Gen.Icon.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an icon component supporting all Heroicons variants with flexible sizing"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.icon"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a comprehensive icon component with access to all Heroicons (outline, solid,
    mini, micro), Pulsar's semantic color system, responsive sizing, and proper
    accessibility attributes.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.icon --components-module=MyAppWeb.UI
    ```

    ## Features

    - Heroicons variants: outline (24×24), solid (24×24), mini (20×20), micro (16×16)
    - Semantic colors: neutral, primary, secondary, success, danger, warning, info, current
    - Sizes: xs (12px), sm (16px), md (20px), lg (24px), xl (32px)
    - Decorative by default with aria-hidden
    - Optional aria_label for informative icons
    - Automatic dark mode support
    - Current color inheritance from parent

    ## Usage Examples

    ```elixir
    # Basic outline icon (decorative)
    <.icon name="hero-check" />

    # Solid variant with color
    <.icon name="hero-heart" variant="solid" color="danger" />

    # Micro icon scaled up
    <.icon name="hero-x-mark" variant="micro" size="lg" />

    # Current color (inherits from parent)
    <.icon name="hero-information-circle" color="current" />

    # Informative icon with accessible label
    <.icon name="hero-exclamation-triangle" color="warning" aria_label="Warning" />
    ```

    ## Heroicons Variants

    - outline: 24×24 stroke-based icons (default)
    - solid: 24×24 filled icons
    - mini: 20×20 filled icons for compact interfaces
    - micro: 16×16 filled icons for very tight spaces

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Icon do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

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
        schema: [
          components_module: :string
        ],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [
          M: :components_module
        ],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Pulsar.Generator.set_default_component_module()
      |> Pulsar.Generator.install_component(:icon, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Icon do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.icon' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
