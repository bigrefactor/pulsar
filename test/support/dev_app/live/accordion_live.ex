defmodule Pulsar.DevApp.AccordionLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Accordion

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, variant: variant)

    ~H"""
    <.fixture_page name={"accordion-#{@variant}"} title={"Accordion (#{@variant})"}>
      <.fixture_section name={"#{@variant}-closed"} title={"#{@variant} · all closed"}>
        <Accordion.accordion
          id={"acc-#{@variant}-closed"}
          variant={@variant}
          class="max-w-lg"
          data-fixture-cell={"#{@variant}-closed"}
        >
          <:item id={"#{@variant}-c-ship"} title="Shipping and delivery">
            We ship worldwide within three to five business days.
          </:item>
          <:item id={"#{@variant}-c-returns"} title="Returns and refunds">
            Free returns within thirty days of delivery.
          </:item>
          <:item id={"#{@variant}-c-warranty"} title="Warranty coverage">
            Every order is covered by a one-year warranty.
          </:item>
        </Accordion.accordion>
      </.fixture_section>

      <.fixture_section name={"#{@variant}-open"} title={"#{@variant} · one open"}>
        <Accordion.accordion
          id={"acc-#{@variant}-open"}
          variant={@variant}
          color="primary"
          value={"#{@variant}-o-billing"}
          class="max-w-lg"
          data-fixture-cell={"#{@variant}-open"}
        >
          <:item id={"#{@variant}-o-profile"} title="Profile settings" icon="hero-user">
            Update your name and avatar.
          </:item>
          <:item id={"#{@variant}-o-billing"} title="Billing settings" icon="hero-credit-card">
            Manage your subscription and payment method.
          </:item>
          <:item id={"#{@variant}-o-disabled"} title="Archived (disabled)" disabled>
            This section is disabled.
          </:item>
        </Accordion.accordion>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
