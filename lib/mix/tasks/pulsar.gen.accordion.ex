defmodule Mix.Tasks.Pulsar.Gen.Accordion do
  use Pulsar.Generator,
    component: :accordion,
    example: "mix pulsar.gen.accordion",
    long_doc: """
    Generates the Accordion component: a set of headers, each toggling a
    collapsible region (the WAI-ARIA Accordion pattern). Configure `type`
    ("single" or "multiple"), `collapsible`, and which section(s) start open via
    `value`.

    ## Example

        mix pulsar.gen.accordion

    ## Generated component

        <.accordion id="faq">
          <:item title="Shipping">We ship worldwide.</:item>
          <:item title="Returns">30-day returns.</:item>
        </.accordion>

    The component ships a colocated LiveView hook that powers expand/collapse and
    arrow-key navigation — wire up your app's colocated-hooks bundle so the hook
    mounts.

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
