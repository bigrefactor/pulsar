defmodule Mix.Tasks.Pulsar.Gen.List.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a list component for displaying key-value data pairs with semantic HTML"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.list"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a semantic list component using proper dl/dt/dd markup for displaying
    structured data, metadata, and key-value information with consistent styling
    and accessibility.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.list --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Semantic HTML (dl, dt, dd elements)
    - Visual options: striped rows, dividers, custom spacing
    - Flexible layout (default 2-column, customizable)
    - Empty state with customizable content
    - Optional header with title and description
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic list
    <.list>
      <:item title="Name">John Doe</:item>
      <:item title="Email">john@example.com</:item>
      <:item title="Role">Administrator</:item>
    </.list>

    # With variant and color
    <.list variant="outline" color="primary">
      <:item title="Project">Phoenix App</:item>
      <:item title="Version">1.7.0</:item>
      <:item title="Status">
        <.badge color="success">Active</.badge>
      </:item>
    </.list>

    # With header
    <.list variant="solid" color="neutral">
      <:header title="User Details" description="Account information" />
      <:item title="Username">johndoe</:item>
      <:item title="Member since">January 2024</:item>
    </.list>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.List do

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
      |> Pulsar.Generator.install_component(:list, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.List do

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.list' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
