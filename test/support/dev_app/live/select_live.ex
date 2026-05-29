defmodule Pulsar.DevApp.SelectLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Select

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]
  @states [
    {"default", []},
    {"required", [required: true]},
    {"disabled", [disabled: true]},
    {"invalid", [invalid: true]}
  ]

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns =
      assign(assigns,
        variant: variant,
        colors: @colors,
        sizes: @sizes,
        options: @options,
        states: @states
      )

    ~H"""
    <.fixture_page name={"select-#{@variant}"} title={"Select (#{@variant})"}>
      <.fixture_section name={"variant-#{@variant}"} title={"variant: #{@variant}"}>
        <div class="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3 w-full">
          <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
            <Select.select
              id={"sel-#{@variant}-#{color}-#{size}-#{state_label}"}
              name={"sel_#{@variant}_#{color}_#{size}_#{state_label}"}
              variant={@variant}
              color={color}
              size={size}
              options={@options}
              prompt="Choose…"
              aria-label={"#{@variant} #{color} #{size} #{state_label}"}
              data-fixture-cell={"#{@variant}-#{color}-#{size}-#{state_label}"}
              {state_attrs}
            />
          <% end %>
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
