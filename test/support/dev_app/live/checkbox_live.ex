defmodule Pulsar.DevApp.CheckboxLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Checkbox

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @states [
    {"unchecked", []},
    {"checked", [checked: true]},
    {"indeterminate", [indeterminate: true]},
    {"disabled", [disabled: true]},
    {"invalid", [invalid: true]}
  ]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes, states: @states)

    ~H"""
    <.fixture_page name="checkbox" title="Checkbox">
      <.fixture_section name="matrix" title="Color × size × state">
        <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
          <Checkbox.checkbox
            id={"chk-#{color}-#{size}-#{state_label}"}
            name={"chk_#{color}_#{size}_#{state_label}"}
            color={color}
            size={size}
            value="1"
            aria-label={"#{color} #{size} #{state_label}"}
            data-fixture-cell={"#{color}-#{size}-#{state_label}"}
            {state_attrs}
          />
        <% end %>
      </.fixture_section>
      <.fixture_section name="card" title="Card variant">
        <Checkbox.checkbox
          id="chk-card-1"
          name="chk_card_1"
          card
          color="primary"
          value="1"
          data-fixture-cell="card-default"
        >
          Card option label
        </Checkbox.checkbox>
        <Checkbox.checkbox
          id="chk-card-2"
          name="chk_card_2"
          card
          color="primary"
          checked
          value="1"
          data-fixture-cell="card-checked"
        >
          Card option (checked)
        </Checkbox.checkbox>
        <Checkbox.checkbox
          id="chk-card-3"
          name="chk_card_3"
          card
          hide_checkbox
          color="primary"
          value="1"
          data-fixture-cell="card-hidden-checkbox"
        >
          Card with hidden checkbox
        </Checkbox.checkbox>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
