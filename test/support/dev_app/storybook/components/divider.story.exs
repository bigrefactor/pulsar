defmodule Pulsar.DevApp.Storybook.Components.Divider do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Divider

  def function, do: &Divider.divider/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "outline",
        doc: "Visual emphasis level of the divider"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the divider"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size affecting thickness and spacing"
      },
      %Attr{
        id: :orientation,
        type: :string,
        values: ~w(horizontal vertical),
        default: "horizontal",
        doc: "Orientation of the divider"
      },
      %Attr{
        id: :line_style,
        type: :string,
        values: ~w(solid dashed dotted),
        default: "solid",
        doc: "Line style pattern"
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
      %Slot{id: :inner_block, doc: "Optional label content for the divider"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default horizontal divider",
        attributes: %{}
      },
      %Variation{
        id: :with_label,
        description: "Divider with centered label",
        attributes: %{color: "neutral"},
        slots: ["Section Title"]
      },
      %Variation{
        id: :primary_color,
        description: "Primary color divider",
        attributes: %{color: "primary", variant: "solid"}
      },
      %Variation{
        id: :dashed,
        description: "Dashed line style",
        attributes: %{line_style: "dashed"}
      },
      %Variation{
        id: :dotted,
        description: "Dotted line style",
        attributes: %{line_style: "dotted"}
      },
      %Variation{
        id: :success_with_label,
        description: "Success-colored divider with label",
        attributes: %{color: "success"},
        slots: ["Completed"]
      },
      %Variation{
        id: :ghost_variant,
        description: "Ghost variant (subtle divider)",
        attributes: %{variant: "ghost"}
      }
    ]
  end
end
