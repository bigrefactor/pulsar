defmodule Pulsar.DevApp.BadgeLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Badge

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="badge" title="Badge">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Badge.badge
            variant={variant}
            color={color}
            size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          >
            {color}/{size}
          </Badge.badge>
        <% end %>
      </.fixture_section>
      <.fixture_section name="addons" title="With start and end addons">
        <Badge.badge variant="solid" color="primary" data-fixture-cell="addons-both">
          <:start_addon>•</:start_addon>
          With addons
          <:end_addon>×</:end_addon>
        </Badge.badge>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
