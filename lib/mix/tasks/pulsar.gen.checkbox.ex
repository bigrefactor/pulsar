defmodule Mix.Tasks.Pulsar.Gen.Checkbox do
  use Pulsar.Generator,
    component: :checkbox,
    example: "mix pulsar.gen.checkbox",
    long_doc: """
    Generates an accessible checkbox component with card variants and indeterminate state

    Creates a full-featured checkbox component with animated checkmark, tri-state
    support (checked/unchecked/indeterminate), card-style layouts, and seamless
    Phoenix form integration.

    ## Example

    ```sh
    mix pulsar.gen.checkbox

    # With custom module namespace
    mix pulsar.gen.checkbox --components-module=MyAppWeb.UI
    ```

    ## Features

    - Sizes: xs, sm, md, lg, xl
    - Colors: neutral, primary, secondary, success, danger, warning
    - Indeterminate state support for "select all" scenarios
    - Card-style layouts for rich checkbox experiences
    - Hidden checkbox option for card-only selection
    - Animated checkmark transitions
    - Phoenix form integration with automatic error styling
    - WCAG 2.2 AA accessibility compliance
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic checkbox
    <.checkbox field={@form[:terms_accepted]} />

    # With color and size
    <.checkbox field={@form[:newsletter]} color="primary" size="lg" />

    # Indeterminate state
    <.checkbox
      field={@form[:select_all]}
      indeterminate={@partial_selection}
      color="success"
    />

    # Card-style checkbox
    <.checkbox
      field={@form[:plan]}
      card
      variant="outline"
      color="primary"
      size="lg"
      value="premium"
    >
      <div class="font-medium">Premium Plan</div>
      <div class="text-sm text-muted-foreground mt-1">
        Advanced features and priority support
      </div>
      <div class="text-sm font-semibold mt-2">$29/month</div>
    </.checkbox>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
