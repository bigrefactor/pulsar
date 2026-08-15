defmodule Pulsar.DevApp.BadgeLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Badge
  alias Pulsar.Components.Popover

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="badge" title="Badge">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Badge.badge
            variant={variant}
            color={color}
            size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          >
            {color}/{size}
          </Badge.badge>
        <% end %>
      </.fixture_section>
      <.fixture_section name="addons" title="With start and end addons">
        <Badge.badge variant="solid" color="primary" data-fixture-cell="addons-both">
          <:start_addon>•</:start_addon>
          With addons
          <:end_addon>×</:end_addon>
        </Badge.badge>
      </.fixture_section>
      <.fixture_section name="removable" title="Removable tokens">
        <Badge.badge
          :for={variant <- @variants}
          variant={variant}
          color="primary"
          on_remove={JS.push("remove_badge")}
          remove_label={"Remove filter #{variant}"}
          data-fixture-cell={"removable-#{variant}"}
        >
          filter: {variant}
        </Badge.badge>
      </.fixture_section>
      <.fixture_section name="two-action" title="Two-action token with a popover label">
        <Badge.badge
          as={:div}
          variant="outline"
          color="primary"
          on_remove={JS.push("remove_badge")}
          remove_label="Remove filter Status"
          data-fixture-cell="two-action"
        >
          <Popover.popover id="badge-filter-status">
            <:trigger>
              <button type="button">Status: Published</button>
            </:trigger>
            <p class="text-sm">Filter editor</p>
          </Popover.popover>
        </Badge.badge>
      </.fixture_section>
    </.fixture_page>
    """
  end

  def handle_event("remove_badge", _params, socket), do: {:noreply, socket}
end
