defmodule Pulsar.DevApp.Keyboard.DropdownMenuLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.DropdownMenu

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <h1 class="text-lg font-semibold">DropdownMenu keyboard fixture</h1>
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

        <%!-- One item per non-neutral color, so an open-menu axe scan gates the
          contrast of every color's item text. Kept after the submenu so the
          roving-focus tests above (profile → settings → sub-trigger) are
          unaffected. --%>
        <DropdownMenu.dropdown_menu_item
          :for={color <- ~w(primary secondary success danger warning info)}
          id={"kbd-dm-color-#{color}"}
          color={color}
          href="#"
        >
          {color} action
        </DropdownMenu.dropdown_menu_item>
      </DropdownMenu.dropdown_menu>

      <button id="kbd-dm-after" type="button">after</button>
    </main>
    """
  end
end
