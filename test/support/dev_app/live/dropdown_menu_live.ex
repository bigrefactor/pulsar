defmodule Pulsar.DevApp.DropdownMenuLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.DropdownMenu

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors)

    ~H"""
    <.fixture_page name="dropdown_menu" title="DropdownMenu">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <DropdownMenu.dropdown_menu
          :for={color <- @colors}
          id={"dm-#{variant}-#{color}"}
          label={"#{variant} #{color} menu"}
          variant={variant}
          color={color}
        >
          <:trigger>
            <button
              type="button"
              class="rounded border border-border px-3 py-1.5 text-sm"
              data-fixture-cell={"#{variant}-#{color}"}
            >
              {variant} {color}
            </button>
          </:trigger>
          <DropdownMenu.dropdown_menu_item icon="hero-user" href="#">Profile</DropdownMenu.dropdown_menu_item>
          <DropdownMenu.dropdown_menu_item href="#">Settings</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
      </.fixture_section>

      <.fixture_section name="features" title="all parts">
        <DropdownMenu.dropdown_menu id="dm-features" label="Full menu">
          <:trigger>
            <button type="button" class="rounded border border-border px-3 py-1.5 text-sm">
              Full menu
            </button>
          </:trigger>

          <DropdownMenu.dropdown_menu_label>Signed in as Ada</DropdownMenu.dropdown_menu_label>
          <DropdownMenu.dropdown_menu_item icon="hero-user" href="#">
            Profile
            <:trailing>⌘P</:trailing>
          </DropdownMenu.dropdown_menu_item>
          <DropdownMenu.dropdown_menu_item disabled>Archived (disabled)</DropdownMenu.dropdown_menu_item>

          <DropdownMenu.dropdown_menu_separator />

          <DropdownMenu.dropdown_menu_group label="View">
            <DropdownMenu.dropdown_menu_checkbox_item checked>Show grid</DropdownMenu.dropdown_menu_checkbox_item>
            <DropdownMenu.dropdown_menu_checkbox_item>Show ruler</DropdownMenu.dropdown_menu_checkbox_item>
          </DropdownMenu.dropdown_menu_group>

          <DropdownMenu.dropdown_menu_separator />

          <DropdownMenu.dropdown_menu_radio_group label="Sort by">
            <DropdownMenu.dropdown_menu_radio_item checked>Name</DropdownMenu.dropdown_menu_radio_item>
            <DropdownMenu.dropdown_menu_radio_item>Date modified</DropdownMenu.dropdown_menu_radio_item>
          </DropdownMenu.dropdown_menu_radio_group>

          <DropdownMenu.dropdown_menu_separator />

          <DropdownMenu.dropdown_menu_submenu id="dm-features-share" label="Share" icon="hero-share">
            <DropdownMenu.dropdown_menu_item href="#">Email</DropdownMenu.dropdown_menu_item>
            <DropdownMenu.dropdown_menu_item href="#">Copy link</DropdownMenu.dropdown_menu_item>
          </DropdownMenu.dropdown_menu_submenu>

          <DropdownMenu.dropdown_menu_separator />

          <DropdownMenu.dropdown_menu_item color="primary" icon="hero-star" phx-click="noop">
            Upgrade plan
          </DropdownMenu.dropdown_menu_item>
          <DropdownMenu.dropdown_menu_item color="warning" icon="hero-exclamation-triangle" phx-click="noop">
            Archive
          </DropdownMenu.dropdown_menu_item>
          <DropdownMenu.dropdown_menu_item color="danger" icon="hero-trash" phx-click="noop">
            Delete
          </DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
      </.fixture_section>
    </.fixture_page>
    """
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}
end
