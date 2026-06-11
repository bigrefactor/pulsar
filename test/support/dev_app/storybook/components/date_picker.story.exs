defmodule Pulsar.DevApp.Storybook.Components.DatePicker do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.DatePicker

  def function, do: &DatePicker.date_picker/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :mode,
        type: :string,
        values: ~w(single range),
        default: "single",
        doc: "Single date or date range"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(outline solid ghost),
        default: "outline",
        doc: "Input surface treatment"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Calendar selection accent"
      },
      %Attr{id: :size, type: :string, values: ~w(xs sm md lg xl), default: "md", doc: "Input height"},
      %Attr{id: :disabled, type: :boolean, default: false, doc: "Disable the picker"}
    ]
  end

  def variations do
    [
      %Variation{id: :single, description: "Single date", attributes: %{id: "sb-dp-single"}},
      %Variation{id: :range, description: "Range", attributes: %{id: "sb-dp-range", mode: "range"}},
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{id: "sb-dp-disabled", disabled: true}
      },
      %Variation{
        id: :solid,
        description: "Solid variant",
        attributes: %{id: "sb-dp-solid", variant: "solid"}
      }
    ]
  end
end
