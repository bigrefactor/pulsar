defmodule Pulsar.DevApp.BreadcrumbLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Breadcrumb

  @colors ~w(muted primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="breadcrumb" title="Breadcrumb">
      <.fixture_section name="colors" title="colors">
        <Breadcrumb.breadcrumb
          :for={color <- @colors}
          color={color}
          aria_label={"Breadcrumb color #{color}"}
          data-fixture-cell={"color-#{color}"}
        >
          <:item href="/">Home</:item>
          <:item href="/products">Products</:item>
          <:item>Edit Product</:item>
        </Breadcrumb.breadcrumb>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <Breadcrumb.breadcrumb
          :for={size <- @sizes}
          size={size}
          aria_label={"Breadcrumb size #{size}"}
          data-fixture-cell={"size-#{size}"}
        >
          <:item href="/">Home</:item>
          <:item href="/products">Products</:item>
          <:item>Edit Product</:item>
        </Breadcrumb.breadcrumb>
      </.fixture_section>

      <.fixture_section name="collapsed" title="overflow collapse">
        <Breadcrumb.breadcrumb
          max_items={4}
          aria_label="Breadcrumb collapsed"
          data-fixture-cell="collapsed"
        >
          <:item href="/">Home</:item>
          <:item href="/workspace">Workspace</:item>
          <:item href="/billing">Billing</:item>
          <:item href="/settings">Settings</:item>
          <:item>Profile</:item>
        </Breadcrumb.breadcrumb>
      </.fixture_section>

      <.fixture_section name="custom-separator" title="custom separator">
        <Breadcrumb.breadcrumb
          aria_label="Breadcrumb custom separator"
          data-fixture-cell="custom-separator"
        >
          <:separator>/</:separator>
          <:item href="/">Home</:item>
          <:item>Docs</:item>
        </Breadcrumb.breadcrumb>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
