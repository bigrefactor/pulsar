defmodule Pulsar.DevApp.Components do
  @moduledoc false

  use Phoenix.Component

  alias Pulsar.Components.Menu

  # Fixtures grouped by component category. `fixtures/0` flattens this for the
  # integration test loops and the index page; `fixture_nav/1` renders a section
  # per group.
  @fixture_groups [
    {"Forms",
     [
       {"Checkbox", "/components/checkbox"},
       {"Field", "/components/field"},
       {"Form", "/components/form"},
       {"Input (outline)", "/components/input/outline"},
       {"Input (ghost)", "/components/input/ghost"},
       {"Input (solid)", "/components/input/solid"},
       {"InputOTP (outline)", "/components/input_otp/outline"},
       {"InputOTP (ghost)", "/components/input_otp/ghost"},
       {"InputOTP (solid)", "/components/input_otp/solid"},
       {"Label", "/components/label"},
       {"RadioGroup", "/components/radio_group"},
       {"Resizable (horizontal)", "/components/resizable/horizontal"},
       {"Resizable (vertical)", "/components/resizable/vertical"},
       {"Select (outline)", "/components/select/outline"},
       {"Select (ghost)", "/components/select/ghost"},
       {"Select (solid)", "/components/select/solid"},
       {"Select (multi)", "/components/select/multi"},
       {"Switch", "/components/switch"},
       {"Textarea", "/components/textarea"}
     ]},
    {"Actions",
     [
       {"Button", "/components/button"},
       {"Link", "/components/link"}
     ]},
    {"Navigation",
     [
       {"Accordion (outline)", "/components/accordion/outline"},
       {"Accordion (solid)", "/components/accordion/solid"},
       {"Accordion (ghost)", "/components/accordion/ghost"},
       {"Accordion (elevated)", "/components/accordion/elevated"},
       {"Breadcrumb", "/components/breadcrumb"},
       {"Collapsible", "/components/collapsible"},
       {"Menu", "/components/menu"},
       {"Navbar", "/components/navbar"},
       {"Pagination (ghost)", "/components/pagination/ghost"},
       {"Pagination (solid)", "/components/pagination/solid"},
       {"Pagination (outline)", "/components/pagination/outline"},
       {"Sidebar", "/components/sidebar"},
       {"Steps (solid)", "/components/steps/solid"},
       {"Steps (outline)", "/components/steps/outline"},
       {"Steps (ghost)", "/components/steps/ghost"},
       {"Tabs (ghost)", "/components/tabs/ghost"},
       {"Tabs (solid)", "/components/tabs/solid"},
       {"Tabs (outline)", "/components/tabs/outline"},
       {"Tabs (elevated)", "/components/tabs/elevated"}
     ]},
    {"Overlays",
     [
       {"AlertDialog", "/components/alert_dialog"},
       {"Drawer", "/components/drawer"},
       {"DropdownMenu", "/components/dropdown_menu"},
       {"Modal", "/components/modal"},
       {"Popover", "/components/popover"},
       {"Tooltip", "/components/tooltip"}
     ]},
    {"Feedback",
     [
       {"Alert", "/components/alert"},
       {"Flash", "/components/flash"},
       {"Flash (trigger)", "/components/flash/trigger"},
       {"FlashGroup", "/components/flash_group"}
     ]},
    {"Layout",
     [
       {"Card", "/components/card"},
       {"Divider", "/components/divider"},
       {"Header", "/components/header"},
       {"List", "/components/list"},
       {"Table (outline)", "/components/table/outline"},
       {"Table (ghost)", "/components/table/ghost"},
       {"Table (solid)", "/components/table/solid"}
     ]},
    {"Content",
     [
       {"Avatar", "/components/avatar"},
       {"Badge", "/components/badge"},
       {"Icon", "/components/icon"},
       {"Progress", "/components/progress"},
       {"Skeleton", "/components/skeleton"},
       {"Spinner", "/components/spinner"},
       {"Status", "/components/status"}
     ]}
  ]

  def fixtures, do: Enum.flat_map(@fixture_groups, fn {_group, items} -> items end)

  attr :current_path, :string, default: nil

  def fixture_nav(assigns) do
    assigns = assign(assigns, :groups, @fixture_groups)

    ~H"""
    <Menu.menu landmark={false} label="Fixtures" data-fixture-nav>
      <Menu.menu_section
        :for={{group, items} <- @groups}
        id={"fixnav-#{String.downcase(group)}"}
        label={group}
      >
        <Menu.menu_item
          :for={{label, path} <- items}
          navigate={path}
          active={@current_path == path}
        >
          {label}
        </Menu.menu_item>
      </Menu.menu_section>
    </Menu.menu>
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
