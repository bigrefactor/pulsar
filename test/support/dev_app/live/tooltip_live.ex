defmodule Pulsar.DevApp.TooltipLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Tooltip

  @colors ~w(neutral primary secondary success danger warning info)
  @placements ~w(top bottom left right)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, placements: @placements)

    ~H"""
    <.fixture_page name="tooltip" title="Tooltip">
      <.fixture_section name="colors" title="colors">
        <Tooltip.tooltip :for={color <- @colors} id={"tip-#{color}"} color={color}>
          <:trigger>
            <button type="button" class="rounded border border-border px-3 py-1.5 text-sm">
              {color}
            </button>
          </:trigger>
          {color} hint
        </Tooltip.tooltip>
      </.fixture_section>

      <.fixture_section name="placements" title="placements">
        <Tooltip.tooltip
          :for={placement <- @placements}
          id={"tip-place-#{placement}"}
          placement={placement}
        >
          <:trigger>
            <button type="button" class="rounded border border-border px-3 py-1.5 text-sm">
              {placement}
            </button>
          </:trigger>
          Anchored {placement}
        </Tooltip.tooltip>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
