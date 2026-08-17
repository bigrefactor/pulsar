defmodule Mix.Tasks.Pulsar.Gen.Combobox do
  use Pulsar.Generator,
    component: :combobox,
    example: "mix pulsar.gen.combobox",
    long_doc: """
    Generates a typeahead form control.

    A text input filters a list of options as you type; picking one sets the
    field's value. Set `multiple` to collect several as removable badges.

    ## Example

    ```sh
    mix pulsar.gen.combobox

    # With custom module namespace
    mix pulsar.gen.combobox --components-module=MyAppWeb.UI
    ```

    ## Features

    - Accepts the same option shapes as `select`, including grouped options
    - Pluggable filtering, with a built-in subsequence matcher
    - Off-process filtering for I/O-bound sources via the `async` attr
    - Single or multiple selection, with array form binding
    - Combobox ARIA with a roving active option and full keyboard navigation

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
