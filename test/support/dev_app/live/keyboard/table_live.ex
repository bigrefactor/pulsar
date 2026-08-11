defmodule Pulsar.DevApp.Keyboard.TableLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Table

  def mount(_params, _session, socket) do
    {:ok, assign(socket, rows: [%{name: "Ada"}, %{name: "Grace"}], selected: "None")}
  end

  def handle_event("select-row", %{"name" => name}, socket) do
    {:noreply, assign(socket, selected: name)}
  end

  def render(assigns) do
    ~H"""
    <p>Selected row: <span id="kbd-table-selection">{@selected}</span></p>
    <Table.table
      id="kbd-table"
      rows={@rows}
      row_click={fn row -> JS.push("select-row", value: %{name: row.name}) end}
    >
      <:col :let={row} label="Name">{row.name}</:col>
    </Table.table>
    """
  end
end
