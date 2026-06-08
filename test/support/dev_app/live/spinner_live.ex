defmodule Pulsar.DevApp.SpinnerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Spinner

  @variants ~w(ring dots bars)
  @colors ~w(current neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="spinner" title="Spinner">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Spinner.spinner
            variant={variant}
            color={color}
            size={size}
            label={"#{variant} #{color} #{size}"}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          />
        <% end %>
      </.fixture_section>
      <.fixture_section name="decorative" title="Decorative (aria-hidden)">
        <Spinner.spinner variant="ring" decorative data-fixture-cell="decorative" />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
