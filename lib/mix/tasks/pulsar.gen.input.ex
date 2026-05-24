defmodule Mix.Tasks.Pulsar.Gen.Input do
  use Pulsar.Generator,
    component: :input,
    example: "mix pulsar.gen.input",
    long_doc: """
    Generates a text input component with decorator support and validation

    Creates a beautiful text input component with start and end decorators for icons,
    text, or interactive elements. Includes automatic error styling when used with
    Phoenix forms and seamless validation integration.

    ## Example

    ```sh
    mix pulsar.gen.input

    # With custom module namespace
    mix pulsar.gen.input --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline, ghost, solid
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Start/end decorator slots for icons, text, or buttons
    - Phoenix form integration with automatic error styling
    - Accessibility built-in with proper ARIA attributes
    - Automatic dark mode support
    - Security with proper input validation

    ## Usage Examples

    ```elixir
    # Basic input
    <.input field={@form[:email]} type="email" />

    # With decorators and color
    <.input field={@form[:amount]} variant="outline" color="success">
      <:start_decorator>$</:start_decorator>
      <:end_decorator>USD</:end_decorator>
    </.input>

    # URL input with protocol decorator
    <.input field={@form[:website]} type="url" color="primary">
      <:start_decorator>https://</:start_decorator>
    </.input>

    # Search input with solid variant
    <.input field={@form[:search]} variant="solid" color="secondary">
      <:start_decorator>
        <.icon name="hero-magnifying-glass" />
      </:start_decorator>
      <:end_decorator>
        <.button variant="ghost" size="sm">Search</.button>
      </:end_decorator>
    </.input>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
