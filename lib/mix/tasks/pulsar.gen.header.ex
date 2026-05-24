defmodule Mix.Tasks.Pulsar.Gen.Header do
  use Pulsar.Generator,
    component: :header,
    example: "mix pulsar.gen.header",
    long_doc: """
    Generates a page header component with title, subtitle, actions, and breadcrumbs

    Creates a comprehensive page header component with semantic variants, responsive
    layout, configurable heading levels, breadcrumb navigation, and action buttons.
    Perfect for page titles and structured content headers.

    ## Example

    ```sh
    mix pulsar.gen.header

    # With custom module namespace
    mix pulsar.gen.header --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (typography scaling)
    - Semantic heading levels (h1-h6) for proper document structure
    - Breadcrumb navigation with auto chevrons and ARIA support
    - Responsive layout (actions stack on mobile, inline on desktop)
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Dependencies

    This component requires: link, icon

    ## Usage Examples

    ```elixir
    # Simple header
    <.header>Dashboard</.header>

    # Header with subtitle
    <.header>
      User Management
      <:subtitle>Manage users, roles, and permissions</:subtitle>
    </.header>

    # Header with actions
    <.header>
      Products
      <:subtitle>{length(@products)} total products</:subtitle>
      <:actions>
        <.button variant="outline">Export</.button>
        <.button variant="solid" color="primary">Add Product</.button>
      </:actions>
    </.header>

    # Header with breadcrumbs
    <.header>
      <:breadcrumb navigate={~p"/"}>Home</:breadcrumb>
      <:breadcrumb navigate={~p"/products"}>Products</:breadcrumb>
      <:breadcrumb>Edit Product</:breadcrumb>
      Edit Product
    </.header>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
