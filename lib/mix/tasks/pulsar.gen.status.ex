defmodule Mix.Tasks.Pulsar.Gen.Status do
  use Pulsar.Generator,
    component: :status,
    example: "mix pulsar.gen.status",
    long_doc: """
    Generates a status-indicator component (dot + ping).

    A small colored dot for signalling state (online/offline/busy, unread,
    live), standalone or placed on the corner of another element via the
    `indicator/1` wrapper.

    ## Examples

        $ mix pulsar.gen.status

    ## Usage

        <.status color="success" label="Online" />
        <.status color="danger" ping label="Live" />

        <.indicator placement="bottom-right">
          <:item><.status color="success" label="Online" /></:item>
          <.avatar name="Jane Doe" />
        </.indicator>
    """
end
