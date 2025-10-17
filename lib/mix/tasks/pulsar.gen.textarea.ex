defmodule Mix.Tasks.Pulsar.Gen.Textarea.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a multi-line textarea component with auto-resize and character counting"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.textarea"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a beautiful textarea with automatic height adjustment as content grows
    and visual character count display. Perfect for comments, descriptions, and any
    multi-line text input needs.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.textarea --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline, ghost, solid
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (with appropriate min/max heights)
    - Auto-resize option (grows with content)
    - Character counting with theme-colored display
    - Phoenix form integration with automatic error styling
    - Accessibility with proper textarea semantics
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic textarea
    <.textarea field={@form[:description]} />

    # With auto-resize and character counting
    <.textarea
      field={@form[:comment]}
      auto_resize
      show_character_count
      max_length={500}
      placeholder="Share your thoughts..."
    />

    # Large textarea with custom styling
    <.textarea
      field={@form[:bio]}
      variant="outline"
      color="primary"
      size="lg"
      auto_resize
      show_character_count
      max_length={1000}
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Textarea do
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
      |> Pulsar.Generator.install_component(:textarea, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Textarea do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.textarea' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
