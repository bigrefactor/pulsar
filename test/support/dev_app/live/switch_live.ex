defmodule Pulsar.DevApp.SwitchLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

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
          <%!-- The cell wraps the switch so it bounds the visible 24px hit box
                rather than the sr-only input (which measures 0×0). --%>
          <span class="inline-flex" data-fixture-cell={"#{color}-#{size}-#{state_label}"}>
            <Switch.switch
              id={"sw-#{color}-#{size}-#{state_label}"}
              name={"sw_#{color}_#{size}_#{state_label}"}
              color={color}
              size={size}
              value="1"
              aria_label={"#{color} #{size} #{state_label}"}
              {state_attrs}
            />
          </span>
        <% end %>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
