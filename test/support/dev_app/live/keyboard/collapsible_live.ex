defmodule Pulsar.DevApp.Keyboard.CollapsibleLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Collapsible`.

  A single collapsible (`kbd-col`), closed by default, with a `:trigger` and a
  uniquely-id'd body span (`kbd-col-body`), so the integration suite can click
  the trigger and assert the panel actually opens (`data-expanded`, visible body)
  and closes again — not just that `aria-expanded` flips. Behavior comes from the
  `.PulsarCollapsible` colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Collapsible

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-collapsible" title="Collapsible interaction fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-col-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="collapsible" title="Closed by default">
        <Collapsible.collapsible id="kbd-col" class="max-w-md">
          <:trigger>Show details</:trigger>
          <span id="kbd-col-body">The hidden details go here.</span>
        </Collapsible.collapsible>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
