defmodule Pulsar.DevApp.InputLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Input

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @states [
    {"default", []},
    {"required", [required: true]},
    {"readonly", [readonly: true, value: "read only"]},
    {"disabled", [disabled: true, value: "disabled"]},
    {"invalid", [invalid: true]}
  ]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :demo))}
  end

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns =
      assign(assigns, variant: variant, colors: @colors, sizes: @sizes, states: @states)

    ~H"""
    <.fixture_page name={"input-#{@variant}"} title={"Input (#{@variant})"}>
      <.fixture_section name={"variant-#{@variant}"} title={"variant: #{@variant}"}>
        <div class="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3 w-full">
          <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
            <Input.input
              id={"in-#{@variant}-#{color}-#{size}-#{state_label}"}
              name={"in_#{@variant}_#{color}_#{size}_#{state_label}"}
              variant={@variant}
              color={color}
              size={size}
              placeholder={"#{color}/#{size}/#{state_label}"}
              data-fixture-cell={"#{@variant}-#{color}-#{size}-#{state_label}"}
              {state_attrs}
            />
          <% end %>
        </div>
      </.fixture_section>
      <%= if @live_action == :outline do %>
        <.fixture_section name="decorators" title="Decorators">
          <Input.input
            id="in-decor"
            name="in_decor"
            placeholder="With decorators"
            data-fixture-cell="decorators"
          >
            <:start_decorator>$</:start_decorator>
            <:end_decorator>.00</:end_decorator>
          </Input.input>
        </.fixture_section>
      <% end %>
    </.fixture_page>
    """
  end
end
