defmodule Pulsar.DevApp.NavbarLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Navbar

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="navbar" title="Navbar">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Navbar.navbar
          :for={color <- @colors}
          id={"nb-#{variant}-#{color}"}
          variant={variant}
          color={color}
          size="md"
          label={"#{variant} #{color}"}
          data-fixture-cell={"#{variant}-#{color}"}
        >
          <:left><span class="font-semibold">Acme</span></:left>
          <:right>
            <button type="button" class="rounded-field px-2 py-1.5 hover:bg-foreground/10">
              Account
            </button>
          </:right>
        </Navbar.navbar>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <Navbar.navbar
          :for={size <- @sizes}
          id={"nb-size-#{size}"}
          variant="solid"
          color="neutral"
          size={size}
          label={"size #{size}"}
          data-fixture-cell={"size-#{size}"}
        >
          <:left>size {size}</:left>
        </Navbar.navbar>
      </.fixture_section>

      <.fixture_section name="menu-button" title="menu button">
        <Navbar.navbar
          id="nb-menu"
          variant="solid"
          color="neutral"
          size="md"
          label="with menu button"
          on_menu_toggle={JS.dispatch("pulsar:sidebar-toggle", to: "#nb-menu-target")}
          menu_controls="nb-menu-target"
          data-fixture-cell="menu-button"
        >
          <:left><span class="font-semibold">Acme</span></:left>
        </Navbar.navbar>
        <nav id="nb-menu-target" aria-label="Demo sidebar" hidden></nav>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
