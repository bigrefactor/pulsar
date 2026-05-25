defmodule Pulsar.DevApp.IconLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Icon

  @icon_variants ~w(outline solid mini micro)
  @sizes ~w(xs sm md lg xl)
  @colors ~w(neutral primary secondary success danger warning)
  @names ~w(hero-bolt hero-check hero-exclamation-triangle hero-information-circle hero-x-mark)

  def render(assigns) do
    assigns =
      assign(assigns,
        icon_variants: @icon_variants,
        sizes: @sizes,
        colors: @colors,
        names: @names
      )

    ~H"""
    <.fixture_page name="icon" title="Icon">
      <.fixture_section
        :for={variant <- @icon_variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for name <- @names, size <- @sizes do %>
          <Icon.icon
            name={name}
            variant={variant}
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
