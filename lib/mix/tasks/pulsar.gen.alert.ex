defmodule Mix.Tasks.Pulsar.Gen.Alert do
  use Pulsar.Generator,
    component: :alert,
    example: "mix pulsar.gen.alert",
    long_doc: """
    Generates an inline alert banner component for form-level and page-level messages.

    Creates a self-contained alert component for non-toast, in-content status
    messages in success, info, warning, and danger styles. For transient toast
    notifications, generate `flash` instead.

    ## Example

    ```sh
    mix pulsar.gen.alert

    # With custom module namespace
    mix pulsar.gen.alert --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost (tinted)
    - Semantic colors, each with an auto-selected status icon
    - Optional title, description, and right-aligned actions
    - Optional dismiss button with a smooth client-side exit
    - Opt-in `role` for dynamically shown alerts

    ## Usage Examples

    ```elixir
    # Simplest
    <.alert description="Your changes have been saved." />

    # Title + description + color
    <.alert color="warning" title="Heads up" description="Your trial ends in 3 days." />

    # Dismissible error with an action
    <.alert color="danger" role="alert" dismissible title="Payment failed"
            description="Update your card to continue." on_dismiss={JS.push("dismiss_alert")}>
      <:actions>
        <.button size="sm">Update card</.button>
      </:actions>
    </.alert>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
