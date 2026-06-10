defmodule Mix.Tasks.Pulsar.Gen.Drawer do
  use Pulsar.Generator,
    component: :drawer,
    example: "mix pulsar.gen.drawer",
    long_doc: """
    Generates a side-anchored, focus-trapped drawer (sheet) overlay.

    Built on the modal primitive: it traps focus, dims the page, locks scroll, and
    closes on Escape or a backdrop click, but anchors the panel to a viewport edge
    (right, left, top, or bottom) and slides it in. Drive it from anywhere with the
    `open/2` and `close/2` helpers. Requires the modal and button components.

    ## Example

    ```sh
    mix pulsar.gen.drawer

    # With custom module namespace
    mix pulsar.gen.drawer --components-module=MyAppWeb.UI
    ```

    ## Features

    - Anchors to any side: right, left, top, bottom — each with a directional slide-in
    - Native `<dialog>` focus trap, Escape handling, dimmed backdrop, and scroll lock
    - `size` controls the variable axis: width for left/right, height for top/bottom
    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Structured title, description, body, and footer regions
    - Focus returns to the opener on close

    ## Usage Examples

    ```elixir
    <.button phx-click={Drawer.open("filters")}>Filters</.button>

    <.drawer id="filters" side="right" title="Filters">
      <:description>Narrow the results.</:description>
      ...
      <:footer>
        <.button phx-click={Drawer.close("filters")}>Close</.button>
      </:footer>
    </.drawer>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
