defmodule Pulsar.DevApp.Storybook.Components.List do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.List

  def function, do: &List.list/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "ghost",
        doc: "Visual style variant of the list"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the list"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size affecting spacing and typography"
      },
      %Attr{
        id: :striped,
        type: :boolean,
        default: false,
        doc: "Enable zebra striping for rows"
      },
      %Attr{
        id: :dividers,
        type: :boolean,
        default: true,
        doc: "Show dividers between items"
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
      %Slot{id: :item, doc: "List item with required :title attribute"},
      %Slot{id: :title, doc: "Optional title for the list"},
      %Slot{id: :description, doc: "Optional description for the list"},
      %Slot{id: :empty, doc: "Content to display when no items are present"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Basic list with items",
        attributes: %{},
        slots: [
          "<:item title=\"Name\">Ada Lovelace</:item>",
          "<:item title=\"Role\">Engineer</:item>",
          "<:item title=\"Status\">Active</:item>"
        ]
      },
      %Variation{
        id: :with_title,
        description: "List with title and description",
        attributes: %{},
        slots: [
          "<:title>User Information</:title>",
          "<:description>Personal details and account information.</:description>",
          "<:item title=\"Email\">grace@example.com</:item>",
          "<:item title=\"Phone\">+1 555 000 1234</:item>"
        ]
      },
      %Variation{
        id: :striped,
        description: "Striped list",
        attributes: %{striped: true},
        slots: [
          "<:item title=\"First\">Row one</:item>",
          "<:item title=\"Second\">Row two</:item>",
          "<:item title=\"Third\">Row three</:item>",
          "<:item title=\"Fourth\">Row four</:item>"
        ]
      },
      %Variation{
        id: :no_dividers,
        description: "List without dividers",
        attributes: %{dividers: false},
        slots: [
          "<:item title=\"Language\">Elixir</:item>",
          "<:item title=\"Framework\">Phoenix</:item>"
        ]
      },
      %Variation{
        id: :outline_primary,
        description: "Outline primary list",
        attributes: %{variant: "outline", color: "primary"},
        slots: [
          "<:item title=\"Project\">Pulsar</:item>",
          "<:item title=\"Version\">0.1.0</:item>"
        ]
      },
      %Variation{
        id: :empty_state,
        description: "List with empty state",
        attributes: %{},
        slots: [
          "<:empty>No items found.</:empty>"
        ]
      }
    ]
  end
end
