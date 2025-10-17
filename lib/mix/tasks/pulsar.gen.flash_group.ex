defmodule Mix.Tasks.Pulsar.Gen.FlashGroup.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a container component for managing multiple flash notifications"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.flash_group"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates an intelligent flash group component that reads from Phoenix.Flash and
    displays multiple notifications with automatic positioning, stacking, type-to-color
    mapping, and item limiting. Single integration point for all flash messages.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.flash_group --components-module=MyAppWeb.UI
    ```

    ## Features

    - Phoenix.Flash integration (reads from @flash assigns)
    - 6 position options (top/bottom × left/center/right)
    - Automatic stacking with coordinated animations
    - Type-to-color mapping (error→danger, warning→warning, etc.)
    - Configurable maximum number of visible flashes
    - Consistent styling across all flashes
    - Staggered entry/exit animations

    ## Dependencies

    This component requires: flash, icon

    ## Usage Examples

    ```elixir
    # Basic usage in layout or LiveView
    <.flash_group flash={@flash} />

    # Custom positioning and styling
    <.flash_group
      flash={@flash}
      variant="outline"
      position="bottom-right"
      max_items={3}
    />

    # Different positions
    <.flash_group flash={@flash} position="top-center" />
    <.flash_group flash={@flash} position="bottom-left" />
    ```

    ## Flash Type Mapping

    - `:error` → danger color
    - `:warning` → warning color
    - `:info` → info color
    - `:success` → success color
    - Custom types → neutral color

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.FlashGroup do
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
      |> Pulsar.Generator.install_component(:flash_group, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.FlashGroup do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.flash_group' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
