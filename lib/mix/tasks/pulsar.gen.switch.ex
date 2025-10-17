defmodule Mix.Tasks.Pulsar.Gen.Switch.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an iOS-style toggle switch component for Phoenix forms"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.switch"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a beautiful toggle switch with iOS-inspired design, smooth animations,
    loading states, and seamless Phoenix form integration using native checkbox input.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.switch --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Native checkbox input for proper form submission
    - iOS-inspired design with rounded track and sliding thumb
    - Smooth animations for all state changes
    - Loading state with spinner animation
    - Keyboard accessible (Space key toggles, Tab navigation)
    - Phoenix form integration with automatic error styling
    - Screen reader support with proper ARIA attributes
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic switch
    <.switch field={@form[:notifications_enabled]} />

    # With variant, color, and size
    <.switch
      field={@form[:dark_mode]}
      variant="outline"
      color="primary"
      size="lg"
    />

    # Loading state during async operation
    <.switch
      field={@form[:public_profile]}
      loading={@updating_privacy}
      color="success"
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Switch do
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
      |> Pulsar.Generator.install_component(:switch, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Switch do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.switch' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
