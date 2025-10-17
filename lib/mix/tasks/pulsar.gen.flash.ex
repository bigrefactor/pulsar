defmodule Mix.Tasks.Pulsar.Gen.Flash.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a toast-style notification component for flash messages and alerts"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.flash"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a flash notification component with dismissible controls, auto-dismiss
    functionality, and smooth animations. Perfect for user feedback, status updates,
    and temporary notifications that integrate with Phoenix.Flash.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.flash --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Auto-dismiss with configurable timeout
    - Pause-on-hover functionality
    - Manual dismiss with close button
    - Smooth entry/exit animations using Phoenix.LiveView.JS
    - Icon support for status indicators
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic flash notification
    <.flash color="success">Changes saved successfully!</.flash>

    # Flash with close button
    <.flash color="danger" dismissible>
      Unable to save changes
    </.flash>

    # Flash with icon and auto-dismiss
    <.flash color="info" auto_dismiss dismiss_after={3000}>
      <:start_icon>
        <.icon name="hero-information-circle" variant="mini" size="sm" />
      </:start_icon>
      New feature available
    </.flash>

    # Custom styled flash
    <.flash variant="outline" color="warning" dismissible>
      <:start_icon>
        <.icon name="hero-exclamation-triangle" variant="mini" size="sm" />
      </:start_icon>
      <strong>Warning:</strong> This action cannot be undone
    </.flash>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Flash do

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
      |> Pulsar.Generator.install_component(:flash, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Flash do

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.flash' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
