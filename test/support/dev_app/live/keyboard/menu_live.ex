defmodule Pulsar.DevApp.Keyboard.MenuLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Menu

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-menu-before" type="button">before</button>

      <Menu.menu id="kbd-vmenu" label="Vertical" class="w-64">
        <Menu.menu_item id="kbd-v-home" href="#">Home</Menu.menu_item>
        <Menu.menu_item id="kbd-v-inbox" href="#">Inbox</Menu.menu_item>
        <Menu.menu_group id="kbd-v-grp" label="Reports">
          <Menu.menu_item id="kbd-v-sales" href="#">Sales</Menu.menu_item>
        </Menu.menu_group>
      </Menu.menu>

      <Menu.menu id="kbd-hmenu" orientation="horizontal" label="Horizontal">
        <Menu.menu_item id="kbd-h-home" href="#">Home</Menu.menu_item>
        <Menu.menu_group id="kbd-h-grp" orientation="horizontal" label="Products">
          <Menu.menu_item id="kbd-h-app" href="#">App</Menu.menu_item>
        </Menu.menu_group>
      </Menu.menu>
    </main>
    """
  end
end
