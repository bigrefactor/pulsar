defmodule Pulsar.DevApp.TabsLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Tabs

  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns =
      assign(assigns,
        variant: variant,
        colors: @colors,
        sizes: @sizes
      )

    ~H"""
    <.fixture_page name={"tabs-#{@variant}"} title={"Tabs (#{@variant})"}>
      <.fixture_section
        :for={color <- @colors}
        name={"#{@variant}-#{color}"}
        title={"#{@variant} · #{color}"}
      >
        <Tabs.tabs
          :for={size <- @sizes}
          id={"tabs-#{@variant}-#{color}-#{size}"}
          variant={@variant}
          color={color}
          size={size}
          aria_label={"#{@variant} #{color} #{size}"}
          data-fixture-cell={"#{@variant}-#{color}-#{size}"}
        >
          <:tab id={"#{@variant}-#{color}-#{size}-a"} label="First">First panel</:tab>
          <:tab id={"#{@variant}-#{color}-#{size}-b"} label="Second">Second panel</:tab>
        </Tabs.tabs>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
