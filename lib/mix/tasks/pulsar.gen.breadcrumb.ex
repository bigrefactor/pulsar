defmodule Mix.Tasks.Pulsar.Gen.Breadcrumb do
  use Pulsar.Generator,
    component: :breadcrumb,
    example: "mix pulsar.gen.breadcrumb",
    long_doc: """
    Generates a breadcrumb component — wayfinding for the path to the current page.

    Creates an accessible, slot-based Breadcrumb that renders a `<nav>` landmark
    wrapping an ordered list of links, with the final crumb marked as the current
    page. Separators are decorative and customizable, and a long trail can be
    collapsed behind a static ellipsis via `max_items`.

    ## Example

    ```sh
    mix pulsar.gen.breadcrumb

    # With custom module namespace
    mix pulsar.gen.breadcrumb --components-module=MyAppWeb.UI
    ```

    ## Features

    - Slot-based items with per-item navigate, patch, or href
    - Last item rendered as the current page (aria-current)
    - Default chevron separator with an optional custom separator slot
    - Count-based overflow: collapse the middle behind a static ellipsis
    - Colors: muted, primary, secondary, success, danger, warning, info; sizes: xs … xl
    - WCAG 2.2 AA accessibility compliance

    ## Dependencies

    This component requires: link, icon

    ## Usage Examples

    ```elixir
    <.breadcrumb>
      <:item navigate={~p"/"}>Home</:item>
      <:item navigate={~p"/products"}>Products</:item>
      <:item>Edit Product</:item>
    </.breadcrumb>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
