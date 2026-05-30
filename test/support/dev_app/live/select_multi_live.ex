defmodule Pulsar.DevApp.SelectMultiLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Select

  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, options: @options, selected: ["1", "2"])}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, selected: params["sel_multi_badges"] || [])}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="select-multi" title="Select (multi)">
      <.fixture_section name="multi" title="Multi-select">
        <Select.select
          id="sel-multi"
          name="sel_multi"
          multiple
          options={@options}
          aria-label="multi-select"
          data-fixture-cell="multi"
        />
      </.fixture_section>

      <.fixture_section name="multi-badges" title="Multi-select with badges">
        <form phx-change="validate">
          <Select.select
            id="sel-multi-badges"
            name="sel_multi_badges"
            multiple
            options={@options}
            value={@selected}
            aria-label="multi-select with badges"
            data-fixture-cell="multi-badges"
          />
        </form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
