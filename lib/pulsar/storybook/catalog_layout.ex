defmodule Pulsar.Storybook.CatalogLayout do
  @moduledoc """
  Shared layout component for the Pulsar component catalog.

  Provides consistent header, sidebar navigation, and theme toggle
  across all catalog pages.
  """

  use Phoenix.Component

  @components [
    %{
      name: "Button",
      id: "button",
      description: "Interactive button component with multiple variants and sizes"
    },
    %{
      name: "Input",
      id: "input",
      description: "Accessible input component with decorator support and Phoenix form integration"
    }
  ]

  attr :selected_component, :string, default: nil
  slot :inner_block, required: true

  def catalog_layout(assigns) do
    assigns = assign(assigns, :components, @components)

    ~H"""
    <div class="min-h-screen" id="theme-container">
      <div class="bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground">
        <header class="border-b border-border dark:border-dark-border bg-surface dark:bg-dark-surface">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
              <div class="flex items-center">
                <.link
                  navigate="/catalog"
                  class="text-xl font-bold hover:text-primary-600 dark:hover:text-primary-400"
                >
                  Pulsar Component Catalog
                </.link>
              </div>
              <div class="flex items-center space-x-4">
                <button
                  id="theme-toggle"
                  phx-hook="ThemeToggle"
                  class="inline-flex items-center justify-center font-medium transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-ring dark:focus-visible:ring-dark-ring h-8 px-3 text-sm gap-1.5 rounded-md text-gray-700 hover:bg-gray-100 active:bg-gray-200 dark:text-gray-300 dark:hover:bg-gray-800 dark:active:bg-gray-700"
                >
                  <span id="theme-icon">🌙</span>
                  <span id="theme-text" class="ml-2">Dark</span>
                </button>
              </div>
            </div>
          </div>
        </header>

        <div class="flex">
          <aside class="w-64 border-r border-border dark:border-dark-border bg-surface dark:bg-dark-surface min-h-screen">
            <nav class="p-4 space-y-2">
              <h2 class="font-semibold text-sm text-muted dark:text-dark-muted mb-4">Components</h2>

              <div :for={component <- @components} class="space-y-1">
                <.link
                  navigate={"/catalog/#{component.id}"}
                  class={[
                    "block w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
                    if(@selected_component == component.id,
                      do: "bg-primary-100 dark:bg-primary-900 text-primary-900 dark:text-primary-100",
                      else:
                        "text-foreground dark:text-dark-foreground hover:bg-gray-100 dark:hover:bg-gray-800"
                    )
                  ]}
                >
                  {component.name}
                </.link>
              </div>
            </nav>
          </aside>

          <main class="flex-1 p-8">
            {render_slot(@inner_block)}
          </main>
        </div>
      </div>
    </div>
    """
  end
end
