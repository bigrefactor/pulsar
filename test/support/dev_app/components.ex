defmodule Pulsar.DevApp.Components do
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
    {"Flash (trigger)", "/components/flash/trigger"},
    {"FlashGroup", "/components/flash_group"},
    {"Form", "/components/form"},
    {"Header", "/components/header"},
    {"Icon", "/components/icon"},
    {"Input (outline)", "/components/input/outline"},
    {"Input (ghost)", "/components/input/ghost"},
    {"Input (solid)", "/components/input/solid"},
    {"Label", "/components/label"},
    {"Link", "/components/link"},
    {"List", "/components/list"},
    {"Navbar", "/components/navbar"},
    {"RadioGroup", "/components/radio_group"},
    {"Select (outline)", "/components/select/outline"},
    {"Select (ghost)", "/components/select/ghost"},
    {"Select (solid)", "/components/select/solid"},
    {"Select (multi)", "/components/select/multi"},
    {"Sidebar", "/components/sidebar"},
    {"Switch", "/components/switch"},
    {"Table (outline)", "/components/table/outline"},
    {"Table (ghost)", "/components/table/ghost"},
    {"Table (solid)", "/components/table/solid"},
    {"Textarea", "/components/textarea"}
  ]

  def fixtures, do: @fixtures

  attr :current_path, :string, default: nil

  def fixture_nav(assigns) do
    assigns = assign(assigns, :fixtures, @fixtures)

    ~H"""
    <ul class="space-y-1" data-fixture-nav>
      <li :for={{label, path} <- @fixtures}>
        <.link
          navigate={path}
          class="block rounded px-3 py-1 text-sm hover:bg-surface-1-hover aria-[current=page]:bg-primary aria-[current=page]:text-primary-foreground aria-[current=page]:font-semibold"
          aria-current={if @current_path == path, do: "page"}
        >
          {label}
        </.link>
      </li>
    </ul>
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
      id="pulsar-theme-toggle"
      type="button"
      class="rounded border px-3 py-1 text-sm"
      data-fixture-theme-toggle
      aria-label="Toggle dark mode"
      phx-hook=".PulsarThemeToggle"
    >
      Toggle theme
    </button>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarThemeToggle">
      export default {
        mounted() {
          this.el.addEventListener("click", () => {
            const root = document.documentElement;
            root.dataset.theme = root.dataset.theme === "dark" ? "light" : "dark";
          });
        }
      }
    </script>
    """
  end
end
