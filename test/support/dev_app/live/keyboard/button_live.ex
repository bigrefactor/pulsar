defmodule Pulsar.DevApp.Keyboard.ButtonLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.Button`.

  Renders pseudo-buttons (`as: :div` → `<div role="button">`) so the test
  exercises the `.PulsarButton` colocated hook's Space/Enter handlers. A
  native `<button>` would activate even without the hook (browser default),
  which would defeat the verification step described in the keyboard-test
  suite.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Button

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("bump", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-button" title="Button keyboard fixture">
      <p>Activation counter: <span id="kbd-count">{@count}</span></p>

      <.fixture_section name="active" title="Active pseudo-button">
        <Button.button as={:div} id="kbd-button-link" phx-click="bump">
          Activate
        </Button.button>
      </.fixture_section>

      <.fixture_section name="disabled" title="Disabled pseudo-button">
        <Button.button as={:div} id="kbd-button-disabled" disabled phx-click="bump">
          Disabled
        </Button.button>
      </.fixture_section>

      <.fixture_section name="loading" title="Loading pseudo-button">
        <Button.button as={:div} id="kbd-button-loading" loading phx-click="bump">
          Loading
        </Button.button>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
