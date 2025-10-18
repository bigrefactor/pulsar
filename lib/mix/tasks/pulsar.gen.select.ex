defmodule Mix.Tasks.Pulsar.Gen.Select.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a select dropdown component with multi-select badge display"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.select"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a beautiful select dropdown with optional multi-select mode displaying
    selected options as removable badges. Includes automatic error styling and
    seamless Phoenix form integration.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.select --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline, ghost, solid
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Multi-select with badge display (requires Badge component)
    - Custom styled dropdown arrow
    - Option groups with consistent styling
    - Phoenix form integration with automatic error styling
    - Accessibility with proper select semantics
    - Automatic dark mode support

    ## Dependencies

    This component requires: badge (for multi-select mode), icon (for dropdown arrow)

    ## Usage Examples

    ```elixir
    # Basic select
    <.select field={@form[:country]} options={@countries} />

    # With variant and color
    <.select field={@form[:priority]} options={@priorities} variant="outline" color="primary" />

    # Multi-select with badges
    <.select field={@form[:skills]} options={@skills} multiple />

    # Custom badge removal handler
    <.select
      field={@form[:tags]}
      options={@tags}
      multiple
      on_badge_remove={JS.push("remove_tag")}
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Select do
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
      |> Pulsar.Generator.install_component(:select, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Select do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.select' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
