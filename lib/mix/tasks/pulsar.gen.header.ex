defmodule Mix.Tasks.Pulsar.Gen.Header.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a page header component with title, subtitle, actions, and breadcrumbs"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.header"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a comprehensive page header component with semantic variants, responsive
    layout, configurable heading levels, breadcrumb navigation, and action buttons.
    Perfect for page titles and structured content headers.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.header --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (typography scaling)
    - Semantic heading levels (h1-h6) for proper document structure
    - Breadcrumb navigation with auto chevrons and ARIA support
    - Responsive layout (actions stack on mobile, inline on desktop)
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Dependencies

    This component requires: link, icon

    ## Usage Examples

    ```elixir
    # Simple header
    <.header>Dashboard</.header>

    # Header with subtitle
    <.header>
      User Management
      <:subtitle>Manage users, roles, and permissions</:subtitle>
    </.header>

    # Header with actions
    <.header>
      Products
      <:subtitle>{length(@products)} total products</:subtitle>
      <:actions>
        <.button variant="outline">Export</.button>
        <.button variant="solid" color="primary">Add Product</.button>
      </:actions>
    </.header>

    # Header with breadcrumbs
    <.header>
      <:breadcrumb navigate={~p"/"}>Home</:breadcrumb>
      <:breadcrumb navigate={~p"/products"}>Products</:breadcrumb>
      <:breadcrumb>Edit Product</:breadcrumb>
      Edit Product
    </.header>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Header do
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
      |> Pulsar.Generator.install_component(:header, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Header do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.header' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
