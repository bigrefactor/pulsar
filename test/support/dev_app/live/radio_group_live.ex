defmodule Pulsar.DevApp.RadioGroupLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.RadioGroup

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes, options: @options)

    ~H"""
    <.fixture_page name="radio_group" title="RadioGroup">
      <.fixture_section name="matrix" title="Color × size">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 w-full">
          <%= for color <- @colors, size <- @sizes do %>
            <RadioGroup.radio_group
              id={"rg-#{color}-#{size}"}
              name={"rg_#{color}_#{size}"}
              color={color}
              size={size}
              data-fixture-cell={"#{color}-#{size}"}
            >
              <:option :for={{label, value} <- @options} value={value}>{label}</:option>
            </RadioGroup.radio_group>
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="card" title="Card variant">
        <RadioGroup.radio_group
          id="rg-card"
          name="rg_card"
          card
          color="primary"
          data-fixture-cell="card"
        >
          <:option :for={{label, value} <- @options} value={value}>{label}</:option>
        </RadioGroup.radio_group>
      </.fixture_section>
      <.fixture_section name="orientation-horizontal" title="Horizontal orientation">
        <RadioGroup.radio_group
          id="rg-horiz"
          name="rg_horiz"
          orientation="horizontal"
          color="primary"
          data-fixture-cell="horizontal"
        >
          <:option :for={{label, value} <- @options} value={value}>{label}</:option>
        </RadioGroup.radio_group>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
