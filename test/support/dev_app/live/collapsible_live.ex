defmodule Pulsar.DevApp.CollapsibleLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Collapsible

  def render(assigns) do
    ~H"""
    <.fixture_page name="collapsible" title="Collapsible">
      <.fixture_section name="closed" title="closed (outline)">
        <Collapsible.collapsible id="col-closed" class="max-w-md" data-fixture-cell="closed">
          <:trigger>Show shipping details</:trigger>
          <p class="text-muted-foreground">We ship worldwide within three to five business days.</p>
        </Collapsible.collapsible>
      </.fixture_section>

      <.fixture_section name="open" title="open (primary)">
        <Collapsible.collapsible id="col-open" open color="primary" class="max-w-md" data-fixture-cell="open">
          <:trigger>Filters</:trigger>
          <p class="text-muted-foreground">Filter controls are shown here.</p>
        </Collapsible.collapsible>
      </.fixture_section>

      <.fixture_section name="ghost" title="ghost">
        <Collapsible.collapsible id="col-ghost" variant="ghost" class="max-w-md" data-fixture-cell="ghost">
          <:trigger>More options</:trigger>
          <p class="text-muted-foreground">Additional options live here.</p>
        </Collapsible.collapsible>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
