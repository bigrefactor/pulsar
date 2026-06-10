defmodule Pulsar.DevApp.DrawerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Drawer

  @sides ~w(right left top bottom)
  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(sm md lg xl)

  def render(assigns) do
    assigns =
      assign(assigns, sides: @sides, variants: @variants, colors: @colors, sizes: @sizes)

    # These cells are a static showcase (`open`, in flow), not live openings, so
    # `style="animation: none"` suppresses the slide entrance and `class="static
    # m-0 w-72"` keeps the panel in flow. Without it the axe gate can scan
    # mid-slide and composite the panel text against the page, producing flaky
    # false sub-4.5:1 contrast readings; the settled colors pass AA.
    ~H"""
    <.fixture_page name="drawer" title="Drawer">
      <.fixture_section name="sides" title="sides">
        <Drawer.drawer
          :for={side <- @sides}
          id={"drawer-side-#{side}"}
          side={side}
          title={"side #{side}"}
          open
          style="animation: none"
          class="static m-0 w-72"
          data-fixture-cell={"side-#{side}"}
        >
          Panel content for the {side} drawer.
        </Drawer.drawer>
      </.fixture_section>

      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Drawer.drawer
          :for={color <- @colors}
          id={"drawer-#{variant}-#{color}"}
          variant={variant}
          color={color}
          title={"#{variant} #{color}"}
          open
          style="animation: none"
          class="static m-0 w-72"
          data-fixture-cell={"#{variant}-#{color}"}
        >
          <:description>Panel body for {variant} {color}.</:description>
          Panel content.
          <:footer>
            <button type="button" class="rounded-field border border-border px-3 py-1.5 text-sm">
              Close
            </button>
          </:footer>
        </Drawer.drawer>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <Drawer.drawer
          :for={size <- @sizes}
          id={"drawer-size-#{size}"}
          size={size}
          title={"size #{size}"}
          open
          style="animation: none"
          class="static m-0 w-72"
          data-fixture-cell={"size-#{size}"}
        >
          Panel content.
        </Drawer.drawer>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
