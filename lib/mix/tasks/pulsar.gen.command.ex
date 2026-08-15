defmodule Mix.Tasks.Pulsar.Gen.Command do
  use Pulsar.Generator,
    component: :command,
    example: "mix pulsar.gen.command",
    long_doc: """
    Generates a searchable, keyboard-navigable option list.

    Renders a query field over a filtered list and reports the chosen option to
    the caller. Use it inline, or inside a popover or modal.

    ## Example

    ```sh
    mix pulsar.gen.command

    # With custom module namespace
    mix pulsar.gen.command --components-module=MyAppWeb.UI
    ```

    ## Features

    - Accepts the same option shapes as `select`, including grouped options
    - Pluggable filtering, with a built-in subsequence matcher
    - Off-process filtering for I/O-bound sources via the `async` attr
    - Combobox ARIA with a roving active option and full keyboard navigation

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
