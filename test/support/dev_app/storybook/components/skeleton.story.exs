defmodule Pulsar.DevApp.Storybook.Components.Skeleton do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Skeleton

  def function, do: &Skeleton.skeleton/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :kind,
        type: :string,
        values: ~w(text circle rect),
        default: "text",
        doc: "Shape: text (a line), circle (avatar placeholder), or rect (block)"
      },
      %Attr{
        id: :lines,
        type: :integer,
        default: 1,
        doc: "For kind=\"text\": number of stacked line bars; the last one is shortened"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl 2xl),
        default: "md",
        doc: "For kind=\"circle\": box size, matching the Avatar scale"
      },
      %Attr{
        id: :animate_text,
        type: :boolean,
        default: false,
        doc: "Render the inner text content with a pulsing color"
      },
      %Attr{
        id: :label,
        type: :string,
        default: nil,
        doc: "When set, wrap the shapes in a polite role=\"status\" loading region"
      }
    ]
  end

  def slots, do: [%Slot{id: :inner_block, doc: "Text content shown when animate_text is set"}]

  def variations do
    [
      %Variation{
        id: :text,
        description: "A single line of text",
        attributes: %{}
      },
      %Variation{
        id: :lines,
        description: "Three stacked text lines",
        attributes: %{kind: "text", lines: 3}
      },
      %Variation{
        id: :circle,
        description: "Circle (avatar placeholder)",
        attributes: %{kind: "circle"}
      },
      %Variation{
        id: :circle_lg,
        description: "Large circle",
        attributes: %{kind: "circle", size: "lg"}
      },
      %Variation{
        id: :rect,
        description: "Rectangular block",
        attributes: %{kind: "rect"}
      },
      %Variation{
        id: :animate_text,
        description: "Streaming-text placeholder",
        attributes: %{animate_text: true},
        slots: ["Thinking…"]
      },
      %Variation{
        id: :labelled,
        description: "Announced loading status",
        attributes: %{kind: "text", lines: 2, label: "Loading profile"}
      }
    ]
  end
end
