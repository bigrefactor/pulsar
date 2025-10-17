defmodule Mix.Tasks.Pulsar.Gen.Label.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a form label component with typography variants and visual indicators"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.label"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates an accessible form label component with required indicators, error state
    styling, and multiple typography sizes. Perfect for labeling form inputs with
    proper accessibility and visual feedback.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.label --components-module=MyAppWeb.UI
    ```

    ## Features

    - Typography sizes: xs, sm, md, lg, xl (matching input components)
    - Required field indicators with screen reader support
    - Error state styling for validation feedback
    - Proper label-input association via `for` attribute
    - Data attributes for additional CSS targeting
    - Automatic dark mode support
    - Internationalization support for required text

    ## Usage Examples

    ```elixir
    # Basic label
    <.label for="email">Email Address</.label>

    # Required field with size
    <.label for="password" required size="lg">Password</.label>

    # Error state
    <.label for="invalid-field" error>Invalid Field</.label>

    # Large size with custom styling
    <.label for="title" size="xl" class="mb-4">
      Document Title
    </.label>

    # With internationalized required text
    <.label for="email" required sr_required_text={gettext("(required)")}>
      Email Address
    </.label>
    ```

    ## Accessibility Features

    - Proper association with inputs via `for` attribute
    - Screen reader text for required indicators
    - ARIA-compatible error state styling
    - Semantic HTML with proper label elements

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Label do
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
      |> Pulsar.Generator.install_component(:label, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Label do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.label' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
