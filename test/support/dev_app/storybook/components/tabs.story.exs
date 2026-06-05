defmodule Pulsar.DevApp.Storybook.Components.Tabs do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Tabs

  def function, do: &Tabs.tabs/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "ghost",
        doc: "Visual style of the tablist"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color of the active tab indicator"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Tab padding and text size"
      },
      %Attr{
        id: :orientation,
        type: :string,
        values: ~w(horizontal vertical),
        default: "horizontal",
        doc: "Layout and arrow-key navigation direction"
      },
      %Attr{
        id: :active,
        type: :string,
        default: nil,
        doc: "id of the initially-active tab"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the container"
      }
    ]
  end

  def slots do
    [%Slot{id: :tab, required: true, doc: "A tab and its panel"}]
  end

  def variations do
    tabs = [
      ~s|<:tab id="overview" label="Overview">Overview panel</:tab>|,
      ~s|<:tab id="activity" label="Activity">Activity panel</:tab>|,
      ~s|<:tab id="reports" label="Reports">Reports panel</:tab>|
    ]

    [
      %Variation{
        id: :ghost,
        description: "Underline (default)",
        attributes: %{id: "sb-tabs-ghost", aria_label: "Ghost tabs"},
        slots: tabs
      },
      %Variation{
        id: :solid,
        description: "Segmented",
        attributes: %{id: "sb-tabs-solid", variant: "solid", color: "primary", aria_label: "Solid tabs"},
        slots: tabs
      },
      %Variation{
        id: :outline,
        description: "Boxed",
        attributes: %{id: "sb-tabs-outline", variant: "outline", aria_label: "Outline tabs"},
        slots: tabs
      },
      %Variation{
        id: :elevated,
        description: "Segmented, raised active tab",
        attributes: %{id: "sb-tabs-elevated", variant: "elevated", color: "primary", aria_label: "Elevated tabs"},
        slots: tabs
      },
      %Variation{
        id: :vertical,
        description: "Vertical orientation",
        attributes: %{id: "sb-tabs-vertical", orientation: "vertical", aria_label: "Vertical tabs"},
        slots: tabs
      }
    ]
  end
end
