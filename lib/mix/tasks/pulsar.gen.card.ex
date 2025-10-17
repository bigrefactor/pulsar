defmodule Mix.Tasks.Pulsar.Gen.Card.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates a flexible card component for grouping related content"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.card"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Creates a composition-based card component with optional media, header, content,
    and footer slots. Perfect for displaying grouped information, product cards,
    user profiles, and any structured content layout.

    ## Example

    ```sh
    #{example()}

    # With custom module namespace
    mix pulsar.gen.card --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Optional media, header, content, and footer slots
    - Composition-first design (use only the slots you need)
    - Automatic dark mode support
    - Semantic markup and accessibility

    ## Usage Examples

    ```elixir
    # Minimal card
    <.card>
      <p>Simple card content</p>
    </.card>

    # Card with variant and color
    <.card variant="outline" color="primary">
      <p>Outlined primary card</p>
    </.card>

    # Full-featured card
    <.card variant="outline" color="primary" size="lg">
      <:media>
        <img src="/hero.jpg" class="w-full h-48 object-cover" />
      </:media>

      <:header>
        <h3 class="text-lg font-semibold">Card Title</h3>
      </:header>

      <p>Main content with automatic spacing between sections.</p>

      <:footer>
        <.button variant="solid" color="primary">Learn More</.button>
      </:footer>
    </.card>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Card do

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
      |> Pulsar.Generator.install_component(:card, [])
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Card do

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.card' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
