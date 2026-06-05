defmodule Mix.Tasks.Pulsar.Gen.Tabs do
  use Pulsar.Generator,
    component: :tabs,
    example: "mix pulsar.gen.tabs",
    long_doc: """
    Generates a tabs component — a tablist with associated panels.

    Creates an accessible Tabs component with horizontal/vertical orientation,
    APG keyboard navigation, and four visual variants. Each tab declares a
    trigger label and holds its panel content; the selected panel is shown and
    the rest are hidden, switched client-side.

    ## Example

    ```sh
    mix pulsar.gen.tabs

    # With custom module namespace
    mix pulsar.gen.tabs --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: ghost (underline), solid (segmented), outline (boxed), elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Horizontal and vertical orientation with arrow-key navigation
    - Per-tab icon, disabled, and color override
    - on_change callback for syncing the active tab to the server

    ## Usage Examples

    ```elixir
    <.tabs id="settings" aria_label="Settings">
      <:tab id="profile" label="Profile" icon="hero-user">Profile content</:tab>
      <:tab id="billing" label="Billing" icon="hero-credit-card">Billing content</:tab>
    </.tabs>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
