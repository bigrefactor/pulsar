defmodule Pulsar.DevApp.Keyboard.DrawerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Drawer

  # Mirrors the storybook drawer template: the trigger and the drawer live
  # inside a single element carrying the open dispatcher. A backdrop click on
  # the open dialog bubbles up to this wrapper, so without the modal hook
  # swallowing that click the drawer would close and immediately re-open —
  # the "clicking outside does nothing" bug this fixture guards against.
  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <div id="kbd-drawer-wrap" phx-click={Drawer.open("kbd-drawer")} class="inline-block">
        <button id="kbd-drawer-open" type="button">Open drawer</button>

        <Drawer.drawer id="kbd-drawer" side="right" title="Filters">
          <input id="kbd-drawer-input" type="text" autofocus />
        </Drawer.drawer>
      </div>
    </main>
    """
  end
end
