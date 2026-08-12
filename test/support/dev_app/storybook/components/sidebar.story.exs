defmodule Pulsar.DevApp.Storybook.Components.Sidebar do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Sidebar

  def function, do: &Sidebar.sidebar/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :id,
        type: :string,
        required: true,
        doc: "Panel ID. Targeted by the toggle helpers."
      },
      %Attr{
        id: :side,
        type: :string,
        values: ~w(left right),
        default: "left",
        doc: "Edge the sidebar is anchored to"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "solid",
        doc: "Visual style of the panel surface"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the panel"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Expanded panel width and interior padding"
      },
      %Attr{
        id: :collapsible,
        type: :string,
        values: ~w(icon offcanvas none),
        default: "offcanvas",
        doc: "Desktop collapse behaviour"
      },
      %Attr{
        id: :open,
        type: :boolean,
        default: true,
        doc: "Initial expanded state on first render"
      },
      %Attr{
        id: :label,
        type: :string,
        default: "Sidebar",
        doc: "Accessible name for the navigation landmark"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the direct nav/layout root"
      },
      %Attr{
        id: :panel_class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the visual panel"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :header, doc: "Pinned top region (brand, logo)"},
      %Slot{id: :inner_block, required: true, doc: "Scrollable main content (navigation)"},
      %Slot{id: :footer, doc: "Pinned bottom region (account, status)"}
    ]
  end

  def variations do
    nav = """
    <nav class="flex flex-col gap-1">
      <a href="#" class="rounded-field px-2 py-1.5 hover:bg-surface-1-hover">Home</a>
      <a href="#" class="rounded-field px-2 py-1.5 hover:bg-surface-1-hover">Reports</a>
      <a href="#" class="rounded-field px-2 py-1.5 hover:bg-surface-1-hover">Settings</a>
    </nav>
    """

    [
      %Variation{
        id: :default,
        description: "Default solid neutral sidebar",
        attributes: %{id: "sb-sidebar-default", class: "h-96"},
        slots: [nav]
      },
      %Variation{
        id: :with_header_and_footer,
        description: "Sidebar with brand header and account footer",
        attributes: %{id: "sb-sidebar-header-footer", class: "h-96"},
        slots: [
          "<:header><span class=\"font-semibold\">Acme</span></:header>",
          nav,
          "<:footer><span class=\"text-sm text-muted-foreground\">Signed in</span></:footer>"
        ]
      },
      %Variation{
        id: :outline_primary,
        description: "Outline primary surface",
        attributes: %{id: "sb-sidebar-outline-primary", variant: "outline", color: "primary", class: "h-96"},
        slots: [nav]
      },
      %Variation{
        id: :elevated,
        description: "Elevated surface with shadow",
        attributes: %{id: "sb-sidebar-elevated", variant: "elevated", class: "h-96"},
        slots: [nav]
      },
      %Variation{
        id: :icon_collapsible,
        description: "Collapses to an icon rail on desktop",
        attributes: %{id: "sb-sidebar-icon-collapsible", collapsible: "icon", class: "h-96"},
        slots: [nav]
      },
      %Variation{
        id: :right_side,
        description: "Anchored to the right edge",
        attributes: %{id: "sb-sidebar-right-side", side: "right", class: "h-96"},
        slots: [nav]
      }
    ]
  end
end
