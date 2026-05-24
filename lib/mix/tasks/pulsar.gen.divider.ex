defmodule Mix.Tasks.Pulsar.Gen.Divider do
  use Pulsar.Generator,
    component: :divider,
    example: "mix pulsar.gen.divider",
    long_doc: """
    Generates a divider component for visually separating content sections

    Creates a flexible divider component with optional labels, multiple line styles,
    and support for both horizontal and vertical orientations. Perfect for section
    separators, OR dividers, and visual content organization.

    ## Example

    ```sh
    mix pulsar.gen.divider

    # With custom module namespace
    mix pulsar.gen.divider --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Line styles: solid, dashed, dotted
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (controls thickness and spacing)
    - Orientations: horizontal, vertical
    - Optional label content
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Simple horizontal divider
    <.divider />

    # Colored divider with variant
    <.divider variant="solid" color="primary" />

    # Labeled divider (common for "OR" separators)
    <.divider>OR</.divider>

    # Dashed section divider
    <.divider line_style="dashed" color="neutral">
      Section 2
    </.divider>

    # Vertical divider (requires height constraint)
    <.divider orientation="vertical" class="h-8" />

    # Large divider with label
    <.divider size="lg" color="primary">
      Featured Content
    </.divider>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
