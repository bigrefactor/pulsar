defmodule Pulsar.DevApp.StatusLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Avatar
  alias Pulsar.Components.Status

  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)
  @placements ~w(top-left top top-right left center right bottom-left bottom bottom-right)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes, placements: @placements)

    ~H"""
    <.fixture_page name="status" title="Status">
      <.fixture_section name="colors" title="Colors">
        <Status.status
          :for={color <- @colors}
          color={color}
          label={"#{color} status"}
          data-fixture-cell={color}
        />
      </.fixture_section>

      <.fixture_section name="sizes" title="Sizes">
        <Status.status
          :for={size <- @sizes}
          size={size}
          color="success"
          label={"#{size} status"}
          data-fixture-cell={size}
        />
      </.fixture_section>

      <.fixture_section name="ping" title="Ping (live)">
        <Status.status color="danger" ping label="Live" data-fixture-cell="ping" />
      </.fixture_section>

      <.fixture_section name="decorative" title="Decorative (aria-hidden)">
        <Status.status color="neutral" data-fixture-cell="decorative" />
      </.fixture_section>

      <.fixture_section name="on-avatar" title="On an avatar (indicator)">
        <Status.indicator
          :for={placement <- @placements}
          placement={placement}
          data-fixture-cell={placement}
        >
          <:item><Status.status color="success" label={"Online (#{placement})"} /></:item>
          <Avatar.avatar name={"User #{placement}"} />
        </Status.indicator>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
