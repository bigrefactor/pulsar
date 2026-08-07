defmodule Mix.Tasks.Pulsar.Gen.Dropzone do
  use Pulsar.Generator,
    component: :dropzone,
    example: "mix pulsar.gen.dropzone",
    long_doc: """
    Generates a dropzone component for LiveView file uploads.

    The dropzone renders a drag-and-drop upload zone with click-to-browse, image
    previews, per-entry progress bars, cancel buttons, and upload error messages
    for an upload configured with `allow_upload/3`. Render it inside a form bound
    with `phx-change`. Requires the icon and progress components
    (`mix pulsar.gen.icon`, `mix pulsar.gen.progress`).

    ## Example

        <form phx-change="validate" phx-submit="save">
          <.dropzone upload={@uploads.avatar} hint="JPG or PNG, up to 8 MB" />
        </form>

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
