defmodule Pulsar.TestApp.FlashLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Flash

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(sm md lg)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="flash" title="Flash">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <div class="grid w-full grid-cols-1 gap-3 md:grid-cols-2">
          <%= for color <- @colors, size <- @sizes do %>
            <Flash.flash
              id={"fl-#{variant}-#{color}-#{size}"}
              variant={variant}
              color={color}
              size={size}
              data-fixture-cell={"#{variant}-#{color}-#{size}"}
            >
              {color} / {size}
            </Flash.flash>
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="dismissible" title="Dismissible">
        <Flash.flash
          id="fl-dismiss"
          variant="solid"
          color="success"
          dismissible
          data-fixture-cell="dismissible"
        >
          You can dismiss this flash
        </Flash.flash>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
