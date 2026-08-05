defmodule Mix.Tasks.Pulsar.Gen.Label do
  use Pulsar.Generator,
    component: :label,
    example: "mix pulsar.gen.label",
    long_doc: """
    Generates a form label component with typography variants and visual indicators

    Creates an accessible form label component with required indicators, error state
    styling, and multiple typography sizes. Perfect for labeling form inputs with
    proper accessibility and visual feedback.

    ## Example

    ```sh
    mix pulsar.gen.label

    # With custom module namespace
    mix pulsar.gen.label --components-module=MyAppWeb.UI
    ```

    ## Features

    - Typography sizes: xs, sm, md, lg, xl (matching input components)
    - Required field indicator drawn as a decorative asterisk
    - Error state styling for validation feedback
    - Proper label-input association via `for` attribute
    - Data attributes for additional CSS targeting
    - Automatic dark mode support

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

    ```

    ## Accessibility Features

    - Proper association with inputs via `for` attribute
    - Required indicator paired with the control's `required` attribute
    - ARIA-compatible error state styling
    - Semantic HTML with proper label elements

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
