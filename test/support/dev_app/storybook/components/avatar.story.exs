defmodule Pulsar.DevApp.Storybook.Components.Avatar do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Avatar

  def function, do: &Avatar.avatar/1
  def render_source, do: :function

  @sample_image "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='80' height='80'><rect width='80' height='80' fill='%234f46e5'/><text x='50%' y='54%' font-size='32' fill='white' text-anchor='middle' dominant-baseline='middle'>JD</text></svg>"

  def attributes do
    [
      %Attr{id: :src, type: :string, default: nil, doc: "Image URL. When present, renders an <img>"},
      %Attr{
        id: :name,
        type: :string,
        default: nil,
        doc: "Entity name. Reduced to initials for the fallback and used as the accessible name"
      },
      %Attr{
        id: :alt,
        type: :string,
        default: nil,
        doc: "Overrides the accessible name. Pass \"\" for a decorative avatar"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline),
        default: "solid",
        doc: "Visual style: solid (filled) or outline (bordered)"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl 2xl),
        default: "md",
        doc: "Avatar size"
      },
      %Attr{id: :class, type: :string, default: "", doc: "Additional CSS classes"}
    ]
  end

  def slots, do: []

  def variations do
    [
      %Variation{
        id: :image,
        description: "Image avatar",
        attributes: %{src: @sample_image, name: "Jane Doe"}
      },
      %Variation{
        id: :initials,
        description: "Initials fallback (no image)",
        attributes: %{name: "Jane Doe"}
      },
      %Variation{
        id: :icon,
        description: "Icon fallback (no image, no name)",
        attributes: %{}
      },
      %Variation{
        id: :outline,
        description: "Outline variant",
        attributes: %{name: "Jane Doe", variant: "outline"}
      },
      %Variation{
        id: :size_xs,
        description: "Extra-small",
        attributes: %{name: "Jane Doe", size: "xs"}
      },
      %Variation{
        id: :size_lg,
        description: "Large",
        attributes: %{name: "Jane Doe", size: "lg"}
      },
      %Variation{
        id: :size_2xl,
        description: "Extra-extra-large",
        attributes: %{name: "Jane Doe", size: "2xl"}
      }
    ]
  end
end
