defmodule Pulsar.DevApp.Keyboard.TooltipLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Button
  alias Pulsar.Components.Tooltip

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("bump", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

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

      <button id="kbd-tip-patch-bump" type="button" phx-click="bump">bump</button>

      <Tooltip.tooltip id="kbd-tip-patch">
        <:trigger>
          <Button.button id="kbd-tip-patch-trigger">Patched {@count}</Button.button>
        </:trigger>
        Saves your patched changes
      </Tooltip.tooltip>
    </main>
    """
  end
end
