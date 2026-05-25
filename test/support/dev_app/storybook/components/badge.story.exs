defmodule Pulsar.DevApp.Storybook.Components.Badge do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Badge

  def function, do: &Badge.badge/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant of the badge"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the badge"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the badge"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, required: true, doc: "Badge content"},
      %Slot{id: :start_addon, doc: "Content at the start of the badge (before text)"},
      %Slot{id: :end_addon, doc: "Content at the end of the badge (after text)"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default neutral solid badge",
        attributes: %{},
        slots: ["New"]
      },
      %Variation{
        id: :primary_solid,
        description: "Primary solid badge",
        attributes: %{variant: "solid", color: "primary"},
        slots: ["Primary"]
      },
      %Variation{
        id: :success_outline,
        description: "Success outline badge",
        attributes: %{variant: "outline", color: "success"},
        slots: ["Completed"]
      },
      %Variation{
        id: :danger_ghost,
        description: "Danger ghost badge",
        attributes: %{variant: "ghost", color: "danger"},
        slots: ["Error"]
      },
      %Variation{
        id: :warning_solid,
        description: "Warning solid badge",
        attributes: %{variant: "solid", color: "warning"},
        slots: ["Warning"]
      },
      %Variation{
        id: :size_xs,
        description: "Extra-small badge",
        attributes: %{size: "xs", color: "primary"},
        slots: ["XS"]
      },
      %Variation{
        id: :size_xl,
        description: "Extra-large badge",
        attributes: %{size: "xl", color: "primary"},
        slots: ["XL"]
      },
      %Variation{
        id: :info_outline,
        description: "Info outline badge",
        attributes: %{variant: "outline", color: "info"},
        slots: ["Info"]
      }
    ]
  end
end
