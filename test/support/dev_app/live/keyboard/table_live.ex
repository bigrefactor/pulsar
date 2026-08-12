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
       action_selected: "None",
       action_count: 0,
       lifecycle_row_click?: false
     )}
  end

  def handle_event("select-row", %{"name" => name}, socket) do
    {:noreply, socket |> assign(:selected, name) |> update(:activation_count, &(&1 + 1))}
  end

  def handle_event("toggle-row-click", _params, socket) do
    {:noreply, update(socket, :lifecycle_row_click?, &(!&1))}
  end

  def handle_event("select-action", %{"name" => name}, socket) do
    {:noreply, socket |> assign(:action_selected, name) |> update(:action_count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <p>Selected row: <span id="kbd-table-selection">{@selected}</span></p>
    <p>Activation count: <span id="kbd-table-activation-count">{@activation_count}</span></p>
    <p>Selected action: <span id="kbd-table-action-selection">{@action_selected}</span></p>
    <p>Action count: <span id="kbd-table-action-count">{@action_count}</span></p>
    <Table.table
      id="kbd-table"
      aria_label="Keyboard activation table"
      rows={@rows}
      row_click={fn row -> JS.push("select-row", value: %{name: row.name}) end}
    >
      <:col :let={row} label="Name">{row.name}</:col>
    </Table.table>

    <Table.table
      id="kbd-table-nested-action"
      aria_label="Nested controls table"
      rows={@rows}
      row_click={fn row -> JS.push("select-row", value: %{name: row.name}) end}
    >
      <:col :let={row} label="Name">{row.name}</:col>
      <:action :let={row}>
        <a id={"kbd-table-link-#{String.downcase(row.name)}"} href="#plain-link-target">
          Edit {row.name}
        </a>
        <button
          id={"kbd-table-action-#{String.downcase(row.name)}"}
          phx-click={JS.push("select-action", value: %{name: row.name})}
        >
          Select {row.name}
        </button>
      </:action>
    </Table.table>

    <button id="kbd-table-toggle-row-click" phx-click="toggle-row-click">Toggle row click</button>
    <Table.table
      id="kbd-table-lifecycle"
      aria_label="Row click lifecycle table"
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
