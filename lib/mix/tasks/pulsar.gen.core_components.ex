defmodule Mix.Tasks.Pulsar.Gen.CoreComponents.Docs do
  @moduledoc false

  @doc false
  @spec short_doc() :: String.t()
  def short_doc do
    "Generates core Phoenix components with Pulsar styling (replaces default core_components)"
  end

  @doc false
  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.core_components"
  end

  @doc false
  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a CoreComponents module that provides essential UI components with Pulsar's
    enhanced styling and behavior. This module follows Phoenix convention as
    YourAppWeb.CoreComponents (not nested under Components namespace) and replaces
    the default core_components.ex file.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace (rare - follows Phoenix convention)
    mix pulsar.gen.core_components --components-module=MyAppWeb
    ```

    ## Features

    - Replaces default Phoenix core_components.ex with Pulsar-enhanced versions
    - Follows Phoenix naming convention (CoreComponents, not Components.CoreComponents)
    - Provides flash notifications, headers, lists, tables, and icons
    - Uses Pulsar's theme system and styling patterns
    - Maintains Phoenix API compatibility for easy migration
    - Integrates seamlessly with Phoenix.HTML and Phoenix.LiveView

    ## Included Components

    - flash/1: Flash notification rendering with Pulsar styling
    - header/1: Page headers with breadcrumbs and actions
    - list/1: Key-value data display lists
    - table/1: Data tables with LiveStream support
    - simple_form/1: Form wrapper with enhanced styling

    ## Usage Examples

    ```elixir
    # In your layout or LiveView
    <.flash kind={:info} flash={@flash} />

    # Page header
    <.header>
      Dashboard
      <:subtitle>Welcome back!</:subtitle>
    </.header>

    # Data list
    <.list>
      <:item title="Name">John Doe</:item>
      <:item title="Email">john@example.com</:item>
    </.list>

    # Data table
    <.table id="users" rows={@users}>
      <:col :let={user} label="Name"><%= user.name %></:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
    </.table>
    ```

    ## Dependencies

    This component requires: button, field, flash, header, icon, list, table

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb)
      Note: Unlike other generators, this defaults to YourAppWeb (not YourAppWeb.Components)
      to follow Phoenix convention for core_components.ex
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.CoreComponents do
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
      # core_components follows Phoenix convention: MyAppWeb.CoreComponents
      # (not nested under Components namespace, but file goes in components/ directory)
      igniter = Igniter.compose_task(igniter, "igniter.add_extension", ["phoenix"])
      web_module = Phoenix.web_module(igniter)

      igniter
      |> update_in([Access.key(:args), Access.key(:options)], fn opts ->
        opts = opts || []
        Keyword.put_new(opts, :components_module, web_module)
      end)
      |> Pulsar.Generator.install_component(:core_components, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.CoreComponents do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.core_components' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
