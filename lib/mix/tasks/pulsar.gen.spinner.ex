defmodule Mix.Tasks.Pulsar.Gen.Spinner do
  use Pulsar.Generator,
    component: :spinner,
    example: "mix pulsar.gen.spinner",
    long_doc: """
    Generates a spinner component for loading and async states.

    The spinner is an accessible, animated loading indicator in three styles
    (ring, dots, bars). By default it announces itself to assistive
    technologies via a status role and a visually-hidden label.

    ## Examples

        $ mix pulsar.gen.spinner

    ## Usage

        <.spinner />
        <.spinner variant="dots" size="lg" color="primary" />
        <.spinner label="Saving changes" />
        <.spinner decorative />
    """
end
