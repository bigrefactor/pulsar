defmodule Pulsar.DevApp.Storybook.Components.Collapsible do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Collapsible

  def function, do: &Collapsible.collapsible/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{id: :id, type: :string, doc: "Collapsible container id (auto-generated if omitted)."},
      %Attr{id: :open, type: :boolean, default: false, doc: "Open on first render."},
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "outline",
        doc: "Visual chrome."
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Open-trigger tint."
      },
      %Attr{id: :size, type: :string, values: ~w(xs sm md lg xl), default: "md", doc: "Trigger/panel size."},
      %Attr{id: :class, type: :string, default: "", doc: "Additional CSS classes."}
    ]
  end

  def slots do
    [
      %Slot{id: :trigger, required: true, doc: "Clickable label content."},
      %Slot{id: :inner_block, required: true, doc: "The collapsible panel content."}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Closed by default",
        attributes: %{id: "sb-collapsible-default", class: "max-w-md"},
        slots: [
          "<:trigger>Show details</:trigger>",
          "<p class=\"text-muted-foreground\">The hidden details appear here.</p>"
        ]
      },
      %Variation{
        id: :open,
        description: "Open initially, primary tint",
        attributes: %{id: "sb-collapsible-open", open: true, color: "primary", class: "max-w-md"},
        slots: [
          "<:trigger>Filters</:trigger>",
          "<p class=\"text-muted-foreground\">Filter controls.</p>"
        ]
      },
      %Variation{
        id: :ghost,
        description: "Borderless",
        attributes: %{id: "sb-collapsible-ghost", variant: "ghost", class: "max-w-md"},
        slots: [
          "<:trigger>More options</:trigger>",
          "<p class=\"text-muted-foreground\">Extra options.</p>"
        ]
      }
    ]
  end
end
