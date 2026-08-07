defmodule Pulsar.DevApp.Storybook.Components.Dropzone do
  use PhoenixStorybook.Story, :component

  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry
  alias Pulsar.Components.Dropzone

  def function, do: &Dropzone.dropzone/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "outline",
        doc: "Visual style variant of the zone"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the zone"
      },
      %Attr{id: :size, type: :string, values: ~w(xs sm md lg xl), default: "md", doc: "Size of the zone"},
      %Attr{id: :prompt, type: :string, default: "Click to upload or drag and drop", doc: "Zone prompt text"},
      %Attr{id: :hint, type: :string, default: nil, doc: "Helper text under the prompt"},
      %Attr{id: :class, type: :string, default: "", doc: "Additional CSS classes"}
    ]
  end

  def variations do
    empty = upload_config()

    uploading =
      upload_config(
        ref: "sb-dz-uploading",
        entries: [
          entry(ref: "a", upload_ref: "sb-dz-uploading", client_name: "team-photo.jpg", progress: 70),
          entry(
            ref: "b",
            upload_ref: "sb-dz-uploading",
            client_name: "notes.pdf",
            client_type: "application/pdf",
            client_size: 24_576,
            progress: 15
          )
        ]
      )

    errored =
      upload_config(
        ref: "sb-dz-errored",
        entries: [entry(ref: "c", upload_ref: "sb-dz-errored", client_name: "huge.jpg")],
        errors: [{"c", :too_large}]
      )

    [
      %Variation{
        id: :default,
        description: "Default zone",
        attributes: %{upload: empty, hint: "PNG or JPG, up to 8 MB"}
      },
      %Variation{id: :uploading, description: "Entries with progress", attributes: %{upload: uploading}},
      %Variation{id: :entry_error, description: "Entry with an error", attributes: %{upload: errored}},
      %Variation{
        id: :solid_primary,
        description: "Solid primary",
        attributes: %{upload: upload_config(ref: "sb-dz-solid"), variant: "solid", color: "primary"}
      },
      %Variation{
        id: :large,
        description: "Large zone",
        attributes: %{upload: upload_config(ref: "sb-dz-lg"), size: "lg", hint: "Up to 8 MB"}
      }
    ]
  end

  defp upload_config(attrs \\ []) do
    defaults = [name: :files, ref: "sb-dz", entries: [], errors: [], max_entries: 3]
    struct(UploadConfig, Keyword.merge(defaults, attrs))
  end

  defp entry(attrs) do
    defaults = [
      upload_config: :files,
      client_size: 1_048_576,
      client_type: "image/jpeg",
      progress: 0,
      valid?: true
    ]

    struct(UploadEntry, Keyword.merge(defaults, attrs))
  end
end
