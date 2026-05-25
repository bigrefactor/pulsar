defmodule Pulsar.TestApp.Components do
  @moduledoc false

  use Phoenix.Component

  @fixtures [
    {"Badge", "/components/badge"},
    {"Button", "/components/button"},
    {"Card", "/components/card"},
    {"Checkbox", "/components/checkbox"},
    {"Divider", "/components/divider"},
    {"Field", "/components/field"},
    {"Flash", "/components/flash"},
    {"FlashGroup", "/components/flash_group"},
    {"Form", "/components/form"},
    {"Header", "/components/header"},
    {"Icon", "/components/icon"},
    {"Input", "/components/input"},
    {"Label", "/components/label"},
    {"Link", "/components/link"},
    {"List", "/components/list"},
    {"RadioGroup", "/components/radio_group"},
    {"Select", "/components/select"},
    {"Switch", "/components/switch"},
    {"Table", "/components/table"},
    {"Textarea", "/components/textarea"}
  ]

  def fixtures, do: @fixtures

  attr :current_path, :string, default: nil

  def fixture_nav(assigns) do
    assigns = assign(assigns, :fixtures, @fixtures)

    ~H"""
    <nav aria-label="Fixtures" data-fixture-nav>
      <ul class="space-y-1">
        <li :for={{label, path} <- @fixtures}>
          <.link
            navigate={path}
            class="block rounded px-3 py-1 text-sm hover:bg-neutral-100 aria-[current=page]:bg-primary-100 aria-[current=page]:font-semibold"
            aria-current={if @current_path == path, do: "page", else: "false"}
          >
            {label}
          </.link>
        </li>
      </ul>
    </nav>
    """
  end

  attr :name, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  def fixture_page(assigns) do
    ~H"""
    <main class="space-y-12 p-8" data-fixture={@name}>
      <header>
        <h1 class="text-2xl font-bold">{@title}</h1>
      </header>
      {render_slot(@inner_block)}
    </main>
    """
  end

  attr :name, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  def fixture_section(assigns) do
    ~H"""
    <section data-fixture-section={@name} aria-labelledby={"fx-h-#{@name}"} class="space-y-3">
      <h2 id={"fx-h-#{@name}"} class="text-lg font-semibold capitalize">{@title}</h2>
      <div class="flex flex-wrap items-center gap-4 rounded border border-border bg-surface-1 p-4">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <button
      type="button"
      class="rounded border px-3 py-1 text-sm"
      data-fixture-theme-toggle
      aria-label="Toggle dark mode"
      onclick="const r=document.documentElement; r.dataset.theme = r.dataset.theme === 'dark' ? 'light' : 'dark'"
    >
      Toggle theme
    </button>
    """
  end
end
