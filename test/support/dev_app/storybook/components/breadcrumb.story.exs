defmodule Pulsar.DevApp.Storybook.Components.Breadcrumb do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Breadcrumb

  def function, do: &Breadcrumb.breadcrumb/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :color,
        type: :string,
        values: ~w(muted primary secondary success danger warning info),
        default: "muted",
        doc: "Accent color for the crumb links"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Text size of the trail"
      },
      %Attr{
        id: :max_items,
        type: :integer,
        default: nil,
        doc: "Collapse the middle when the item count exceeds this"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :item, required: true, doc: "A crumb; the last is the current page"},
      %Slot{id: :separator, doc: "Optional custom separator (default: chevron)"}
    ]
  end

  def variations do
    trail = [
      ~s|<:item navigate="/">Home</:item>|,
      ~s|<:item navigate="/products">Products</:item>|,
      ~s|<:item>Edit Product</:item>|
    ]

    [
      %Variation{
        id: :default,
        description: "Three crumbs, chevron separators",
        slots: trail
      },
      %Variation{
        id: :custom_separator,
        description: "Slash separator",
        slots: [
          ~s|<:separator>/</:separator>|,
          ~s|<:item navigate="/">Home</:item>|,
          ~s|<:item>Docs</:item>|
        ]
      },
      %Variation{
        id: :collapsed,
        description: "Long trail collapsed with max_items",
        attributes: %{max_items: 4},
        slots: [
          ~s|<:item navigate="/">Home</:item>|,
          ~s|<:item navigate="/workspace">Workspace</:item>|,
          ~s|<:item navigate="/billing">Billing</:item>|,
          ~s|<:item navigate="/settings">Settings</:item>|,
          ~s|<:item>Profile</:item>|
        ]
      }
    ]
  end
end
