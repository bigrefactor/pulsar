defmodule Pulsar.Storybook.ButtonLive do
  @moduledoc """
  Phoenix LiveView component for showcasing Pulsar button components.
  
  Demonstrates all variants, colors, sizes, and states of the button component
  with interactive examples and code snippets.
  """

  use Phoenix.LiveView
  import Pulsar.Components.Button
  import Pulsar.Storybook.CatalogLayout

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       selected_component: "button",
       page_title: "Button Component"
     )}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
      <div class="max-w-4xl mx-auto space-y-12">
        <div>
          <h1 class="text-3xl font-bold mb-2">Button</h1>
          <p class="text-muted dark:text-dark-muted">
            Interactive button component with multiple variants, sizes, and states.
            Built on Stellar's accessible button foundation.
          </p>
        </div>

      <section class="space-y-8">
        <div>
          <h2 class="text-xl font-semibold mb-6">All Variant & Color Combinations</h2>
          <div class="space-y-6">
            <div :for={variant <- ["solid", "outline", "ghost", "link"]}>
              <h3 class="text-lg font-medium mb-4 capitalize">{variant} Variant</h3>
              <div class="flex flex-wrap gap-3">
                <.button :for={color <- ["neutral", "primary", "secondary", "success", "danger", "warning"]} 
                  variant={variant} 
                  color={color}
                >
                  {String.capitalize(color)}
                </.button>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Sizes (Solid Primary)</h2>
          <div class="flex flex-wrap items-end gap-3">
            <.button variant="solid" color="primary" size="xs">Extra Small</.button>
            <.button variant="solid" color="primary" size="sm">Small</.button>
            <.button variant="solid" color="primary" size="md">Medium</.button>
            <.button variant="solid" color="primary" size="lg">Large</.button>
            <.button variant="solid" color="primary" size="xl">Extra Large</.button>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Icon Buttons</h2>
          <p class="text-muted dark:text-dark-muted mb-4">
            For icon-only buttons, use regular sizes with custom classes for square aspect ratio.
          </p>
          <div class="flex flex-wrap items-end gap-3">
            <.button variant="solid" color="primary" size="xs" class="w-6 p-0" aria-label="Add item">+</.button>
            <.button variant="solid" color="primary" size="sm" class="w-8 p-0" aria-label="Favorite">⭐</.button>
            <.button variant="solid" color="primary" size="md" class="w-10 p-0" aria-label="Settings">⚙️</.button>
            <.button variant="solid" color="primary" size="lg" class="w-12 p-0" aria-label="Menu">☰</.button>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-6">Interactive States</h2>
          <div class="space-y-6">
            <div :for={variant <- ["solid", "outline", "ghost", "link"]}>
              <h3 class="text-lg font-medium mb-4 capitalize">{variant} States</h3>
              <div class="flex flex-wrap gap-3">
                <.button variant={variant} color="primary">Normal</.button>
                <.button variant={variant} color="primary" loading={true}>Loading</.button>
                <.button variant={variant} color="primary" disabled={true}>Disabled</.button>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Usage Examples</h2>
          <div class="space-y-4">
            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">Basic Button</h3>
              <.button variant="solid" color="primary">Save Changes</.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="solid" color="primary"&gt;Save Changes&lt;/.button&gt;</code></pre>
            </div>

            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">Navigation Button</h3>
              <.button variant="outline" color="primary" as={:a} href="https://example.com" target="_blank">
                Visit Site
              </.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="outline" color="primary" as={:a} href="https://example.com"&gt;
                Visit Site
              &lt;/.button&gt;</code></pre>
            </div>

            <div class="p-4 border border-border dark:border-dark-border rounded-lg">
              <h3 class="font-medium mb-2">With Custom Classes</h3>
              <.button variant="solid" color="primary" class="w-full justify-start">
                <span>📁</span> Full Width with Icon
              </.button>
              <pre class="mt-2 text-sm bg-surface-secondary dark:bg-dark-surface-secondary p-2 rounded text-muted dark:text-dark-muted"><code>&lt;.button variant="solid" color="primary" class="w-full justify-start"&gt;
                &lt;span&gt;📁&lt;/span&gt; Full Width with Icon
              &lt;/.button&gt;</code></pre>
            </div>
          </div>
        </div>
      </section>
      </div>
    </.catalog_layout>
    """
  end
end