defmodule Mix.Tasks.Pulsar.Gen.Checkbox.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an accessible checkbox component with card variants and indeterminate state"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.checkbox"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a full-featured checkbox component with animated checkmark, tri-state
    support (checked/unchecked/indeterminate), card-style layouts, and seamless
    Phoenix form integration.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.checkbox --components-module=MyAppWeb.UI
    ```

    ## Features

    - Sizes: xs, sm, md, lg, xl
    - Colors: neutral, primary, secondary, success, danger, warning
    - Indeterminate state support for "select all" scenarios
    - Card-style layouts for rich checkbox experiences
    - Hidden checkbox option for card-only selection
    - Animated checkmark transitions
    - Phoenix form integration with automatic error styling
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic checkbox
    <.checkbox field={@form[:terms_accepted]} />

    # With color and size
    <.checkbox field={@form[:newsletter]} color="primary" size="lg" />

    # Indeterminate state
    <.checkbox
      field={@form[:select_all]}
      indeterminate={@partial_selection}
      color="success"
    />

    # Card-style checkbox
    <.checkbox
      field={@form[:plan]}
      card
      variant="outline"
      color="primary"
      size="lg"
      value="premium"
    >
      <div class="font-medium">Premium Plan</div>
      <div class="text-sm text-muted-foreground mt-1">
        Advanced features and priority support
      </div>
      <div class="text-sm font-semibold mt-2">$29/month</div>
    </.checkbox>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Checkbox do
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
      |> Pulsar.Generator.install_component(:checkbox, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Checkbox do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.checkbox' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
