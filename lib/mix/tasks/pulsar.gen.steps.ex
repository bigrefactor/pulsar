defmodule Mix.Tasks.Pulsar.Gen.Steps do
  use Pulsar.Generator,
    component: :steps,
    example: "mix pulsar.gen.steps",
    long_doc: """
    Generates a steps component — a progress indicator for multi-step flows.

    Creates an accessible Steps component for onboarding, wizards, and checkout.
    The host passes `current` (the 1-based active step); each step's state
    (done / current / upcoming) is derived, and a step may override its state
    (error / loading / disabled). Horizontal and vertical orientations,
    `solid`/`outline`/`ghost` variants, seven colors, and `xs`–`xl` sizes.

    ## Example

    ```sh
    mix pulsar.gen.steps

    # With custom module namespace
    mix pulsar.gen.steps --components-module=MyAppWeb.UI
    ```

    ## Features

    - Done / current / upcoming derived from a single `current` index
    - Per-step overrides: state (error/loading/disabled), icon, color
    - Orientations: horizontal (marker above label), vertical (marker left)
    - Variants: solid, outline, ghost; colors: neutral … info; sizes: xs … xl
    - Number or dot markers; solid or dashed connectors
    - Localizable `aria_label` and per-state screen-reader status text

    ## Usage Examples

    ```elixir
    <.steps current={3} aria_label="Checkout progress">
      <:step label="Cart" description="3 items" />
      <:step label="Shipping" icon="hero-truck" />
      <:step label="Payment" state="error" />
      <:step label="Review" />
    </.steps>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
