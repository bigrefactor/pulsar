defmodule Pulsar.DevApp.LinkLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Link

  @variants ~w(solid outline ghost link)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="link" title="Link">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Link.a
            href="#"
            variant={variant}
            color={color}
            size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          >
            {color}/{size}
          </Link.a>
        <% end %>
      </.fixture_section>
      <.fixture_section name="external" title="External (auto rel/target)">
        <Link.a href="https://example.com" data-fixture-cell="external">
          External link
        </Link.a>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
