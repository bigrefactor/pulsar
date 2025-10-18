defmodule Mix.Tasks.Pulsar.Gen.Badge.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a badge component for displaying labels, tags, and status indicators"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.badge"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a flexible badge component with start and end addon slots for icons,
    buttons, or other content. Perfect for tags, status indicators, multi-select
    displays, and any labeled content that needs visual decoration.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.badge --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Start/end addon slots for icons and buttons
    - Automatic dark mode support
    - Accessibility built-in

    ## Usage Examples

    ```elixir
    # Simple badge
    <.badge>New</.badge>

    # Colored badge with variant
    <.badge color="primary" variant="outline">Featured</.badge>

    # Badge with status icon
    <.badge color="success">
      <:start_addon>
        <.icon name="hero-check-circle" variant="micro" size="xs" />
      </:start_addon>
      Completed
    </.badge>

    # Badge with remove button
    <.badge color="danger">
      Error
      <:end_addon>
        <button phx-click="remove_error">
          <.icon name="hero-x-mark" variant="micro" size="xs" />
        </button>
      </:end_addon>
    </.badge>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Badge do
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
      |> Pulsar.Generator.install_component(:badge, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Badge do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.badge' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
