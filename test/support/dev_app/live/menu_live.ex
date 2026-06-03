defmodule Pulsar.DevApp.MenuLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Menu

  def render(assigns) do
    ~H"""
    <.fixture_page name="menu" title="Menu">
      <.fixture_section name="vertical" title="vertical">
        <Menu.menu id="menu-vertical" label="Vertical" class="w-64" data-fixture-cell="vertical">
          <Menu.menu_item href="#" icon="hero-home" active data-fixture-cell="active-item">
            Home
          </Menu.menu_item>
          <Menu.menu_item href="#" icon="hero-inbox" data-fixture-cell="item">
            Inbox
            <:trailing>9</:trailing>
          </Menu.menu_item>

          <Menu.menu_section id="menu-vertical-ws" label="Workspace">
            <Menu.menu_item href="#" icon="hero-folder" data-fixture-cell="section-item">
              Projects
            </Menu.menu_item>
            <Menu.menu_group
              id="menu-vertical-reports"
              label="Reports"
              icon="hero-chart-bar"
              open
              data-fixture-cell="group-open"
            >
              <Menu.menu_item href="#">Sales</Menu.menu_item>
              <Menu.menu_item href="#">Traffic</Menu.menu_item>
            </Menu.menu_group>
            <Menu.menu_group
              id="menu-vertical-admin"
              label="Admin"
              icon="hero-lock-closed"
              data-fixture-cell="group-closed"
            >
              <Menu.menu_item href="#">Users</Menu.menu_item>
            </Menu.menu_group>
          </Menu.menu_section>
        </Menu.menu>
      </.fixture_section>

      <.fixture_section name="horizontal" title="horizontal">
        <Menu.menu
          id="menu-horizontal"
          orientation="horizontal"
          label="Horizontal"
          data-fixture-cell="horizontal"
        >
          <Menu.menu_item href="#" active data-fixture-cell="h-active-item">Home</Menu.menu_item>
          <Menu.menu_item href="#" data-fixture-cell="h-item">Pricing</Menu.menu_item>
          <Menu.menu_group
            id="menu-horizontal-products"
            orientation="horizontal"
            label="Products"
            data-fixture-cell="h-group"
          >
            <Menu.menu_item href="#">App</Menu.menu_item>
            <Menu.menu_item href="#">API</Menu.menu_item>
          </Menu.menu_group>
        </Menu.menu>
      </.fixture_section>

      <.fixture_section name="icon-rail" title="collapsed icon rail">
        <div class="group/sidebar" data-state="collapsed" data-collapsible="icon">
          <Menu.menu id="menu-rail" landmark={false} label="Rail" class="w-16" data-fixture-cell="rail">
            <Menu.menu_item href="#" icon="hero-home" active data-fixture-cell="rail-active">
              Home
            </Menu.menu_item>
            <Menu.menu_item href="#" icon="hero-inbox" data-fixture-cell="rail-item">Inbox</Menu.menu_item>
          </Menu.menu>
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
