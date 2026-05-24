defmodule Mix.Tasks.Pulsar.Gen.Textarea do
  use Pulsar.Generator,
    component: :textarea,
    example: "mix pulsar.gen.textarea",
    long_doc: """
    Generates a multi-line textarea component with auto-resize and character counting

    Creates a beautiful textarea with automatic height adjustment as content grows
    and visual character count display. Perfect for comments, descriptions, and any
    multi-line text input needs.

    ## Example

    ```sh
    mix pulsar.gen.textarea

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
