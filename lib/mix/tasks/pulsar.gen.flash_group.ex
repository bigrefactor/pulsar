defmodule Mix.Tasks.Pulsar.Gen.FlashGroup do
  use Pulsar.Generator,
    component: :flash_group,
    example: "mix pulsar.gen.flash_group",
    long_doc: """
    Generates a container component for managing multiple flash notifications

    Creates an intelligent flash group component that reads from Phoenix.Flash and
    displays multiple notifications with automatic positioning, stacking, type-to-color
    mapping, and item limiting. Single integration point for all flash messages.

    ## Example

    ```sh
    mix pulsar.gen.flash_group

    # With custom module namespace
    mix pulsar.gen.flash_group --components-module=MyAppWeb.UI
    ```

    ## Features

    - Phoenix.Flash integration (reads from @flash assigns)
    - 6 position options (top/bottom × left/center/right)
    - Automatic stacking with coordinated animations
    - Type-to-color mapping (error→danger, warning→warning, etc.)
    - Configurable maximum number of visible flashes
    - Consistent styling across all flashes
    - Staggered entry/exit animations

    ## Dependencies

    This component requires: flash, icon

    ## Usage Examples

    ```elixir
    # Basic usage in layout or LiveView
    <.flash_group flash={@flash} />

    # Custom positioning and styling
    <.flash_group
      flash={@flash}
      variant="outline"
      position="bottom-right"
      max_items={3}
    />

    # Different positions
    <.flash_group flash={@flash} position="top-center" />
    <.flash_group flash={@flash} position="bottom-left" />
    ```

    ## Flash Type Mapping

    - `:error` → danger color
    - `:warning` → warning color
    - `:info` → info color
    - `:success` → success color
    - Custom types → neutral color

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
