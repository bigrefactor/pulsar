defmodule Pulsar.TestApp.IndexLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.TestApp.Components

  def render(assigns) do
    assigns = assign(assigns, :fixtures, Components.fixtures())

    ~H"""
    <main class="space-y-6 p-8" data-fixture="index">
      <header>
        <h1 class="text-2xl font-bold">Pulsar fixtures</h1>
        <p class="text-muted-foreground">
          One LiveView per component, rendering the full variant matrix used by Tier E browser tests.
        </p>
      </header>
      <ul class="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4">
        <li :for={{label, path} <- @fixtures}>
          <.link
            navigate={path}
            class="block rounded border border-border bg-surface-1 px-3 py-2 hover:bg-surface-2"
            data-fixture-link={label}
          >
            {label}
          </.link>
        </li>
      </ul>
    </main>
    """
  end
end
