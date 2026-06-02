defmodule Mix.Tasks.Pulsar.Gen.Popover do
  use Pulsar.Generator,
    component: :popover,
    example: "mix pulsar.gen.popover",
    long_doc: """
    Generates an anchored, dismissible, non-modal popover overlay.

    Built on the native HTML Popover API: clicking the trigger opens a panel
    anchored to it; clicking outside or pressing Escape closes it and returns
    focus to the trigger. Positioning (flip + shift) runs in a colocated hook.

    ## Example

    ```sh
    mix pulsar.gen.popover

    # With custom module namespace
    mix pulsar.gen.popover --components-module=MyAppWeb.UI
    ```

    ## Features

    - Anchored placement: top/bottom/left/right with start/center/end align
    - Flip + shift so the panel stays on screen
    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Outside-click + Escape dismissal (native); Escape returns focus to the trigger
    - Accessibility built-in (aria-controls / aria-expanded wiring)

    ## Usage Examples

    ```elixir
    <.popover id="filters" placement="bottom-start">
      <:trigger><.button>Filters</.button></:trigger>
      <div>...</div>
    </.popover>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
