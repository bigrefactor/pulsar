defmodule Pulsar.DevApp.Storybook.Components.Avatar do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Avatar

  def function, do: &Avatar.avatar/1
  def render_source, do: :function

  @photo "https://i.pravatar.cc/150?img=12"
  @photo_alt "https://i.pravatar.cc/150?img=32"

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
        id: :photo,
        description: "Photo avatar",
        attributes: %{src: @photo, name: "Jane Doe"}
      },
      %Variation{
        id: :photo_large,
        description: "Photo avatar (large)",
        attributes: %{src: @photo_alt, name: "John Roe", size: "2xl"}
      },
      %Variation{
        id: :photo_outline,
        description: "Photo avatar with outline ring",
        attributes: %{src: @photo, name: "Jane Doe", variant: "outline"}
      },
      %Variation{
        id: :photo_linked,
        description: "Linked photo avatar",
        attributes: %{src: @photo, name: "Jane Doe", navigate: "/storybook/components/avatar"}
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
