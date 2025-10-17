defmodule Mix.Tasks.Pulsar.Gen.Divider.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a divider component for visually separating content sections"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.divider"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a flexible divider component with optional labels, multiple line styles,
    and support for both horizontal and vertical orientations. Perfect for section
    separators, OR dividers, and visual content organization.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.divider --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Line styles: solid, dashed, dotted
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (controls thickness and spacing)
    - Orientations: horizontal, vertical
    - Optional label content
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Simple horizontal divider
    <.divider />

    # Colored divider with variant
    <.divider variant="solid" color="primary" />

    # Labeled divider (common for "OR" separators)
    <.divider>OR</.divider>

    # Dashed section divider
    <.divider line_style="dashed" color="neutral">
      Section 2
    </.divider>

    # Vertical divider (requires height constraint)
    <.divider orientation="vertical" class="h-8" />

    # Large divider with label
    <.divider size="lg" color="primary">
      Featured Content
    </.divider>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Divider do

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
      |> Pulsar.Generator.install_component(:divider, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Divider do

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.divider' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
