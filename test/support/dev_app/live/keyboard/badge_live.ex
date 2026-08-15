defmodule Pulsar.DevApp.Keyboard.BadgeLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Badge
  alias Pulsar.Components.Popover

  def mount(_params, _session, socket), do: {:ok, assign(socket, removed: false)}

  def handle_event("remove", _params, socket), do: {:noreply, assign(socket, removed: true)}

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-badge-before" type="button">before</button>

      <Badge.badge
        :if={!@removed}
        id="kbd-badge"
        as={:div}
        on_remove={JS.push("remove")}
        remove_label="Remove filter Status"
      >
        <Popover.popover id="kbd-badge-panel">
          <:trigger>
            <button id="kbd-badge-trigger" type="button">Status: Published</button>
          </:trigger>
          <a id="kbd-badge-inside" href="#">Edit filter</a>
        </Popover.popover>
      </Badge.badge>

      <button id="kbd-badge-after" type="button">after</button>
    </main>
    """
  end
end
