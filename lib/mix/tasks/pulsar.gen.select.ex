defmodule Mix.Tasks.Pulsar.Gen.Select do
  use Pulsar.Generator,
    component: :select,
    example: "mix pulsar.gen.select",
    long_doc: """
    Generates a select dropdown component with multi-select badge display

    Creates a beautiful select dropdown with optional multi-select mode displaying
    selected options as removable badges. Includes automatic error styling and
    seamless Phoenix form integration.

    ## Example

    ```sh
    mix pulsar.gen.select

    # With custom module namespace
    mix pulsar.gen.select --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline, ghost, solid
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Multi-select with badge display (requires Badge component)
    - Custom styled dropdown arrow
    - Option groups with consistent styling
    - Phoenix form integration with automatic error styling
    - Accessibility with proper select semantics
    - Automatic dark mode support

    ## Dependencies

    This component requires: badge (for multi-select mode), icon (for dropdown arrow)

    ## Usage Examples

    ```elixir
    # Basic select
    <.select field={@form[:country]} options={@countries} />

    # With variant and color
    <.select field={@form[:priority]} options={@priorities} variant="outline" color="primary" />

    # Multi-select with badges
    <.select field={@form[:skills]} options={@skills} multiple />

    # Custom badge removal handler
    <.select
      field={@form[:tags]}
      options={@tags}
      multiple
      on_badge_remove={JS.push("remove_tag")}
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
