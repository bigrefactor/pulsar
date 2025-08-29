defmodule Pulsar.Storybook.CatalogLive do
  @moduledoc """
  Phoenix LiveView-based component catalog for Pulsar components.

  This provides a simple storybook-style interface for browsing and testing
  Pulsar components with different props and states.
  """

  use Phoenix.LiveView
  import Pulsar.Components.Button

  @components [
    %{
      name: "Button",
      id: "button",
      description: "Interactive button component with multiple variants and sizes"
    }
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       components: @components,
       selected_component: "button",
       dark_mode: false,
       page_title: "Pulsar Component Catalog"
     )}
  end

  def handle_params(%{"component" => component}, _uri, socket) do
    {:noreply, assign(socket, selected_component: component)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("select_component", %{"component" => component}, socket) do
    {:noreply, push_patch(socket, to: "/catalog/#{component}")}
  end

  def handle_event("toggle_dark_mode", _params, socket) do
    new_dark_mode = !socket.assigns.dark_mode

    {:noreply,
     socket
     |> assign(dark_mode: new_dark_mode)
     |> push_event("toggle_theme", %{dark: new_dark_mode})}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen" phx-hook="ThemeToggle" id="theme-container">
      <div class="bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground">
        <header class="border-b border-border dark:border-dark-border bg-surface dark:bg-dark-surface">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
              <div class="flex items-center">
                <h1 class="text-xl font-bold">Pulsar Component Catalog</h1>
              </div>
              <div class="flex items-center space-x-4">
                <.button
                  variant="ghost"
                  size="sm"
                  phx-click="toggle_dark_mode"
                >
                  <span :if={!@dark_mode}>🌙</span>
                  <span :if={@dark_mode}>☀️</span>
                  <span class="ml-2">{if @dark_mode, do: "Light", else: "Dark"}</span>
                </.button>
              </div>
            </div>
          </div>
        </header>

        <div class="flex">
          <aside class="w-64 border-r border-border dark:border-dark-border bg-surface dark:bg-dark-surface min-h-screen">
            <nav class="p-4 space-y-2">
              <h2 class="font-semibold text-sm text-muted dark:text-dark-muted mb-4">Components</h2>

              <div :for={component <- @components} class="space-y-1">
                <button
                  type="button"
                  phx-click="select_component"
                  phx-value-component={component.id}
                  class={[
                    "w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
                    if(@selected_component == component.id,
                      do: "bg-primary-100 dark:bg-primary-900 text-primary-900 dark:text-primary-100",
                      else:
                        "text-foreground dark:text-dark-foreground hover:bg-gray-100 dark:hover:bg-gray-800"
                    )
                  ]}
                >
                  {component.name}
                </button>
              </div>
            </nav>
          </aside>

          <main class="flex-1 p-8">
            <%= case @selected_component do %>
              <% "button" -> %>
                <.button_showcase />
              <% _ -> %>
                <div class="text-center py-12">
                  <h2 class="text-2xl font-bold text-muted dark:text-dark-muted">
                    Component not found
                  </h2>
                </div>
            <% end %>
          </main>
        </div>
      </div>
    </div>
    """
  end

  defp button_showcase(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-12">
      <div>
        <h1 class="text-3xl font-bold mb-2">Button</h1>
        <p class="text-muted dark:text-dark-muted">
          Interactive button component with multiple variants, sizes, and states.
          Built on Stellar's accessible button foundation.
        </p>
      </div>

      <section class="space-y-6">
        <div>
          <h2 class="text-xl font-semibold mb-4">Variants</h2>
          <div class="flex flex-wrap gap-3">
            <.button variant="primary">Primary</.button>
            <.button variant="secondary">Secondary</.button>
            <.button variant="success">Success</.button>
            <.button variant="error">Error</.button>
            <.button variant="warning">Warning</.button>
          </div>

          <div class="flex flex-wrap gap-3 mt-3">
            <.button variant="ghost">Ghost</.button>
            <.button variant="outline">Outline</.button>
            <.button variant="link">Link</.button>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Sizes</h2>
          <div class="flex flex-wrap items-end gap-3">
            <.button variant="primary" size="sm">Small</.button>
            <.button variant="primary" size="md">Medium</.button>
            <.button variant="primary" size="lg">Large</.button>
            <.button variant="primary" size="icon">⭐</.button>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">States</h2>
          <div class="flex flex-wrap gap-3">
            <.button variant="primary">Normal</.button>
            <.button variant="primary" loading={true}>Loading</.button>
            <.button variant="primary" disabled={true}>Disabled</.button>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Usage Examples</h2>
          <div class="space-y-4">
            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">Basic Button</h3>
              <.button variant="primary">Save Changes</.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="primary"&gt;Save Changes&lt;/.button&gt;</code></pre>
            </div>

            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">Navigation Button</h3>
              <.button variant="outline" as={:a} href="https://example.com" target="_blank">
                Visit Site
              </.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="outline" as={:a} href="https://example.com"&gt;
                Visit Site
              &lt;/.button&gt;</code></pre>
            </div>

            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">With Custom Classes</h3>
              <.button variant="primary" class="w-full justify-start">
                <span>📁</span> Full Width with Icon
              </.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="primary" class="w-full justify-start"&gt;
                &lt;span&gt;📁&lt;/span&gt;
                Full Width with Icon
              &lt;/.button&gt;</code></pre>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
