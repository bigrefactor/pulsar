defmodule Pulsar.DevApp.Storybook.Components.Popover do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Popover

  def function, do: &Popover.popover/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :placement,
        type: :string,
        values:
          ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end),
        default: "bottom-start",
        doc: "Preferred anchor placement"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "elevated",
        doc: "Visual style of the panel surface"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the panel surface"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Interior padding and corner radius"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the panel"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :trigger, required: true, doc: "The activating control — a single <button>"},
      %Slot{id: :inner_block, required: true, doc: "Panel content"}
    ]
  end

  def variations do
    trigger = ~s|<:trigger><button class="rounded border border-border px-3 py-1.5 text-sm">Open</button></:trigger>|

    body =
      ~s|<div class="space-y-1"><p class="text-sm font-medium">Popover title</p><p class="text-sm text-muted-foreground">Anchored, dismissible content.</p></div>|

    [
      %Variation{
        id: :default,
        description: "Default elevated neutral popover",
        slots: [trigger, body]
      },
      %Variation{
        id: :outline_primary,
        description: "Outline primary surface",
        attributes: %{variant: "outline", color: "primary"},
        slots: [trigger, body]
      },
      %Variation{
        id: :solid_danger,
        description: "Soft danger surface (confirmations)",
        attributes: %{variant: "solid", color: "danger"},
        slots: [trigger, body]
      },
      %Variation{
        id: :top_end,
        description: "Anchored above, end-aligned",
        attributes: %{placement: "top-end"},
        slots: [trigger, body]
      }
    ]
  end
end
