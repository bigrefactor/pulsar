defmodule Mix.Tasks.Pulsar.Gen.Icon do
  use Pulsar.Generator,
    component: :icon,
    example: "mix pulsar.gen.icon",
    long_doc: """
    Generates an icon component supporting all Heroicons variants with flexible sizing

    Creates a comprehensive icon component with access to all Heroicons (outline, solid,
    mini, micro), Pulsar's semantic color system, responsive sizing, and proper
    accessibility attributes.

    ## Example

    ```sh
    mix pulsar.gen.icon

    # With custom module namespace
    mix pulsar.gen.icon --components-module=MyAppWeb.UI
    ```

    ## Features

    - Heroicons variants: outline (24×24), solid (24×24), mini (20×20), micro (16×16)
    - Semantic colors: neutral, primary, secondary, success, danger, warning, info, current
    - Sizes: xs (12px), sm (16px), md (20px), lg (24px), xl (32px)
    - Decorative by default with aria-hidden
    - Optional aria_label for informative icons
    - Automatic dark mode support
    - Current color inheritance from parent

    ## Usage Examples

    ```elixir
    # Basic outline icon (decorative)
    <.icon name="hero-check" />

    # Solid variant with color
    <.icon name="hero-heart" variant="solid" color="danger" />

    # Micro icon scaled up
    <.icon name="hero-x-mark" variant="micro" size="lg" />

    # Current color (inherits from parent)
    <.icon name="hero-information-circle" color="current" />

    # Informative icon with accessible label
    <.icon name="hero-exclamation-triangle" color="warning" aria_label="Warning" />
    ```

    ## Heroicons Variants

    - outline: 24×24 stroke-based icons (default)
    - solid: 24×24 filled icons
    - mini: 20×20 filled icons for compact interfaces
    - micro: 16×16 filled icons for very tight spaces

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
