defmodule Pulsar.DevApp.Keyboard.TableLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Table

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       rows: [%{name: "Ada"}, %{name: "Grace"}],
       selected: "None",
       activation_count: 0,
       lifecycle_row_click?: false
     )}
  end

  def handle_event("select-row", %{"name" => name}, socket) do
    {:noreply, socket |> assign(:selected, name) |> update(:activation_count, &(&1 + 1))}
  end

  def handle_event("toggle-row-click", _params, socket) do
    {:noreply, update(socket, :lifecycle_row_click?, &(!&1))}
  end

  def render(assigns) do
    ~H"""
    <p>Selected row: <span id="kbd-table-selection">{@selected}</span></p>
    <p>Activation count: <span id="kbd-table-activation-count">{@activation_count}</span></p>
    <Table.table
      id="kbd-table"
      rows={@rows}
      row_click={fn row -> JS.push("select-row", value: %{name: row.name}) end}
    >
      <:col :let={row} label="Name">{row.name}</:col>
    </Table.table>

    <button id="kbd-table-toggle-row-click" phx-click="toggle-row-click">Toggle row click</button>
    <Table.table
      id="kbd-table-lifecycle"
      rows={@rows}
      row_click={
        if @lifecycle_row_click?,
          do: fn row -> JS.push("select-row", value: %{name: row.name}) end,
          else: nil
      }
    >
      <:col :let={row} label="Name">{row.name}</:col>
    </Table.table>
    """
  end
end
