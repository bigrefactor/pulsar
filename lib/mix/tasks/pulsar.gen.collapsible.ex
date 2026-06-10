defmodule Mix.Tasks.Pulsar.Gen.Collapsible do
  use Pulsar.Generator,
    component: :collapsible,
    example: "mix pulsar.gen.collapsible",
    long_doc: """
    Generates the Collapsible component: a single expand/collapse disclosure —
    a trigger over one collapsible panel.

    ## Example

        mix pulsar.gen.collapsible

    ## Generated component

        <.collapsible id="more">
          <:trigger>Show details</:trigger>
          <p>Hidden details.</p>
        </.collapsible>

    The component ships a colocated LiveView hook that powers expand/collapse —
    wire up your app's colocated-hooks bundle so the hook mounts.

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
