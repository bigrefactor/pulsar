defmodule Mix.Tasks.Pulsar.Gen.Pagination do
  use Pulsar.Generator,
    component: :pagination,
    example: "mix pulsar.gen.pagination",
    long_doc: """
    Generates a pagination component — page navigation for tables and lists.

    Creates an accessible, link-based Pagination component with two modes: a
    numbered `page` mode (windowed page numbers, previous/next, optional
    summary) and a `cursor` mode (previous/next only). Navigation is supplied by
    the caller via a `page_href` function or `prev_href`/`next_href`, so it maps
    directly onto a `Flop.Meta` with no Flop dependency.

    ## Example

    ```sh
    mix pulsar.gen.pagination

    # With custom module namespace
    mix pulsar.gen.pagination --components-module=MyAppWeb.UI
    ```

    ## Features

    - Page mode: windowed page numbers with configurable siblings/boundaries
    - Cursor mode: previous/next only for keyset pagination
    - Variants: ghost, solid, outline; colors: neutral … info; sizes: xs … xl
    - Link types: navigate, patch, or plain href
    - Localizable labels and CLDR-compatible number formatting

    ## Usage Examples

    ```elixir
    <.pagination
      page={@meta.current_page}
      total_pages={@meta.total_pages}
      page_href={fn p -> ~p"/users?page=\#{p}" end}
      show_summary
    />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
