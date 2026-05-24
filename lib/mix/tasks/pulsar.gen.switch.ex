defmodule Mix.Tasks.Pulsar.Gen.Switch do
  use Pulsar.Generator,
    component: :switch,
    example: "mix pulsar.gen.switch",
    long_doc: """
    Generates an iOS-style toggle switch component for Phoenix forms

    Creates a beautiful toggle switch with iOS-inspired design, smooth animations,
    loading states, and seamless Phoenix form integration using native checkbox input.

    ## Example

    ```sh
    mix pulsar.gen.switch

    # With custom module namespace
    mix pulsar.gen.switch --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Native checkbox input for proper form submission
    - iOS-inspired design with rounded track and sliding thumb
    - Smooth animations for all state changes
    - Loading state with spinner animation
    - Keyboard accessible (Space key toggles, Tab navigation)
    - Phoenix form integration with automatic error styling
    - Screen reader support with proper ARIA attributes
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic switch
    <.switch field={@form[:notifications_enabled]} />

    # With variant, color, and size
    <.switch
      field={@form[:dark_mode]}
      variant="outline"
      color="primary"
      size="lg"
    />

    # Loading state during async operation
    <.switch
      field={@form[:public_profile]}
      loading={@updating_privacy}
      color="success"
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
