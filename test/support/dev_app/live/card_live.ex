defmodule Pulsar.DevApp.CardLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Card

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(sm md lg)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="card" title="Card">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Card.card
            variant={variant}
            color={color}
            size={size}
            class="w-64"
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          >
            <:header>
              <h3 class="font-semibold">{color} / {size}</h3>
            </:header>
            <p class="text-sm">Body content for the {variant} card.</p>
            <:footer>
              <span class="text-xs text-muted-foreground">Footer slot</span>
            </:footer>
          </Card.card>
        <% end %>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
