defmodule Mix.Tasks.Pulsar.Gen.Input.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a text input component with decorator support and validation"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.input"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a beautiful text input component with start and end decorators for icons,
    text, or interactive elements. Includes automatic error styling when used with
    Phoenix forms and seamless validation integration.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.input --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline, ghost, solid
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Start/end decorator slots for icons, text, or buttons
    - Phoenix form integration with automatic error styling
    - Accessibility built-in with proper ARIA attributes
    - Automatic dark mode support
    - Security with proper input validation

    ## Usage Examples

    ```elixir
    # Basic input
    <.input field={@form[:email]} type="email" />

    # With decorators and color
    <.input field={@form[:amount]} variant="outline" color="success">
      <:start_decorator>$</:start_decorator>
      <:end_decorator>USD</:end_decorator>
    </.input>

    # URL input with protocol decorator
    <.input field={@form[:website]} type="url" color="primary">
      <:start_decorator>https://</:start_decorator>
    </.input>

    # Search input with solid variant
    <.input field={@form[:search]} variant="solid" color="secondary">
      <:start_decorator>
        <.icon name="hero-magnifying-glass" />
      </:start_decorator>
      <:end_decorator>
        <.button variant="ghost" size="sm">Search</.button>
      </:end_decorator>
    </.input>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Input do
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
      |> Pulsar.Generator.install_component(:input, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Input do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.input' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
