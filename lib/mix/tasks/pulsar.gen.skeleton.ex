defmodule Mix.Tasks.Pulsar.Gen.Skeleton do
  use Pulsar.Generator,
    component: :skeleton,
    example: "mix pulsar.gen.skeleton",
    long_doc: """
    Generates a skeleton loading-placeholder component.

    Creates a self-contained skeleton component that renders muted, gently
    pulsing shapes standing in for content while it loads — text lines, a circle
    (for an avatar), or a rectangular block. Compose several to mirror the layout
    you are waiting on.

    ## Example

    ```sh
    mix pulsar.gen.skeleton

    # With custom module namespace
    mix pulsar.gen.skeleton --components-module=MyAppWeb.UI
    ```

    ## Features

    - Kinds: `text` (a line), `circle` (avatar placeholder), `rect` (block)
    - Multi-line text via `lines` (the last bar is shortened)
    - Circle `size` (xs–2xl) matching the Avatar scale
    - Streaming-text mode via `animate_text`
    - Optional `label` wraps the shapes in a polite `role="status"` region

    ## Usage Examples

    ```elixir
    # A line of text
    <.skeleton />

    # Three stacked text lines
    <.skeleton kind="text" lines={3} />

    # A circle the size of a large avatar
    <.skeleton kind="circle" size="lg" />

    # A block sized to the content it replaces
    <.skeleton kind="rect" class="h-40 w-full" />

    # Announced to screen readers while loading
    <.skeleton kind="text" lines={2} label="Loading profile" />
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
