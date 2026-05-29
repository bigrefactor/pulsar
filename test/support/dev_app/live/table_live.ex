defmodule Pulsar.DevApp.TableLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Table

  @rows [
    %{id: 1, name: "Ada Lovelace", role: "Engineer", status: "active"},
    %{id: 2, name: "Grace Hopper", role: "Admiral", status: "active"},
    %{id: 3, name: "Alan Turing", role: "Cryptanalyst", status: "inactive"}
  ]
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(sm md lg)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns = assign(assigns, variant: variant, rows: @rows, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name={"table-#{@variant}"} title={"Table (#{@variant})"}>
      <.fixture_section name={"variant-#{@variant}"} title={"variant: #{@variant}"}>
        <div class="grid w-full grid-cols-1 gap-6">
          <%= for color <- @colors, size <- @sizes do %>
            <Table.table
              id={"tbl-#{@variant}-#{color}-#{size}"}
              variant={@variant}
              color={color}
              size={size}
              rows={@rows}
              aria_label={"Team roster — #{@variant} #{color} #{size}"}
              data-fixture-cell={"#{@variant}-#{color}-#{size}"}
            >
              <:col :let={row} label="Name">{row.name}</:col>
              <:col :let={row} label="Role">{row.role}</:col>
              <:col :let={row} label="Status">{row.status}</:col>
            </Table.table>
          <% end %>
        </div>
      </.fixture_section>
      <%= if @live_action == :outline do %>
        <.fixture_section name="striped-sticky" title="Striped + sticky header">
          <Table.table
            id="tbl-striped"
            striped
            sticky_header
            rows={@rows}
            data-fixture-cell="striped-sticky"
          >
            <:caption>Team roster — striped with sticky header</:caption>
            <:col :let={row} label="Name">{row.name}</:col>
            <:col :let={row} label="Role">{row.role}</:col>
            <:col :let={row} label="Status">{row.status}</:col>
            <:action :let={_row}>Edit</:action>
          </Table.table>
        </.fixture_section>
        <.fixture_section name="empty" title="Empty state">
          <Table.table
            id="tbl-empty"
            rows={[]}
            aria_label="Team roster — empty state"
            data-fixture-cell="empty"
          >
            <:col :let={row} label="Name">{row.name}</:col>
            <:empty>No rows yet</:empty>
          </Table.table>
        </.fixture_section>
      <% end %>
    </.fixture_page>
    """
  end
end
