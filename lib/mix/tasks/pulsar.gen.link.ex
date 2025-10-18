defmodule Mix.Tasks.Pulsar.Gen.Link.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an accessible link component with semantic variants, security, and Phoenix navigation"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.link"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a link component with XSS protection, automatic external link security,
    Phoenix navigation support, and semantic color schemes. Perfect for inline links,
    navigation, and external resources.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.link --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid (no underline), ghost (hover underline), outline (always underlined)
    - Colors: primary, secondary, danger, neutral, and all semantic colors
    - XSS protection (blocks javascript:, data: protocols)
    - Automatic external link security (rel="noopener noreferrer" for target="_blank")
    - Phoenix navigation support (navigate, patch, href)
    - Start/end icon slots
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Dependencies

    This component requires: icon

    ## Usage Examples

    ```elixir
    # Basic link
    <.link href="/profile">View Profile</.link>

    # External link (auto-secure)
    <.link href="https://example.com">External Link</.link>

    # Phoenix navigation
    <.link navigate={~p"/dashboard"} variant="ghost" color="danger">
      Dashboard
    </.link>

    # Link with icon
    <.link href="/settings">
      <:start_icon>
        <.icon name="hero-cog" />
      </:start_icon>
      Settings
    </.link>
    ```

    ## Security Features

    - XSS protection blocks dangerous protocols (javascript:, data:, etc.)
    - Auto-adds rel="noopener noreferrer" for external links with target="_blank"
    - Proper handling of external vs internal navigation
    - Safe Phoenix LiveView navigation

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Link do
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
      |> Pulsar.Generator.install_component(:link, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Link do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.link' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
