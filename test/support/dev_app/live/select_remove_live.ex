defmodule Pulsar.DevApp.SelectRemoveLive do
  @moduledoc """
  Interaction fixture for `Pulsar.Components.Select` multi-select badge removal.

  Pre-selects two options so their badges render, and wires the select to a
  form with `phx-change`. Clicking a badge's remove button fires the
  `.PulsarSelect` colocated hook, which deselects the matching `<option>`
  client-side and dispatches a `change` event; the form then re-renders
  without that badge. This isolates the hook: there is no server-side
  `remove_tag` handler, so removal only happens if the hook actually mounts
  and runs in the browser.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Select

  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, options: @options, selected: ["1", "2"])}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, selected: params["sel_remove"] || [])}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="select-remove" title="Select (multi) badge removal">
      <p>Selected: <span id="sel-remove-count">{length(@selected)}</span></p>

      <.fixture_section name="multi" title="Multi-select with removable badges">
        <form phx-change="validate">
          <Select.select
            id="sel-remove"
            name="sel_remove"
            multiple
            options={@options}
            value={@selected}
            aria-label="removable multi-select"
          />
        </form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
