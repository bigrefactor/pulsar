defmodule Mix.Tasks.Pulsar.Gen.Badge do
  use Pulsar.Generator,
    component: :badge,
    example: "mix pulsar.gen.badge",
    long_doc: """
    Generates a badge component for displaying labels, tags, and removable tokens

    Creates a flexible badge component with start and end addon slots for icons,
    buttons, or other content, plus an optional built-in remove control. Perfect
    for tags, status indicators, filter chips, multi-select tokens, and any
    labeled content that needs visual decoration.

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
    - Built-in labeled remove control via `on_remove`
    - `as={:div}` for tokens whose label opens a popover
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

    # Removable token
    <.badge on_remove={JS.push("remove_tag", value: %{id: 7})} remove_label="Remove tag Draft">
      Draft
    </.badge>

    # Two-action token: the label opens a popover, the × removes it
    <.badge as={:div} on_remove={JS.push("remove_filter")} remove_label="Remove filter Status">
      <.popover id="filter-status-panel">
        <:trigger><button type="button">Status: Published</button></:trigger>
        <.filter_editor />
      </.popover>
    </.badge>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
