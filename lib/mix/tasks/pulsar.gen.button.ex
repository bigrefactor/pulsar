defmodule Mix.Tasks.Pulsar.Gen.Button.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a beautiful, accessible button component with polymorphic rendering"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.button"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a fully-featured button component supporting multiple variants, colors,
    sizes, loading states, and smart navigation. Renders as button, link, or div
    elements with proper accessibility and XSS protection.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.button --components-module=MyAppWeb.UI
    ```

    ## Features

    - Polymorphic rendering (button, a, or div elements)
    - Variants: solid, outline, ghost, link
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Loading states with spinner
    - Phoenix navigation support (navigate, patch, href)
    - XSS protection for href attributes
    - WCAG 2.1 AA accessibility compliance
    - Keyboard navigation for pseudo-buttons

    ## Usage Examples

    ```elixir
    # Basic button
    <.button variant="solid" color="primary">Save Changes</.button>

    # With loading state
    <.button variant="solid" color="success" loading={@saving}>
      Submit Form
    </.button>

    # Navigation button
    <.button variant="outline" navigate={~p"/dashboard"}>
      Go to Dashboard
    </.button>

    # Link variant
    <.button variant="link" color="primary" href="https://example.com">
      Learn More
    </.button>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Button do
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
      |> Pulsar.Generator.install_component(:button, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Button do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.button' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
