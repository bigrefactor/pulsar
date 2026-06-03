defmodule Mix.Tasks.Pulsar.Gen.Modal do
  use Pulsar.Generator,
    component: :modal,
    example: "mix pulsar.gen.modal",
    long_doc: """
    Generates a focus-trapped, dismissible modal dialog overlay.

    Built on the native HTML `<dialog>` element: a colocated hook opens it with
    `showModal()` (browser-provided focus trap, Escape handling, and dialog
    semantics) and adds scroll lock, backdrop-click dismissal, and open/close
    callbacks. Drive it from anywhere with the `open/2` and `close/2` helpers.

    ## Example

    ```sh
    mix pulsar.gen.modal

    # With custom module namespace
    mix pulsar.gen.modal --components-module=MyAppWeb.UI
    ```

    ## Features

    - Native `<dialog>` focus trap, Escape handling, and dimmed backdrop
    - Backdrop-click + Escape dismissal, with a `dismissable={false}` lock
    - Structured title, description, body, and footer regions
    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: sm, md, lg, xl
    - Scroll lock while open; focus returns to the opener on close

    ## Usage Examples

    ```elixir
    <.button phx-click={Modal.open("edit")}>Edit</.button>

    <.modal id="edit" title="Edit user">
      <:description>Update the details.</:description>
      ...
      <:footer>
        <.button phx-click={Modal.close("edit")}>Done</.button>
      </:footer>
    </.modal>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
