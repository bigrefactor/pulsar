defmodule Mix.Tasks.Pulsar.Gen.Tooltip do
  use Pulsar.Generator,
    component: :tooltip,
    example: "mix pulsar.gen.tooltip",
    long_doc: """
    Generates a hover/focus tooltip that describes its trigger.

    Built on the popover primitive in hover mode: the hint opens when the trigger
    is hovered or focused and closes on leave, blur, or Escape. Positioning
    (flip + shift) runs in a colocated hook. Requires the popover component.

    ## Example

    ```sh
    mix pulsar.gen.tooltip

    # With custom module namespace
    mix pulsar.gen.tooltip --components-module=MyAppWeb.UI
    ```

    ## Features

    - Opens on hover (after a short delay) and on keyboard focus (immediately)
    - Dismissible with Escape; the hint is hoverable so the pointer can reach it
    - Anchored placement: top/bottom/left/right with start/center/end align
    - Flip + shift so the hint stays on screen
    - Caret pointing at the trigger (on by default, opt out with `arrow={false}`)
    - Opaque solid surfaces: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Accessibility built-in (role="tooltip", aria-describedby wiring)

    ## Usage Examples

    ```elixir
    <.tooltip id="save-tip">
      <:trigger><.button aria-label="Save"><.icon name="hero-check" /></.button></:trigger>
      Save changes
    </.tooltip>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
