defmodule Pulsar.DevApp.Keyboard.CardLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.Card` in its interactive
  pseudo-button mode (triggered by presence of `phx-click` in `:rest`).
  Exercises the `.PulsarCard` colocated hook's Space/Enter → click dispatch.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Card

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("bump", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-card" title="Card keyboard fixture">
      <p>Activation counter: <span id="kbd-count">{@count}</span></p>

      <.fixture_section name="active" title="Interactive card">
        <Card.card id="kbd-card" class="w-64" phx-click="bump">
          <:header>
            <h3 class="font-semibold">Activate me</h3>
          </:header>
          <p class="text-sm">Press Space or Enter while focused.</p>
        </Card.card>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
