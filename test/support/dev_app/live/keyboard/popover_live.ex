defmodule Pulsar.DevApp.Keyboard.PopoverLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Button
  alias Pulsar.Components.Popover

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("bump", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-pop-before" type="button">before</button>

      <Popover.popover id="kbd-pop">
        <:trigger>
          <button id="kbd-pop-trigger" type="button">Open popover</button>
        </:trigger>
        <a id="kbd-pop-inside" href="#">Inside link</a>
      </Popover.popover>

      <button id="kbd-pop-after" type="button">after</button>

      <button id="kbd-pop-patch-bump" type="button" phx-click="bump">bump</button>

      <Popover.popover id="kbd-pop-patch">
        <:trigger>
          <Button.button id="kbd-pop-patch-trigger">Patched {@count}</Button.button>
        </:trigger>
        <a id="kbd-pop-patch-inside" href="#">Inside patched link</a>
      </Popover.popover>
    </main>
    """
  end
end
