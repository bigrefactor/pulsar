defmodule Pulsar.DevApp.Keyboard.TooltipLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Tooltip

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-tip-before" type="button">before</button>

      <Tooltip.tooltip id="kbd-tip">
        <:trigger>
          <button id="kbd-tip-trigger" type="button">Help</button>
        </:trigger>
        Saves your changes
      </Tooltip.tooltip>

      <button id="kbd-tip-after" type="button">after</button>
    </main>
    """
  end
end
