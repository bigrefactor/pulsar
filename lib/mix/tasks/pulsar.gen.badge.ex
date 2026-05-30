defmodule Mix.Tasks.Pulsar.Gen.Badge do
  use Pulsar.Generator,
    component: :badge,
    example: "mix pulsar.gen.badge",
    long_doc: """
    Generates a badge component for displaying labels, tags, and status indicators

    Creates a flexible badge component with start and end addon slots for icons,
    buttons, or other content. Perfect for tags, status indicators, multi-select
    displays, and any labeled content that needs visual decoration.

    ## Example

    ```sh
    mix pulsar.gen.badge

    # With custom module namespace
    mix pulsar.gen.badge --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Start/end addon slots for icons and buttons
    - Automatic dark mode support
    - Accessibility built-in

    ## Usage Examples

    ```elixir
    # Simple badge
    <.badge>New</.badge>

    # Colored badge with variant
    <.badge color="primary" variant="outline">Featured</.badge>

    # Badge with status icon
    <.badge color="success">
      <:start_addon>
        <.icon name="hero-check-circle-micro" size="xs" />
      </:start_addon>
      Completed
    </.badge>

    # Badge with remove button
    <.badge color="danger">
      Error
      <:end_addon>
        <button phx-click="remove_error">
          <.icon name="hero-x-mark-micro" size="xs" />
        </button>
      </:end_addon>
    </.badge>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
