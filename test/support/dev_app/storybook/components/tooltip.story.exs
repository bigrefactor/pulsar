defmodule Pulsar.DevApp.Storybook.Components.Tooltip do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Tooltip

  def function, do: &Tooltip.tooltip/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :placement,
        type: :string,
        values:
          ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end),
        default: "top",
        doc: "Preferred anchor placement"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color of the tooltip's solid surface"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "sm",
        doc: "Interior padding and corner radius"
      },
      %Attr{
        id: :arrow,
        type: :boolean,
        default: true,
        doc: "Render a caret pointing at the trigger"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the tooltip"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :trigger, required: true, doc: "The element the tooltip describes — a focusable control"},
      %Slot{id: :inner_block, required: true, doc: "Tooltip content (plain, non-interactive text)"}
    ]
  end

  def variations do
    trigger =
      ~s|<:trigger><button type="button" class="rounded border border-border px-3 py-1.5 text-sm">Hover me</button></:trigger>|

    [
      %Variation{
        id: :default,
        description: "Default neutral tooltip",
        slots: [trigger, "Save changes"]
      },
      %Variation{
        id: :primary,
        description: "Primary surface",
        attributes: %{color: "primary"},
        slots: [trigger, "More information"]
      },
      %Variation{
        id: :danger,
        description: "Danger surface",
        attributes: %{color: "danger"},
        slots: [trigger, "This cannot be undone"]
      },
      %Variation{
        id: :right_placement,
        description: "Anchored to the right",
        attributes: %{placement: "right"},
        slots: [trigger, "Appears to the side"]
      },
      %Variation{
        id: :no_arrow,
        description: "Without the caret",
        attributes: %{arrow: false},
        slots: [trigger, "No caret here"]
      }
    ]
  end
end
