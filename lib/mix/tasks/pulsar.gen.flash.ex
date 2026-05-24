defmodule Mix.Tasks.Pulsar.Gen.Flash do
  use Pulsar.Generator,
    component: :flash,
    example: "mix pulsar.gen.flash",
    long_doc: """
    Generates a toast-style notification component for flash messages and alerts

    Creates a flash notification component with dismissible controls, auto-dismiss
    functionality, and smooth animations. Perfect for user feedback, status updates,
    and temporary notifications that integrate with Phoenix.Flash.

    ## Example

    ```sh
    mix pulsar.gen.flash

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
