defmodule Pulsar.DevApp.SpinnerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Spinner

  @colors ~w(current neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="spinner" title="Spinner">
      <.fixture_section name="colors-and-sizes" title="Colors and sizes">
        <%= for color <- @colors, size <- @sizes do %>
          <Spinner.spinner
            color={color}
            size={size}
            label={"#{color} #{size}"}
            data-fixture-cell={"#{color}-#{size}"}
          />
        <% end %>
      </.fixture_section>
      <.fixture_section name="decorative" title="Decorative (aria-hidden)">
        <Spinner.spinner decorative data-fixture-cell="decorative" />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
