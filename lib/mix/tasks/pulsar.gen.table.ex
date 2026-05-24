defmodule Mix.Tasks.Pulsar.Gen.Table do
  use Pulsar.Generator,
    component: :table,
    example: "mix pulsar.gen.table",
    long_doc: """
    Generates a table component for displaying tabular data with Phoenix LiveView integration

    Creates a beautiful data table with LiveStream support for real-time updates,
    interactive rows, action columns, and all the features needed for displaying
    and managing tabular data in Phoenix LiveView applications.

    ## Example

    ```sh
    mix pulsar.gen.table

    # With custom module namespace
    mix pulsar.gen.table --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid, outline, ghost
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl (controls data density)
    - LiveStream support for real-time updates
    - Interactive row click handlers
    - Dedicated action column for row operations
    - Striped rows and sticky headers
    - Empty state with customizable content
    - Loading state with skeleton UI
    - Semantic table markup with proper accessibility
    - Automatic dark mode support

    ## Usage Examples

    ```elixir
    # Basic table
    <.table id="users" rows={@users}>
      <:col :let={user} label="Name"><%= user.name %></:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
      <:col :let={user} label="Status">
        <.badge color={status_color(user.status)}>
          <%= user.status %>
        </.badge>
      </:col>
    </.table>

    # With variant, size, and actions
    <.table
      id="products"
      rows={@products}
      variant="outline"
      color="primary"
      size="sm"
      row_click={&JS.navigate(~p"/products/\#{&1.id}")}
    >
      <:col :let={product} label="Name"><%= product.name %></:col>
      <:col :let={product} label="Price">$<%= product.price %></:col>
      <:action :let={product}>
        <.button variant="ghost" size="sm" phx-click="delete" phx-value-id={product.id}>
          Delete
        </.button>
      </:action>
    </.table>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
