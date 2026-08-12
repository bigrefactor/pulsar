defmodule Pulsar.DevApp.SelectRemoveLive do
  @moduledoc """
  Interaction fixture for `Pulsar.Components.Select` multi-select badge removal.

  Pre-selects two options so their badges render, and wires each select to a
  form with `phx-change`. Clicking a badge's remove button fires the
  `.PulsarSelect` colocated hook, which deselects the matching `<option>`
  client-side and dispatches a `change` event; the form then re-renders
  without that badge. The selects deliberately share a form field name but
  use distinct explicit IDs, covering event isolation under the explicit-ID
  contract. This isolates the hook: there is no server-side `remove_tag`
  handler, so removal only happens if the hook actually mounts and runs in
  the browser.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Select

  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, options: @options, primary_selected: ["1", "2"], sibling_selected: ["1", "2"])}
  end

  def handle_event("validate-primary", params, socket) do
    {:noreply, assign(socket, primary_selected: params["shared_skills"] || [])}
  end

  def handle_event("validate-sibling", params, socket) do
    {:noreply, assign(socket, sibling_selected: params["shared_skills"] || [])}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="select-remove" title="Select (multi) badge removal">
      <.fixture_section name="primary" title="Primary multi-select">
        <p>Selected: <span id="sel-remove-primary-count">{length(@primary_selected)}</span></p>
        <form id="sel-remove-primary-form" phx-change="validate-primary">
          <Select.select
            id="primary-skills"
            name="shared_skills"
            multiple
            options={@options}
            value={@primary_selected}
            aria-label="primary removable multi-select"
          />
        </form>
      </.fixture_section>

      <.fixture_section name="sibling" title="Sibling multi-select with the same name">
        <p>Selected: <span id="sel-remove-sibling-count">{length(@sibling_selected)}</span></p>
        <form id="sel-remove-sibling-form" phx-change="validate-sibling">
          <Select.select
            id="sibling-skills"
            name="shared_skills"
            multiple
            options={@options}
            value={@sibling_selected}
            aria-label="sibling removable multi-select"
          />
        </form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
