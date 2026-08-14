defmodule Pulsar.DevApp.Keyboard.CommandLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Command`.

  A fixed option list with one disabled row, so the integration suite can
  type, arrow, Enter and Escape and assert real filtering, roving
  activedescendant and selection. Behavior comes from the `.PulsarCommand`
  colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Command

  @options [
    {"Alpha", "alpha"},
    {"Beta", "beta"},
    [key: "Gamma", value: "gamma", disabled: true],
    {"Betamax", "betamax"}
  ]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, received: "", cancelled: "")}
  end

  def handle_event("chosen", %{"value" => value}, socket) do
    {:noreply, assign(socket, :received, value)}
  end

  def handle_event("cancelled", _params, socket) do
    {:noreply, assign(socket, :cancelled, "cancelled")}
  end

  def render(assigns) do
    assigns = assign(assigns, :options, @options)

    ~H"""
    <.fixture_page name="keyboard-command" title="Command interaction fixture">
      <.fixture_section name="list" title="Fixed option list">
        <Command.command
          id="kbd-cmd"
          label="Search commands"
          options={@options}
          on_select={JS.push("chosen")}
          on_cancel={JS.push("cancelled")}
        />
        <p id="kbd-cmd-received">{@received}</p>
        <p id="kbd-cmd-cancelled">{@cancelled}</p>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
