defmodule Mix.Tasks.Pulsar.Gen.Spinner do
  use Pulsar.Generator,
    component: :spinner,
    example: "mix pulsar.gen.spinner",
    long_doc: """
    Generates a spinner component for loading and async states.

    The spinner is an accessible, animated loading indicator. By default it
    announces itself to assistive technologies via a status role and a
    visually-hidden label.

    ## Examples

        $ mix pulsar.gen.spinner

    ## Usage

        <.spinner />
        <.spinner size="lg" color="primary" />
        <.spinner label="Saving changes" />
        <.spinner decorative />
    """
end
