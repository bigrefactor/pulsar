defmodule Pulsar.DevApp.Keyboard.DropdownMenuLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.DropdownMenu

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-dm-before" type="button">before</button>

      <DropdownMenu.dropdown_menu id="kbd-dm" label="Actions">
        <:trigger>
          <button id="kbd-dm-trigger" type="button">Open menu</button>
        </:trigger>

        <DropdownMenu.dropdown_menu_item id="kbd-dm-profile" href="#">Profile</DropdownMenu.dropdown_menu_item>
        <DropdownMenu.dropdown_menu_item id="kbd-dm-settings" href="#">Settings</DropdownMenu.dropdown_menu_item>
        <DropdownMenu.dropdown_menu_submenu id="kbd-dm-sub" label="Share">
          <DropdownMenu.dropdown_menu_item id="kbd-dm-email" href="#">Email</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu_submenu>
      </DropdownMenu.dropdown_menu>

      <button id="kbd-dm-after" type="button">after</button>
    </main>
    """
  end
end
