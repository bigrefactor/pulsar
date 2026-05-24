defmodule Mix.Tasks.Pulsar.Gen.List do
  use Pulsar.Generator,
    component: :list,
    example: "mix pulsar.gen.list",
    long_doc: """
    Generates a list component for displaying key-value data pairs with semantic HTML

    Creates a semantic list component using proper dl/dt/dd markup for displaying
    structured data, metadata, and key-value information with consistent styling
    and accessibility.

    ## Example

    ```sh
    mix pulsar.gen.list

    # With custom module namespace
    mix pulsar.gen.list --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Semantic HTML (dl, dt, dd elements)
    - Visual options: striped rows, dividers, custom spacing
    - Flexible layout (default 2-column, customizable)
    - Empty state with customizable content
    - Optional header with title and description
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic list
    <.list>
      <:item title="Name">John Doe</:item>
      <:item title="Email">john@example.com</:item>
      <:item title="Role">Administrator</:item>
    </.list>

    # With variant and color
    <.list variant="outline" color="primary">
      <:item title="Project">Phoenix App</:item>
      <:item title="Version">1.7.0</:item>
      <:item title="Status">
        <.badge color="success">Active</.badge>
      </:item>
    </.list>

    # With header
    <.list variant="solid" color="neutral">
      <:header title="User Details" description="Account information" />
      <:item title="Username">johndoe</:item>
      <:item title="Member since">January 2024</:item>
    </.list>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
