defmodule Pulsar.DevApp.PopoverLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Popover

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @placements ~w(top bottom left right)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, placements: @placements)

    ~H"""
    <.fixture_page name="popover" title="Popover">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Popover.popover
          :for={color <- @colors}
          id={"pop-#{variant}-#{color}"}
          variant={variant}
          color={color}
        >
          <:trigger>
            <button
              type="button"
              class="rounded border border-border px-3 py-1.5 text-sm"
            >
              {variant} {color}
            </button>
          </:trigger>
          <p class="text-sm">{variant} {color} panel</p>
        </Popover.popover>
      </.fixture_section>

      <.fixture_section name="placements" title="placements">
        <Popover.popover
          :for={placement <- @placements}
          id={"pop-place-#{placement}"}
          placement={placement}
        >
          <:trigger>
            <button
              type="button"
              class="rounded border border-border px-3 py-1.5 text-sm"
            >
              {placement}
            </button>
          </:trigger>
          <p class="text-sm">Anchored {placement}</p>
        </Popover.popover>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
