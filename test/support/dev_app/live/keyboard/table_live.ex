defmodule Pulsar.DevApp.Keyboard.TableLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Table

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       rows: [%{name: "Ada"}, %{name: "Grace"}],
       selected: "None",
       activation_count: 0,
       action_selected: "None",
       action_count: 0,
       lifecycle_row_click?: false,
       name_sort_direction: nil,
       async_sort_direction: nil,
       async_loading?: false,
       async_reloads: 0,
       stream_loading?: false,
       stream_reloads: 0
     )
     |> stream(:people, [%{id: "ada", name: "Ada"}, %{id: "grace", name: "Grace"}])}
  end

  def handle_event("sort-name", _params, socket) do
    {:noreply, update(socket, :name_sort_direction, &next_sort_direction/1)}
  end

  def handle_event("sort-async", _params, socket) do
    Process.send_after(self(), :finish_async_sort, 50)

    {:noreply,
     socket
     |> assign(:async_loading?, true)
     |> update(:async_sort_direction, &next_sort_direction/1)}
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

  def handle_event("reload-stream", _params, socket) do
    Process.send_after(self(), :finish_stream_reload, 50)
    {:noreply, assign(socket, :stream_loading?, true)}
  end

  def handle_info(:finish_async_sort, socket) do
    {:noreply, socket |> assign(:async_loading?, false) |> update(:async_reloads, &(&1 + 1))}
  end

  def handle_info(:finish_stream_reload, socket) do
    {:noreply, socket |> assign(:stream_loading?, false) |> update(:stream_reloads, &(&1 + 1))}
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

    <div id="kbd-table-sortable">
      <Table.table id="kbd-table-sortable-inner" aria_label="Sortable table" rows={@rows}>
        <:col
          :let={row}
          label="Name"
          sortable
          sort_direction={@name_sort_direction}
          on_sort={JS.push("sort-name")}
        >
          {row.name}
        </:col>
        <:col :let={row} label="Role" sortable on_sort={JS.push("sort-name")}>{row.name}</:col>
      </Table.table>
    </div>

    <p>Async reloads: <span id="kbd-table-async-reloads">{@async_reloads}</span></p>
    <div id="kbd-table-async">
      <Table.table
        id="kbd-table-async-inner"
        aria_label="Async sortable table"
        rows={@rows}
        loading={@async_loading?}
      >
        <:col
          :let={row}
          label="Name"
          sortable
          sort_direction={@async_sort_direction}
          on_sort={JS.push("sort-async")}
        >
          {row.name}
        </:col>
      </Table.table>
    </div>

    <p>Stream reloads: <span id="kbd-table-stream-reloads">{@stream_reloads}</span></p>
    <button id="kbd-table-stream-reload" phx-click="reload-stream">Reload stream</button>
    <div id="kbd-table-stream">
      <Table.table
        id="kbd-table-stream-inner"
        aria_label="Stream reload table"
        rows={@streams.people}
        loading={@stream_loading?}
      >
        <:col :let={{_id, person}} label="Name">{person.name}</:col>
      </Table.table>
    </div>

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

  defp next_sort_direction(nil), do: "ascending"
  defp next_sort_direction("ascending"), do: "descending"
  defp next_sort_direction("descending"), do: nil
end
