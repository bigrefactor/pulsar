defmodule Pulsar.DevApp.DropzoneLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry
  alias Pulsar.Components.Dropzone

  @colors ~w(neutral primary secondary success danger warning info)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, variant: variant, colors: @colors)

    ~H"""
    <.fixture_page name={"dropzone-#{@variant}"} title={"Dropzone (#{@variant})"}>
      <.fixture_section name={"variant-#{@variant}"} title={"variant: #{@variant}"}>
        <Dropzone.dropzone
          :for={color <- @colors}
          upload={config("#{@variant}-#{color}")}
          variant={@variant}
          color={color}
          hint="PNG or JPG, up to 8 MB"
          data-fixture-cell={"#{@variant}-#{color}-md"}
        />
      </.fixture_section>
      <.fixture_section :if={@live_action == :outline} name="states" title="entry states">
        <Dropzone.dropzone upload={uploading_config()} data-fixture-cell="state-uploading" />
        <Dropzone.dropzone upload={errored_config()} data-fixture-cell="state-errored" />
        <Dropzone.dropzone upload={config_error_config()} data-fixture-cell="state-config-error" />
      </.fixture_section>
    </.fixture_page>
    """
  end

  defp config(ref, attrs \\ []) do
    defaults = [name: String.to_atom(ref), ref: ref, entries: [], errors: [], max_entries: 3]
    struct(UploadConfig, Keyword.merge(defaults, attrs))
  end

  defp uploading_config do
    config("state-uploading",
      entries: [
        entry("a", "state-uploading", client_name: "team-photo.jpg", progress: 70),
        entry("b", "state-uploading",
          client_name: "notes.pdf",
          client_type: "application/pdf",
          progress: 15
        )
      ]
    )
  end

  defp errored_config do
    config("state-errored",
      entries: [entry("c", "state-errored", client_name: "huge.jpg")],
      errors: [{"c", :too_large}]
    )
  end

  defp config_error_config do
    config("state-cfg-err", errors: [{"state-cfg-err", :too_many_files}])
  end

  defp entry(ref, upload_ref, attrs) do
    defaults = [
      ref: ref,
      upload_ref: upload_ref,
      upload_config: :files,
      client_size: 1_048_576,
      client_type: "image/jpeg",
      progress: 0,
      valid?: true
    ]

    struct(UploadEntry, Keyword.merge(defaults, [ref: ref, upload_ref: upload_ref] ++ attrs))
  end
end
