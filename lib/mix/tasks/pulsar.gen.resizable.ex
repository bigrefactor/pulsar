defmodule Mix.Tasks.Pulsar.Gen.Resizable do
  use Pulsar.Generator,
    component: :resizable,
    example: "mix pulsar.gen.resizable",
    long_doc: """
    Generates the Resizable split-pane primitive: two panels divided by a
    draggable, keyboard-operable handle that resizes the second panel while the
    first flexes to fill the rest. With `collapsible`, the second panel can
    collapse to an edge and restore via the handle's toggle button.

    ## Example

        mix pulsar.gen.resizable

    ## Generated component

        <.resizable id="dock" default_size={30} min_size={15} max_size={60}>
          <:panel>
            <main>Primary content…</main>
          </:panel>
          <:panel label="Resize side panel">
            <section>Side content…</section>
          </:panel>
        </.resizable>

    The component ships a colocated LiveView hook that powers the drag — wire up
    your app's colocated-hooks bundle so the hook mounts.

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
