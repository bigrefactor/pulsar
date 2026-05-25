defmodule Pulsar.TestApp.SwitchLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Switch

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @states [
    {"unchecked", []},
    {"checked", [checked: true]},
    {"loading", [loading: true]},
    {"disabled", [disabled: true]},
    {"invalid", [invalid: true]}
  ]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes, states: @states)

    ~H"""
    <.fixture_page name="switch" title="Switch">
      <.fixture_section name="matrix" title="Color × size × state">
        <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
          <Switch.switch
            id={"sw-#{color}-#{size}-#{state_label}"}
            name={"sw_#{color}_#{size}_#{state_label}"}
            color={color}
            size={size}
            value="1"
            aria_label={"#{color} #{size} #{state_label}"}
            data-fixture-cell={"#{color}-#{size}-#{state_label}"}
            {state_attrs}
          />
        <% end %>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
