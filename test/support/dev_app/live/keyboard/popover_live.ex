defmodule Pulsar.DevApp.Keyboard.PopoverLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Popover

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
    </main>
    """
  end
end
