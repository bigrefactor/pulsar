defmodule Pulsar.DevApp.ListLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.List

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(sm md lg)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="list" title="List">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <div class="grid w-full grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          <%= for color <- @colors, size <- @sizes do %>
            <List.list
              variant={variant}
              color={color}
              size={size}
              data-fixture-cell={"#{variant}-#{color}-#{size}"}
            >
              <:item title="Name">Ada Lovelace</:item>
              <:item title="Email">ada@example.com</:item>
              <:item title="Role">Engineer</:item>
            </List.list>
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="striped-dividers" title="Striped + dividers">
        <List.list striped dividers data-fixture-cell="striped-dividers">
          <:item title="Plan">Pro</:item>
          <:item title="Seats">10</:item>
          <:item title="Status">Active</:item>
        </List.list>
      </.fixture_section>
      <.fixture_section name="empty-state" title="Empty state">
        <div class="grid w-full grid-cols-1 gap-4 md:grid-cols-2">
          <List.list variant="outline" color="neutral" data-fixture-cell="empty-headerless" />
          <List.list variant="outline" color="primary" data-fixture-cell="empty-with-header">
            <:title>Recent activity</:title>
            <:description>Nothing has happened yet.</:description>
          </List.list>
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
