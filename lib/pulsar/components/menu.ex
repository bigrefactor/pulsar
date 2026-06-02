defmodule Pulsar.Components.Menu do
  @moduledoc """
  Orientation-aware navigation menu for app-shell navigation.

  Renders a list of navigation links with optional sections and collapsible
  groups. The same component works `vertical` (default) inside a sidebar and
  `horizontal` inside a top bar — the orientation flips the layout direction and
  the arrow-key affordance, and switches a group between an in-place disclosure
  and a dropdown popover.

  Compose it from `menu_item`, `menu_section`, and `menu_group`. Mark the current
  page with `active` on its item.

  Give each menu a distinct `label` when more than one appears on a page — two
  landmarks sharing a name (the `"Primary"` default) are harder to tell apart in a
  screen reader's landmark list.

  ## Examples

      # Vertical menu in a sidebar content slot
      <.menu label="Primary">
        <.menu_item navigate={~p"/"} icon="hero-home" active>Home</.menu_item>
        <.menu_item navigate={~p"/inbox"} icon="hero-inbox">
          Inbox
          <:trailing>9</:trailing>
        </.menu_item>

        <.menu_section label="Workspace">
          <.menu_item navigate={~p"/projects"} icon="hero-folder">Projects</.menu_item>
          <.menu_group label="Reports" icon="hero-chart-bar">
            <.menu_item navigate={~p"/reports/sales"}>Sales</.menu_item>
            <.menu_item navigate={~p"/reports/traffic"}>Traffic</.menu_item>
          </.menu_group>
        </.menu_section>
      </.menu>

      # Horizontal menu in a navbar region — groups open as dropdowns
      <.menu orientation="horizontal" label="Primary">
        <.menu_item navigate={~p"/"} active>Home</.menu_item>
        <.menu_group label="Products">
          <.menu_item navigate={~p"/products/app"}>App</.menu_item>
          <.menu_item navigate={~p"/products/api"}>API</.menu_item>
        </.menu_group>
      </.menu>

  ## Inside a sidebar

  Drop the menu into the sidebar's content slot with `landmark={false}` so it
  doesn't nest a second `<nav>` inside the sidebar's own landmark. Labels fold
  into the icon rail automatically when the sidebar collapses to `collapsible="icon"`.

      <.sidebar id="app-sidebar" collapsible="icon">
        <.menu landmark={false} label="Primary">
          <.menu_item navigate={~p"/"} icon="hero-home">Home</.menu_item>
        </.menu>
      </.sidebar>

  ## Accessibility

  - The menu is a `<nav>` landmark (overridable `label`) around a list of links;
    groups use the disclosure pattern (`aria-expanded` + `aria-controls`).
  - The active item carries `aria-current="page"`.
  - Arrow keys move focus between items (Up/Down when vertical, Left/Right when
    horizontal); Enter/Space toggles a group; Escape closes an open horizontal
    dropdown and returns focus to its trigger.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # Inline ID generator
  defp generate_id(prefix \\ "menu") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Shared row treatment for items and group triggers. Text color is inherited
  # from the host surface (text-inherit) so the menu reads correctly on a neutral
  # panel or a colored sidebar/navbar alike; the active row supplies its own pair.
  # Horizontal rows size to content; collapsed sidebar rail centers the icon.
  @row_base "flex w-full items-center gap-2 rounded-field px-3 py-2 text-sm text-inherit no-underline " <>
              "hover:bg-foreground/10 " <>
              "transition-colors duration-fast ease-standard " <>
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 " <>
              "group-data-[orientation=horizontal]/menu:w-auto " <>
              "group-data-[state=collapsed]/sidebar:lg:justify-center"

  # Active item / group treatment, applied via the aria-current attribute.
  @row_active "aria-[current=page]:bg-primary aria-[current=page]:text-primary-foreground aria-[current=page]:font-medium"

  # Label span: truncates, and folds visually away in the collapsed sidebar icon
  # rail while staying the row's accessible name (sr-only, not display:none).
  @label_classes "min-w-0 truncate group-data-[state=collapsed]/sidebar:lg:sr-only"

  # Trailing affordance: pinned to the row end, folds away in the icon rail.
  @trailing_classes "ml-auto inline-flex shrink-0 items-center group-data-[state=collapsed]/sidebar:lg:hidden"

  # Section label: small caps heading naming the grouped list.
  @section_label_classes "px-3 pb-1 pt-3 text-xs font-medium uppercase tracking-wide text-muted-foreground group-data-[state=collapsed]/sidebar:lg:hidden"

  # Disclosure chevron: rotates when the group is expanded.
  @chevron_classes "ml-auto shrink-0 transition-transform duration-fast ease-standard group-data-[expanded]/disclosure:rotate-180 group-data-[orientation=horizontal]/menu:ml-1 group-data-[state=collapsed]/sidebar:lg:hidden"

  # Group panel wrapper. Vertical: an in-flow height disclosure. Horizontal: a
  # dropdown popover anchored under the trigger, toggled via display so a closed
  # dropdown takes no layout space (and never widens the page at narrow widths).
  @disclosure_wrapper [
    "grid grid-rows-[0fr] group-data-[expanded]/disclosure:grid-rows-[1fr]",
    "transition-[grid-template-rows] duration-normal ease-emphasized motion-reduce:transition-none",
    "group-data-[orientation=horizontal]/menu:absolute group-data-[orientation=horizontal]/menu:left-0 group-data-[orientation=horizontal]/menu:top-full",
    "group-data-[orientation=horizontal]/menu:z-dropdown group-data-[orientation=horizontal]/menu:mt-1 group-data-[orientation=horizontal]/menu:min-w-48",
    "group-data-[orientation=horizontal]/menu:rounded-box group-data-[orientation=horizontal]/menu:border group-data-[orientation=horizontal]/menu:border-border group-data-[orientation=horizontal]/menu:bg-surface-1 group-data-[orientation=horizontal]/menu:p-1 group-data-[orientation=horizontal]/menu:shadow-dropdown",
    "group-data-[orientation=horizontal]/menu:hidden group-data-[orientation=horizontal]/menu:group-data-[expanded]/disclosure:block"
  ]

  # Group panel list. Hidden from focus order until expanded; indents under the
  # parent in vertical layout.
  @disclosure_list [
    "overflow-hidden invisible group-data-[expanded]/disclosure:visible",
    "flex flex-col gap-0.5",
    "group-data-[orientation=vertical]/menu:pl-3 group-data-[orientation=vertical]/menu:pt-0.5"
  ]

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Menu ID (auto-generated if omitted). Targeted by the keyboard/disclosure behavior.")

  attr(:orientation, :string,
    default: "vertical",
    values: ~w(vertical horizontal),
    doc: "Layout direction. vertical for a sidebar, horizontal for a top bar."
  )

  attr(:label, :string,
    default: "Primary",
    doc: ~s{Accessible name for the navigation landmark. Use with i18n: gettext("Primary")}
  )

  attr(:landmark, :boolean,
    default: true,
    doc: "Wrap the list in a `<nav>` landmark. Set false when nesting inside an existing nav landmark (e.g. a sidebar)."
  )

  attr(:on_group_open, JS,
    default: %JS{},
    doc: "JS commands to run when a group expands"
  )

  attr(:on_group_close, JS,
    default: %JS{},
    doc: "JS commands to run when a group collapses"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Menu items, sections, and groups")

  @doc """
  Renders an orientation-aware navigation menu.

  Compose it from `menu_item/1`, `menu_section/1`, and `menu_group/1`.

  ## Examples

      <.menu label="Primary">
        <.menu_item navigate={~p"/"} icon="hero-home" active>Home</.menu_item>
      </.menu>
  """
  @spec menu(map()) :: Rendered.t()
  def menu(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> generate_id() end)
      |> assign(:list_classes, merge([list_base(assigns.orientation), assigns.class]))

    ~H"""
    <.menu_landmark landmark={@landmark} label={@label}>
      <ul
        id={@id}
        role="list"
        aria-label={(!@landmark && @label) || nil}
        phx-hook=".PulsarMenu"
        data-orientation={@orientation}
        data-on-group-open={@on_group_open}
        data-on-group-close={@on_group_close}
        class={["group/menu", @list_classes]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </ul>
    </.menu_landmark>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarMenu">
      export default {
        mounted() {
          this.orientation = this.el.dataset.orientation === "horizontal" ? "horizontal" : "vertical"
          this.expanded = new Set()
          this.el.querySelectorAll("[data-menu-group][data-expanded]").forEach((group) => {
            if (group.id) this.expanded.add(group.id)
          })
          this._onClick = (e) => this.handleClick(e)
          this._onKeydown = (e) => this.handleKeydown(e)
          this._onDocPointer = (e) => this.handleDocPointer(e)
          this.el.addEventListener("click", this._onClick)
          this.el.addEventListener("keydown", this._onKeydown)
          document.addEventListener("pointerdown", this._onDocPointer)
        },

        updated() {
          this.orientation = this.el.dataset.orientation === "horizontal" ? "horizontal" : "vertical"
          this.restoreExpanded()
        },

        // A LiveView re-render reconciles aria-expanded/data-expanded back to the
        // server-rendered @open and strips client-added attributes. Re-apply the
        // expand state the user drove on the client so open groups stay open.
        restoreExpanded() {
          this.el.querySelectorAll("[data-menu-group]").forEach((group) => {
            if (!group.id) return
            const open = this.expanded.has(group.id)
            const trigger = group.querySelector("[data-menu-trigger]")
            if (open) {
              group.setAttribute("data-expanded", "")
              if (trigger) trigger.setAttribute("aria-expanded", "true")
            } else {
              group.removeAttribute("data-expanded")
              if (trigger) trigger.setAttribute("aria-expanded", "false")
            }
          })
        },

        handleClick(e) {
          const trigger = e.target.closest("[data-menu-trigger]")
          if (trigger && this.el.contains(trigger)) {
            e.preventDefault()
            this.toggleGroup(trigger)
          }
        },

        toggleGroup(trigger) {
          const group = trigger.closest("[data-menu-group]")
          if (!group) return
          group.hasAttribute("data-expanded")
            ? this.closeGroup(group, trigger)
            : this.openGroup(group, trigger)
        },

        openGroup(group, trigger) {
          if (this.orientation === "horizontal") this.closeAll(group)
          group.setAttribute("data-expanded", "")
          trigger.setAttribute("aria-expanded", "true")
          if (group.id) this.expanded.add(group.id)
          this.runCallback("onGroupOpen")
        },

        closeGroup(group, trigger) {
          // Closing a panel that holds focus would strand the user on a hidden
          // element, so return focus to the trigger (APG disclosure guidance).
          const hadFocus = group.contains(document.activeElement)
          group.removeAttribute("data-expanded")
          if (trigger) trigger.setAttribute("aria-expanded", "false")
          if (group.id) this.expanded.delete(group.id)
          if (hadFocus && trigger) trigger.focus()
          this.runCallback("onGroupClose")
        },

        closeAll(except) {
          this.el.querySelectorAll("[data-menu-group][data-expanded]").forEach((group) => {
            if (group === except) return
            // Don't close an ancestor of the group being opened (nested groups).
            if (except && group.contains(except)) return
            this.closeGroup(group, group.querySelector("[data-menu-trigger]"))
          })
        },

        handleKeydown(e) {
          if (e.key === "Escape" && this.orientation === "horizontal") {
            const open = e.target.closest("[data-menu-group][data-expanded]")
            if (open) {
              e.preventDefault()
              this.closeGroup(open, open.querySelector("[data-menu-trigger]"))
              return
            }
          }

          const next = this.orientation === "horizontal" ? "ArrowRight" : "ArrowDown"
          const prev = this.orientation === "horizontal" ? "ArrowLeft" : "ArrowUp"

          if (e.key === next || e.key === prev) {
            const items = this.focusables()
            const idx = items.indexOf(document.activeElement)
            if (idx === -1) return
            e.preventDefault()
            const delta = e.key === next ? 1 : -1
            const target = items[(idx + delta + items.length) % items.length]
            if (target) target.focus()
          } else if (e.key === "Home") {
            const items = this.focusables()
            if (items.length) {
              e.preventDefault()
              items[0].focus()
            }
          } else if (e.key === "End") {
            const items = this.focusables()
            if (items.length) {
              e.preventDefault()
              items[items.length - 1].focus()
            }
          }
        },

        focusables() {
          return Array.from(this.el.querySelectorAll("[data-menu-item]")).filter((el) => this.isVisible(el))
        },

        isVisible(el) {
          if (typeof el.checkVisibility === "function") {
            return el.checkVisibility({opacityProperty: true, visibilityProperty: true})
          }
          // offsetParent misses visibility:hidden — collapsed groups hide via
          // `invisible` (vertical) so check computed visibility too.
          if (el.offsetParent === null) return false
          return getComputedStyle(el).visibility !== "hidden"
        },

        handleDocPointer(e) {
          if (this.orientation !== "horizontal") return
          if (this.el.contains(e.target)) return
          this.closeAll(null)
        },

        runCallback(name) {
          const encoded = this.el.dataset[name]
          if (encoded && encoded !== "[]" && this.liveSocket) {
            this.liveSocket.execJS(this.el, encoded)
          }
        },

        destroyed() {
          this.el.removeEventListener("click", this._onClick)
          this.el.removeEventListener("keydown", this._onKeydown)
          document.removeEventListener("pointerdown", this._onDocPointer)
        }
      }
    </script>
    """
  end

  attr(:landmark, :boolean, required: true)
  attr(:label, :string, default: nil)
  slot(:inner_block, required: true)

  # Wraps the list in a `<nav>` landmark when requested; renders the list bare
  # otherwise (the caller moves `aria-label` onto the list itself in that case).
  @spec menu_landmark(map()) :: Rendered.t()
  defp menu_landmark(assigns) do
    ~H"""
    <nav :if={@landmark} aria-label={@label}>{render_slot(@inner_block)}</nav>
    {if !@landmark, do: render_slot(@inner_block)}
    """
  end

  attr(:navigate, :any, default: nil, doc: "Phoenix route to navigate to (string or VerifiedRoute)")
  attr(:patch, :any, default: nil, doc: "Phoenix route to patch navigate to (string or VerifiedRoute)")
  attr(:href, :string, default: nil, doc: "URL to link to. Renders an action button when no target is given.")

  attr(:active, :boolean,
    default: false,
    doc: "Marks the item as the current page (`aria-current=\"page\"`)"
  )

  attr(:icon, :string, default: nil, doc: ~s{Leading Heroicon name, e.g. "hero-home"})

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes (e.g. phx-click on an action item)")

  slot(:inner_block, required: true, doc: "Item label")
  slot(:trailing, doc: "Trailing affordance (badge, count, chevron)")

  @doc """
  Renders a menu item — a navigation link, or an action button when no target is given.

  ## Examples

      <.menu_item navigate={~p"/"} icon="hero-home" active>Home</.menu_item>
      <.menu_item href="/docs">Docs</.menu_item>
      <.menu_item phx-click="sign_out">Sign out</.menu_item>
  """
  @spec menu_item(map()) :: Rendered.t()
  def menu_item(assigns) do
    assigns =
      assigns
      |> assign(:link?, assigns.navigate != nil or assigns.patch != nil or assigns.href != nil)
      |> assign(:aria_current, if(assigns.active, do: "page"))
      |> assign(:row_classes, merge([@row_base, @row_active, assigns.class]))

    ~H"""
    <li class="group-data-[orientation=horizontal]/menu:shrink-0">
      <.link
        :if={@link?}
        navigate={@navigate}
        patch={@patch}
        href={@href}
        aria-current={@aria_current}
        data-menu-item
        class={@row_classes}
        {@rest}
      >
        <Icon.icon :if={@icon} name={@icon} size="sm" class="shrink-0" />
        <span class={label_classes()}>{render_slot(@inner_block)}</span>
        <span :if={@trailing != []} class={trailing_classes()}>{render_slot(@trailing)}</span>
      </.link>

      <button
        :if={!@link?}
        type="button"
        aria-current={@aria_current}
        data-menu-item
        class={@row_classes}
        {@rest}
      >
        <Icon.icon :if={@icon} name={@icon} size="sm" class="shrink-0" />
        <span class={label_classes()}>{render_slot(@inner_block)}</span>
        <span :if={@trailing != []} class={trailing_classes()}>{render_slot(@trailing)}</span>
      </button>
    </li>
    """
  end

  attr(:id, :string, doc: "Section ID (auto-generated if omitted), used to label the grouped list")
  attr(:label, :string, default: nil, doc: ~s{Optional section heading. Use with i18n: gettext("...")})
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Items and groups in this section")

  @doc """
  Renders a labelled section grouping a set of items.

  ## Examples

      <.menu_section label="Workspace">
        <.menu_item navigate={~p"/projects"}>Projects</.menu_item>
      </.menu_section>
  """
  @spec menu_section(map()) :: Rendered.t()
  def menu_section(assigns) do
    assigns = assign_new(assigns, :id, fn -> generate_id("menu-section") end)

    ~H"""
    <li class={["list-none", @class]} {@rest}>
      <p :if={@label} id={"#{@id}-label"} class={section_label_classes()}>{@label}</p>
      <ul role="list" aria-labelledby={@label && "#{@id}-label"} class={section_list_classes()}>
        {render_slot(@inner_block)}
      </ul>
    </li>
    """
  end

  attr(:id, :string, doc: "Group ID (auto-generated if omitted), wires the trigger to its panel")
  attr(:label, :string, required: true, doc: ~s{Group label shown on the trigger. Use with i18n: gettext("...")})
  attr(:icon, :string, default: nil, doc: ~s{Leading Heroicon name, e.g. "hero-chart-bar"})
  attr(:open, :boolean, default: false, doc: "Initial expanded state")

  attr(:active, :boolean,
    default: false,
    doc: "Highlights the trigger when the group contains the current page"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Child items")

  @doc """
  Renders a collapsible group — an in-place disclosure when vertical, a dropdown
  popover when horizontal.

  ## Examples

      <.menu_group label="Reports" icon="hero-chart-bar">
        <.menu_item navigate={~p"/reports/sales"}>Sales</.menu_item>
      </.menu_group>
  """
  @spec menu_group(map()) :: Rendered.t()
  def menu_group(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> generate_id("menu-group") end)
      |> assign(:trigger_classes, merge([@row_base, trigger_active(assigns.active), assigns.class]))

    ~H"""
    <li id={@id} class="group/disclosure relative list-none" data-menu-group data-expanded={(@open && "") || nil} {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        data-menu-trigger
        data-menu-item
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-panel"}
        class={@trigger_classes}
      >
        <Icon.icon :if={@icon} name={@icon} size="sm" class="shrink-0" />
        <span class={label_classes()}>{@label}</span>
        <Icon.icon name="hero-chevron-down" size="xs" class={chevron_classes()} />
      </button>

      <div class={disclosure_wrapper_classes()}>
        <ul id={"#{@id}-panel"} role="list" data-menu-panel class={disclosure_list_classes()}>
          {render_slot(@inner_block)}
        </ul>
      </div>
    </li>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec list_base(String.t()) :: String.t()
  defp list_base("horizontal"), do: "flex flex-row items-center gap-1"
  defp list_base(_vertical), do: "flex flex-col gap-0.5"

  @spec label_classes() :: String.t()
  defp label_classes, do: @label_classes

  @spec trailing_classes() :: String.t()
  defp trailing_classes, do: @trailing_classes

  @spec section_label_classes() :: String.t()
  defp section_label_classes, do: @section_label_classes

  @spec chevron_classes() :: String.t()
  defp chevron_classes, do: @chevron_classes

  @spec section_list_classes() :: String.t()
  defp section_list_classes do
    "flex flex-col gap-0.5 group-data-[orientation=horizontal]/menu:flex-row group-data-[orientation=horizontal]/menu:items-center"
  end

  @spec disclosure_wrapper_classes() :: [String.t()]
  defp disclosure_wrapper_classes, do: @disclosure_wrapper

  @spec disclosure_list_classes() :: [String.t()]
  defp disclosure_list_classes, do: @disclosure_list

  @spec trigger_active(boolean()) :: String.t()
  defp trigger_active(true), do: "bg-primary text-primary-foreground font-medium"
  defp trigger_active(false), do: ""
end
