defmodule Pulsar.TestApp.ButtonLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Button

  @variants ~w(solid outline ghost link)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @states [
    {"default", []},
    {"disabled", [disabled: true]},
    {"loading", [loading: true]},
    {"pressed", [pressed: true]}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        variants: @variants,
        colors: @colors,
        sizes: @sizes,
        states: @states
      )

    ~H"""
    <.fixture_page name="button" title="Button">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
          <Button.button
            variant={variant}
            color={color}
            size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}-#{state_label}"}
            {state_attrs}
          >
            {color}/{size}/{state_label}
          </Button.button>
        <% end %>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
