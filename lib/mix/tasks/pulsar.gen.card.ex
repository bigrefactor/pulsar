defmodule Mix.Tasks.Pulsar.Gen.Card do
  use Pulsar.Generator,
    component: :card,
    example: "mix pulsar.gen.card",
    long_doc: """
    Generates a flexible card component for grouping related content

    Creates a composition-based card component with optional media, header, content,
    and footer slots. Perfect for displaying grouped information, product cards,
    user profiles, and any structured content layout.

    ## Example

    ```sh
    mix pulsar.gen.card

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
