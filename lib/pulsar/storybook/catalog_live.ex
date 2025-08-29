defmodule Pulsar.Storybook.CatalogLive do
  @moduledoc """
  Phoenix LiveView-based component catalog for Pulsar components.

  This provides a simple storybook-style interface for browsing and testing
  Pulsar components with different props and states.
  """

  use Phoenix.LiveView
  import Pulsar.Storybook.CatalogLayout

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       selected_component: nil,
       page_title: "Pulsar Component Catalog"
     )}
  end

  def handle_params(%{"component" => component}, _uri, socket) do
    {:noreply, assign(socket, selected_component: component)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, selected_component: nil)}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
      <div class="text-center py-12">
        <h2 class="text-2xl font-bold text-muted dark:text-dark-muted">
          Select a component from the sidebar
        </h2>
        <p class="text-muted dark:text-dark-muted mt-2">
          Choose a component to view its documentation and examples
        </p>
      </div>
    </.catalog_layout>
    """
  end
end
