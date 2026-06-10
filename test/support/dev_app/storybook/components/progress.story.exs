defmodule Pulsar.DevApp.Storybook.Components.Progress do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Progress

  def function, do: &Progress.progress/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :shape,
        type: :string,
        values: ~w(linear radial),
        default: "linear",
        doc: "Progress shape: a linear bar or a radial ring"
      },
      %Attr{
        id: :value,
        type: :integer,
        default: nil,
        doc: "Current value. Omit for an indeterminate linear bar; required for radial."
      },
      %Attr{
        id: :max,
        type: :integer,
        default: 100,
        doc: "Value representing 100% complete"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Semantic color of the fill/ring"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the bar/ring"
      },
      %Attr{
        id: :label,
        type: :string,
        default: nil,
        doc: "Visible label and accessible name"
      },
      %Attr{
        id: :show_value,
        type: :boolean,
        default: false,
        doc: "Render the computed percentage (determinate only)"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes"
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :determinate,
        description: "Determinate bar",
        attributes: %{value: 62, label: "Uploading", show_value: true}
      },
      %Variation{
        id: :indeterminate,
        description: "Indeterminate bar",
        attributes: %{label: "Loading"}
      },
      %Variation{
        id: :success,
        description: "Success-colored",
        attributes: %{value: 100, color: "success", show_value: true}
      },
      %Variation{
        id: :radial,
        description: "Radial ring",
        attributes: %{shape: "radial", value: 62, show_value: true, size: "lg"}
      }
    ]
  end
end
