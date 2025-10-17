defmodule Mix.Tasks.Pulsar.Gen.RadioGroup.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an accessible radio button group component with card-style layouts"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.radio_group"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a radio button group with proper radiogroup semantics, keyboard support,
    roving tabindex, card-style layouts, and seamless Phoenix form integration.
    Perfect for single-choice selections with rich content.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.radio_group --components-module=MyAppWeb.UI
    ```

    ## Features

    - Sizes: xs, sm, md, lg, xl
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Custom radio design with smooth animations
    - Card-style layouts for rich selections
    - Flexible layouts (use `class` for flex, grid, etc.)
    - Proper radiogroup semantics with keyboard support
    - Roving tabindex for optimal navigation
    - Phoenix form integration with automatic error styling
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic radio group
    <.radio_group field={@form[:plan]}>
      <:option value="basic">Basic Plan</:option>
      <:option value="pro">Pro Plan</:option>
      <:option value="enterprise">Enterprise Plan</:option>
    </.radio_group>

    # Horizontal layout
    <.radio_group field={@form[:size]} color="primary" size="lg" class="flex flex-row gap-6">
      <:option value="sm">Small</:option>
      <:option value="md">Medium</:option>
      <:option value="lg">Large</:option>
    </.radio_group>

    # Card-style with descriptions
    <.radio_group field={@form[:plan]} card variant="outline" color="primary">
      <:option value="basic">
        <div class="font-medium">Basic Plan</div>
        <div class="text-sm text-muted-foreground mt-1">Perfect for individuals</div>
        <div class="text-sm font-semibold mt-2">$9/month</div>
      </:option>
    </.radio_group>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.RadioGroup do
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
      |> Pulsar.Generator.install_component(:radio_group, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.RadioGroup do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.radio_group' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
