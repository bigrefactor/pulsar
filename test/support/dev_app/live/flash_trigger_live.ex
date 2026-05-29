defmodule Pulsar.DevApp.FlashTriggerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Flash

  def mount(_p, _s, socket) do
    {:ok, assign(socket, show_status: false, show_alert: false, show_persistent: false)}
  end

  def handle_event("show_status", _, socket), do: {:noreply, assign(socket, show_status: true)}

  def handle_event("show_alert", _, socket), do: {:noreply, assign(socket, show_alert: true)}

  def handle_event("show_persistent", _, socket), do: {:noreply, assign(socket, show_persistent: true)}

  def render(assigns) do
    ~H"""
    <.fixture_page name="flash_trigger" title="Flash (trigger)">
      <.fixture_section name="status" title="Status flash (polite)">
        <button id="trigger-status" type="button" phx-click="show_status">
          Show status flash
        </button>
        <Flash.flash
          :if={@show_status}
          id="fl-trigger-status"
          color="info"
          auto_dismiss={false}
          data-fixture-cell="status"
        >
          Status flash content
        </Flash.flash>
      </.fixture_section>

      <.fixture_section name="alert" title="Alert flash (assertive)">
        <button id="trigger-alert" type="button" phx-click="show_alert">
          Show alert flash
        </button>
        <Flash.flash
          :if={@show_alert}
          id="fl-trigger-alert"
          color="danger"
          role="alert"
          auto_dismiss={false}
          data-fixture-cell="alert"
        >
          Alert flash content
        </Flash.flash>
      </.fixture_section>

      <.fixture_section name="persistent" title="Non-dismissible flash">
        <button id="trigger-persistent" type="button" phx-click="show_persistent">
          Show persistent flash
        </button>
        <Flash.flash
          :if={@show_persistent}
          id="fl-trigger-persistent"
          color="info"
          dismissible={false}
          auto_dismiss={false}
          data-fixture-cell="persistent"
        >
          Persistent flash content <button type="button" id="fl-persistent-action">Retry</button>
        </Flash.flash>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
