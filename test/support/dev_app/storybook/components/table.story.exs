defmodule Pulsar.DevApp.Storybook.Components.Table do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Table

  def function, do: &Table.table/1
  def render_source, do: :function

  # Sample rows data for all table variations
  @rows [
    %{id: 1, name: "Ada Lovelace", role: "Engineer", status: "active"},
    %{id: 2, name: "Grace Hopper", role: "Admiral", status: "active"},
    %{id: 3, name: "Alan Turing", role: "Cryptanalyst", status: "inactive"}
  ]

  def attributes do
    [
      %Attr{
        id: :id,
        type: :string,
        default: nil,
        doc: "Table ID"
      },
      %Attr{
        id: :rows,
        type: :list,
        required: true,
        doc: "List of row data (maps or structs)"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "ghost",
        doc: "Visual style variant of the table"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the table"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(sm md lg),
        default: "md",
        doc: "Size of the table (controls cell padding)"
      },
      %Attr{
        id: :striped,
        type: :boolean,
        default: false,
        doc: "Enable zebra striping for rows"
      },
      %Attr{
        id: :sticky_header,
        type: :boolean,
        default: false,
        doc: "Make the table header sticky"
      },
      %Attr{
        id: :loading,
        type: :boolean,
        default: false,
        doc: "Show loading skeleton state"
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
      %Slot{id: :col, required: true, doc: "Column definition with :let binding and label"},
      %Slot{id: :action, doc: "Action column at the end of each row"},
      %Slot{id: :empty, doc: "Content to display when rows is empty"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default ghost table",
        attributes: %{id: "table-default", rows: @rows},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:col :let={row} label=\"Role\">{row.role}</:col>",
          "<:col :let={row} label=\"Status\">{row.status}</:col>"
        ]
      },
      %Variation{
        id: :outline_primary,
        description: "Outline primary table",
        attributes: %{id: "table-outline", rows: @rows, variant: "outline", color: "primary"},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:col :let={row} label=\"Role\">{row.role}</:col>",
          "<:col :let={row} label=\"Status\">{row.status}</:col>"
        ]
      },
      %Variation{
        id: :striped,
        description: "Striped rows",
        attributes: %{id: "table-striped", rows: @rows, striped: true},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:col :let={row} label=\"Role\">{row.role}</:col>",
          "<:col :let={row} label=\"Status\">{row.status}</:col>"
        ]
      },
      %Variation{
        id: :with_actions,
        description: "Table with action column",
        attributes: %{id: "table-actions", rows: @rows},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:col :let={row} label=\"Role\">{row.role}</:col>",
          "<:action :let={_row}>Edit</:action>"
        ]
      },
      %Variation{
        id: :empty_state,
        description: "Empty table with empty slot",
        attributes: %{id: "table-empty", rows: []},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:empty>No users found.</:empty>"
        ]
      },
      %Variation{
        id: :size_sm,
        description: "Small compact table",
        attributes: %{id: "table-sm", rows: @rows, size: "sm"},
        slots: [
          "<:col :let={row} label=\"Name\">{row.name}</:col>",
          "<:col :let={row} label=\"Status\">{row.status}</:col>"
        ]
      }
    ]
  end
end
