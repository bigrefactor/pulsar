defmodule Mix.Tasks.Pulsar.Gen.Progress do
  use Pulsar.Generator,
    component: :progress,
    example: "mix pulsar.gen.progress",
    long_doc: """
    Generates a progress component for showing task completion.

    The progress component renders a determinate or indeterminate linear bar, or
    a determinate radial ring, for uploads, imports, and onboarding flows.

    ## Examples

        $ mix pulsar.gen.progress

    ## Usage

        <.progress value={62} label="Uploading…" show_value />
        <.progress value={3} max={10} color="success" />
        <.progress />
        <.progress shape="radial" value={62} show_value size="lg" />
    """
end
