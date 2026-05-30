defmodule Pulsar.DevApp.IconLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Icon

  # Heroicon names are full classes including the variant suffix. The lists are
  # spelled out as literals (not assembled from a suffix at runtime) so Tailwind
  # detects every class and generates its mask CSS.
  @variant_groups [
    {"outline", ~w(hero-bolt hero-check hero-exclamation-triangle hero-information-circle hero-x-mark)},
    {"solid",
     ~w(hero-bolt-solid hero-check-solid hero-exclamation-triangle-solid hero-information-circle-solid hero-x-mark-solid)},
    {"mini",
     ~w(hero-bolt-mini hero-check-mini hero-exclamation-triangle-mini hero-information-circle-mini hero-x-mark-mini)},
    {"micro",
     ~w(hero-bolt-micro hero-check-micro hero-exclamation-triangle-micro hero-information-circle-micro hero-x-mark-micro)}
  ]
  @sizes ~w(xs sm md lg xl)
  @colors ~w(neutral primary secondary success danger warning)

  def render(assigns) do
    assigns =
      assign(assigns,
        variant_groups: @variant_groups,
        sizes: @sizes,
        colors: @colors
      )

    ~H"""
    <.fixture_page name="icon" title="Icon">
      <.fixture_section
        :for={{variant, names} <- @variant_groups}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for name <- names, size <- @sizes do %>
          <Icon.icon
            name={name}
            size={size}
            data-fixture-cell={"#{variant}-#{name}-#{size}"}
          />
        <% end %>
      </.fixture_section>
      <.fixture_section name="colors" title="Color tokens">
        <%= for color <- @colors do %>
          <Icon.icon
            name="hero-bolt"
            color={color}
            data-fixture-cell={"color-#{color}"}
          />
        <% end %>
      </.fixture_section>
      <.fixture_section name="aria" title="Decorative vs labelled">
        <Icon.icon name="hero-bolt" aria_hidden="true" data-fixture-cell="aria-hidden" />
        <Icon.icon name="hero-bolt" aria_label="Power bolt" data-fixture-cell="aria-label" />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
