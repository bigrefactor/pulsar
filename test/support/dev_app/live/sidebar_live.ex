defmodule Pulsar.DevApp.SidebarLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Menu
  alias Pulsar.Components.Sidebar

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  # The sidebar is normally a full-height, fixed/off-canvas panel. The axe and
  # reflow gates only care about its colors and content, so positioning is
  # neutralized here (`relative`, no transform) and the box is bounded, letting
  # the cells tile in the fixture grid at both 1280px and 320px viewports.
  @cell "relative !translate-x-0 h-44 w-40"

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes, cell: @cell)

    ~H"""
    <.fixture_page name="sidebar" title="Sidebar">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Sidebar.sidebar
          :for={color <- @colors}
          id={"sb-#{variant}-#{color}"}
          variant={variant}
          color={color}
          size="md"
          label={"#{variant} #{color}"}
          class={@cell}
          data-fixture-cell={"#{variant}-#{color}"}
        >
          <:header>
            <span class="text-sm font-semibold">Acme</span>
          </:header>
          <.demo_menu label={"#{variant} #{color} nav"} />
          <:footer>
            <span class="text-xs">Signed in</span>
          </:footer>
        </Sidebar.sidebar>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <Sidebar.sidebar
          :for={size <- @sizes}
          id={"sb-size-#{size}"}
          variant="solid"
          color="neutral"
          size={size}
          label={"size #{size}"}
          class={@cell}
          data-fixture-cell={"size-#{size}"}
        >
          <.demo_menu label={"size #{size} nav"} />
        </Sidebar.sidebar>
      </.fixture_section>

      <.fixture_section name="sides" title="sides">
        <Sidebar.sidebar
          :for={side <- ~w(left right)}
          id={"sb-side-#{side}"}
          side={side}
          variant="solid"
          color="neutral"
          size="md"
          label={"side #{side}"}
          class={@cell}
          data-fixture-cell={"side-#{side}"}
        >
          <.demo_menu label={"side #{side} nav"} />
        </Sidebar.sidebar>
      </.fixture_section>
    </.fixture_page>
    """
  end

  # A compact Menu instance dogfooding PUL-103 inside the sidebar's content slot.
  # `landmark={false}` so it doesn't nest a second <nav> inside the sidebar's own
  # landmark.
  attr :label, :string, required: true

  defp demo_menu(assigns) do
    ~H"""
    <Menu.menu landmark={false} label={@label}>
      <Menu.menu_item href="#" icon="hero-home" active>Home</Menu.menu_item>
      <Menu.menu_item href="#" icon="hero-chart-bar">Reports</Menu.menu_item>
    </Menu.menu>
    """
  end
end
