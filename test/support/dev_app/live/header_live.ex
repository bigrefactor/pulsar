defmodule Pulsar.DevApp.HeaderLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Button
  alias Pulsar.Components.Header

  @sizes ~w(xs sm md lg xl)
  @levels ~w(h1 h2 h3 h4 h5 h6)

  def render(assigns) do
    assigns = assign(assigns, sizes: @sizes, levels: @levels)

    ~H"""
    <.fixture_page name="header" title="Header">
      <.fixture_section name="sizes" title="Sizes">
        <div class="w-full space-y-4">
          <%= for size <- @sizes do %>
            <Header.header size={size} data-fixture-cell={"size-#{size}"}>
              Header @ {size}
              <:subtitle>Subtitle line</:subtitle>
            </Header.header>
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="as-levels" title="Semantic `as` levels">
        <div class="w-full space-y-3">
          <Header.header :for={level <- @levels} as={level} data-fixture-cell={"as-#{level}"}>
            {level}
          </Header.header>
        </div>
      </.fixture_section>
      <.fixture_section name="actions" title="With actions slot">
        <Header.header data-fixture-cell="actions">
          Page title
          <:subtitle>Description text</:subtitle>
          <:actions>
            <Button.button variant="solid" color="primary">Save</Button.button>
            <Button.button variant="outline" color="neutral">Cancel</Button.button>
          </:actions>
        </Header.header>
      </.fixture_section>
      <.fixture_section name="breadcrumbs" title="With breadcrumbs">
        <Header.header data-fixture-cell="breadcrumbs">
          Settings
          <:breadcrumb>Home</:breadcrumb>
          <:breadcrumb>Account</:breadcrumb>
          <:breadcrumb>Settings</:breadcrumb>
        </Header.header>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
