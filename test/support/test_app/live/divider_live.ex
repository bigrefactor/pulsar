defmodule Pulsar.TestApp.DividerLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Divider

  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg)
  @line_styles ~w(solid dashed dotted)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes, line_styles: @line_styles)

    ~H"""
    <.fixture_page name="divider" title="Divider">
      <.fixture_section
        :for={line_style <- @line_styles}
        name={"horizontal-#{line_style}"}
        title={"horizontal · #{line_style}"}
      >
        <div class="w-full space-y-4">
          <%= for color <- @colors, size <- @sizes do %>
            <div data-fixture-cell={"h-#{line_style}-#{color}-#{size}"}>
              <Divider.divider color={color} size={size} line_style={line_style} />
            </div>
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="with-label" title="With label slot">
        <div class="w-full">
          <Divider.divider color="primary" data-fixture-cell="labeled">
            <span>Section label</span>
          </Divider.divider>
        </div>
      </.fixture_section>
      <.fixture_section name="vertical" title="Vertical orientation">
        <div class="flex h-16 items-center gap-4">
          <%= for color <- @colors do %>
            <Divider.divider
              color={color}
              orientation="vertical"
              data-fixture-cell={"v-#{color}"}
            />
          <% end %>
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
