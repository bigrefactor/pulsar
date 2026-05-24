defmodule Mix.Tasks.Pulsar.Gen.RadioGroup do
  use Pulsar.Generator,
    component: :radio_group,
    example: "mix pulsar.gen.radio_group",
    long_doc: """
    Generates an accessible radio button group component with card-style layouts

    Creates a radio button group with proper radiogroup semantics, keyboard support,
    roving tabindex, card-style layouts, and seamless Phoenix form integration.
    Perfect for single-choice selections with rich content.

    ## Example

    ```sh
    mix pulsar.gen.radio_group

    # With custom module namespace
    mix pulsar.gen.radio_group --components-module=MyAppWeb.UI
    ```

    ## Features

    - Sizes: xs, sm, md, lg, xl
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Custom radio design with smooth animations
    - Card-style layouts for rich selections
    - Flexible layouts (use `class` for flex, grid, etc.)
    - Proper radiogroup semantics with keyboard support
    - Roving tabindex for optimal navigation
    - Phoenix form integration with automatic error styling
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic radio group
    <.radio_group field={@form[:plan]}>
      <:option value="basic">Basic Plan</:option>
      <:option value="pro">Pro Plan</:option>
      <:option value="enterprise">Enterprise Plan</:option>
    </.radio_group>

    # Horizontal layout
    <.radio_group field={@form[:size]} color="primary" size="lg" class="flex flex-row gap-6">
      <:option value="sm">Small</:option>
      <:option value="md">Medium</:option>
      <:option value="lg">Large</:option>
    </.radio_group>

    # Card-style with descriptions
    <.radio_group field={@form[:plan]} card variant="outline" color="primary">
      <:option value="basic">
        <div class="font-medium">Basic Plan</div>
        <div class="text-sm text-muted-foreground mt-1">Perfect for individuals</div>
        <div class="text-sm font-semibold mt-2">$9/month</div>
      </:option>
    </.radio_group>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
