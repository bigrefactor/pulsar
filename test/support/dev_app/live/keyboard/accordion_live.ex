defmodule Pulsar.DevApp.Keyboard.AccordionLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Accordion`.

  A single (`type="single"`, `collapsible`) accordion with stable item/header
  ids and unique panel body text, so the integration suite can click and key the
  headers and assert that panels actually open (`data-expanded`, visible body)
  and that single-mode exclusivity, the disabled item, and arrow-key roving all
  behave. Behavior comes from the `.PulsarAccordion` colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Accordion

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-accordion" title="Accordion interaction fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-acc-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="single" title="Single (item 'two' disabled)">
        <Accordion.accordion id="kbd-acc">
          <:item id="kbd-acc-one" title="Shipping and delivery">
            <span id="kbd-acc-one-body">Worldwide in three to five days.</span>
          </:item>
          <:item id="kbd-acc-two" title="Disabled section" disabled>
            <span id="kbd-acc-two-body">This panel is disabled.</span>
          </:item>
          <:item id="kbd-acc-three" title="Returns and refunds">
            <span id="kbd-acc-three-body">Free returns within thirty days.</span>
          </:item>
        </Accordion.accordion>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
