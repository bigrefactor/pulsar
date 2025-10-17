defmodule Mix.Tasks.Pulsar.Gen.Field.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a composable field component that wraps inputs with labels and error handling"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.field"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a unified field component that automatically handles labels, descriptions,
    error messages, and input rendering based on type. Provides a consistent,
    accessible interface for all form inputs with standardized spacing and layout.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.field --components-module=MyAppWeb.UI
    ```

    ## Features

    - Type-based rendering (automatically uses the right Pulsar component)
    - Automatic label generation from field names
    - Error integration with Phoenix forms
    - Decorator support passed through to compatible inputs
    - Consistent layout and spacing
    - Accessibility with proper label association
    - Phoenix form and changeset integration

    ## Dependencies

    This component requires: checkbox, icon, input, label, radio_group, select, switch, textarea

    ## Usage Examples

    ```elixir
    # Basic text field with auto-generated label
    <.field field={@form[:email]} type="email" />

    # Field with custom label and description
    <.field field={@form[:username]} type="text" placeholder="Choose a username">
      <:label>Username</:label>
      <:description>This will be your public display name</:description>
    </.field>

    # Field with decorators
    <.field field={@form[:price]} type="number" step="0.01">
      <:label>Price</:label>
      <:start_decorator>$</:start_decorator>
      <:end_decorator>USD</:end_decorator>
    </.field>

    # Select field
    <.field field={@form[:country]} type="select" options={@countries}>
      <:label>Country</:label>
    </.field>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Field do
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
      |> Pulsar.Generator.install_component(:field, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Field do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.field' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
