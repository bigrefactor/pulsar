defmodule Pulsar.DevApp.Storybook.Components.Drawer do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Drawer

  def function, do: &Drawer.drawer/1
  def render_source, do: :function

  # Each variation renders "in use": clicking the trigger opens the drawer as a
  # real focus-trapped dialog (showModal + backdrop + slide). The drawer
  # auto-generates its id, so the wrapper dispatches the open event to the inner
  # dialog via `{:inner, "dialog"}` (PSB doesn't substitute :variation_id into
  # component attrs).
  def template do
    """
    <div class="flex min-h-48 items-center justify-center p-8" psb-code-hidden>
      <div
        phx-click={Phoenix.LiveView.JS.dispatch("pulsar:modal-open", to: {:inner, "dialog"})}
        class="inline-block"
      >
        <button
          type="button"
          class="rounded-field bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-ring"
        >
          Open drawer
        </button>
        <.psb-variation/>
      </div>
    </div>
    """
  end

  def attributes do
    [
      %Attr{
        id: :side,
        type: :string,
        values: ~w(right left top bottom),
        default: "right",
        doc: "Viewport edge the panel anchors to and slides in from"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(sm md lg xl),
        default: "md",
        doc: "Width for left/right drawers, height for top/bottom drawers"
      },
      %Attr{
        id: :title,
        type: :string,
        default: nil,
        doc: "Heading text; wired as the panel's accessible name"
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
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the panel"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, required: true, doc: "Drawer body"}
    ]
  end

  def variations do
    body = "Panel content — detail pane, navigation, or filters live here."

    [
      %Variation{
        id: :right,
        description: "Right-anchored (default)",
        attributes: %{side: "right", title: "Details"},
        slots: [body]
      },
      %Variation{
        id: :left,
        description: "Left-anchored — mobile nav",
        attributes: %{side: "left", title: "Navigation"},
        slots: [body]
      },
      %Variation{
        id: :top,
        description: "Top-anchored sheet",
        attributes: %{side: "top", title: "Notifications"},
        slots: [body]
      },
      %Variation{
        id: :bottom,
        description: "Bottom-anchored sheet",
        attributes: %{side: "bottom", title: "Actions"},
        slots: [body]
      },
      %Variation{
        id: :large_filters,
        description: "Large right drawer for filters",
        attributes: %{side: "right", size: "xl", title: "Filters", variant: "solid", color: "primary"},
        slots: [body]
      }
    ]
  end
end
