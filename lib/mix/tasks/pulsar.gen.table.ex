defmodule Mix.Tasks.Pulsar.Gen.Table.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a table component for displaying tabular data with Phoenix LiveView integration"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.table"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a beautiful data table with LiveStream support for real-time updates,
    interactive rows, action columns, and all the features needed for displaying
    and managing tabular data in Phoenix LiveView applications.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.table --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (controls data density)
    - LiveStream support for real-time updates
    - Interactive row click handlers
    - Dedicated action column for row operations
    - Striped rows and sticky headers
    - Empty state with customizable content
    - Loading state with skeleton UI
    - Semantic table markup with proper accessibility
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic table
    <.table id="users" rows={@users}>
      <:col :let={user} label="Name"><%= user.name %></:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
      <:col :let={user} label="Status">
        <.badge color={status_color(user.status)}>
          <%= user.status %>
        </.badge>
      </:col>
    </.table>

    # With variant, size, and actions
    <.table
      id="products"
      rows={@products}
      variant="outline"
      color="primary"
      size="sm"
      row_click={&JS.navigate(~p"/products/#{&1.id}")}
    >
      <:col :let={product} label="Name"><%= product.name %></:col>
      <:col :let={product} label="Price">$<%= product.price %></:col>
      <:action :let={product}>
        <.button variant="ghost" size="sm" phx-click="delete" phx-value-id={product.id}>
          Delete
        </.button>
      </:action>
    </.table>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Table do
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
      |> Pulsar.Generator.install_component(:table, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Table do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.table' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
