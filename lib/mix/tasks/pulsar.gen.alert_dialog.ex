defmodule Mix.Tasks.Pulsar.Gen.AlertDialog do
  use Pulsar.Generator,
    component: :alert_dialog,
    example: "mix pulsar.gen.alert_dialog",
    long_doc: """
    Generates a constrained confirmation dialog for destructive actions.

    Built on the modal primitive: it traps focus, dims the page, and locks scroll,
    but bakes in a fixed Cancel/Confirm footer so the destructive `on_confirm`
    command rides only on the Confirm button. Escape and Cancel dismiss without
    running it; backdrop clicks and the corner close button are removed so the
    choice can't be dismissed by accident. Requires the modal and button components.

    ## Example

    ```sh
    mix pulsar.gen.alert_dialog

    # With custom module namespace
    mix pulsar.gen.alert_dialog --components-module=MyAppWeb.UI
    ```

    ## Features

    - One behavioral hook: `on_confirm` runs on Confirm, then the dialog closes
    - Escape and Cancel are inert dismissals; no backdrop dismiss, no close button
    - Focus lands on Cancel so an accidental Enter can't confirm
    - `role="alertdialog"` with the title as the accessible name and the body wired
      as `aria-describedby`
    - Configurable Confirm color (defaults to `danger`) for destructive or merely
      important confirmations
    - Full surface passthrough: variant, color, and size

    ## Usage Examples

    ```elixir
    <.button color="danger" phx-click={AlertDialog.open("delete")}>Delete</.button>

    <.alert_dialog id="delete" title="Delete project?" on_confirm={JS.push("delete")}>
      This can't be undone.
    </.alert_dialog>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
