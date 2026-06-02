defmodule Pulsar.Components.Sidebar do
  @moduledoc """
  Responsive, collapsible sidebar panel for app-shell navigation.

  Renders a `<nav>` landmark that sits beside your main content on large screens
  and becomes an off-canvas drawer with a tap-to-dismiss backdrop on small ones.
  Place a brand `:header`, navigation in the body, and an account `:footer` inside
  it, then toggle it from anywhere with the `toggle/2`, `show/2`, and `hide/2`
  helpers.

  ## Features

  - **Sides**: render on the `left` or `right`.
  - **Collapse modes**: `icon` shrinks to an icon rail, `offcanvas` hides the
    panel and lets content reflow, `none` stays fixed.
  - **Responsive drawer**: below the `lg` breakpoint the panel is an off-canvas
    drawer with a backdrop, focus trap, and Escape-to-close.
  - **Variants / colors / sizes**: the standard `variant`, `color`, and `size`
    axes, matching the rest of the library.

  ## Examples

      # Compose it next to your main content in a flex container
      <div class="flex min-h-svh">
        <.sidebar id="app-sidebar" collapsible="icon">
          <:header>
            <span class="font-semibold">Acme</span>
          </:header>

          <nav class="flex flex-col gap-1">
            <.link navigate={~p"/"} class="flex items-center gap-2 rounded-field px-2 py-1.5">
              <.icon name="hero-home" size="sm" />
              <span class="group-data-[state=collapsed]/sidebar:lg:hidden">Home</span>
            </.link>
          </nav>

          <:footer>
            <span class="text-sm text-muted-foreground">signed in</span>
          </:footer>
        </.sidebar>

        <main class="flex-1">...</main>
      </div>

      # Toggle from a button anywhere (e.g. a navbar). `Sidebar` is your
      # generated component module.
      <button phx-click={Sidebar.toggle("app-sidebar")} aria-controls="app-sidebar">
        Menu
      </button>

  ## Collapsible content

  The panel publishes its state on a `group/sidebar` element via `data-state`
  (`expanded` / `collapsed`). To make content fold into the icon rail, hide labels
  with the matching group variant while keeping their icons:

      <span class="group-data-[state=collapsed]/sidebar:lg:hidden">Reports</span>

  ## Accessibility

  - The panel is a `<nav>` landmark with an overridable `aria-label`.
  - As a mobile drawer it traps focus while open, closes on Escape or backdrop
    click, and returns focus to the element that opened it.
  - The toggle control should set `aria-controls` to the panel `id`.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  # Inline ID generator
  defp generate_id(prefix \\ "sidebar") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Expanded panel width and interior padding per size.
  @size_config %{
    "xs" => %{width: "w-48", header: "p-2", content: "p-2 gap-1", footer: "p-2"},
    "sm" => %{width: "w-56", header: "p-3", content: "p-3 gap-1", footer: "p-3"},
    "md" => %{width: "w-64", header: "p-4", content: "p-4 gap-1", footer: "p-4"},
    "lg" => %{width: "w-72", header: "p-5", content: "p-5 gap-1", footer: "p-5"},
    "xl" => %{width: "w-80", header: "p-6", content: "p-6 gap-1", footer: "p-6"}
  }

  # Layout, positioning, and the CSS contract shared by every sidebar.
  # Mobile: fixed off-canvas drawer above the backdrop. Desktop: in-flow column
  # so sibling content reflows on collapse. Mobile drawer transform uses
  # emphasized slow-in / accelerate fast-out; desktop collapse animates width.
  @panel_base_classes "group/sidebar peer/sidebar " <>
                        "flex flex-col shrink-0 h-svh overflow-hidden " <>
                        "focus-visible:outline-none " <>
                        "fixed inset-y-0 z-modal " <>
                        "lg:static lg:z-auto lg:translate-x-0 " <>
                        "transition-transform duration-fast ease-accelerate " <>
                        "data-[mobile=open]:duration-slow data-[mobile=open]:ease-emphasized " <>
                        "lg:transition-[width] lg:duration-normal lg:ease-emphasized"

  # Desktop collapse behaviour, keyed off the panel's own data attributes.
  @collapse_classes "data-[collapsible=icon]:data-[state=collapsed]:lg:w-16 " <>
                      "data-[collapsible=offcanvas]:data-[state=collapsed]:lg:w-0 " <>
                      "data-[collapsible=offcanvas]:data-[state=collapsed]:lg:border-0 " <>
                      "data-[collapsible=offcanvas]:data-[state=collapsed]:lg:overflow-hidden"

  # Backdrop shown only while the mobile drawer is open.
  @backdrop_classes [
    "fixed inset-0 z-overlay bg-foreground/50 lg:hidden",
    "opacity-0 pointer-events-none",
    # Exit timing by default; enter timing while the drawer is open.
    "transition-opacity duration-fast ease-accelerate",
    "peer-data-[mobile=open]/sidebar:opacity-100",
    "peer-data-[mobile=open]/sidebar:duration-normal peer-data-[mobile=open]/sidebar:ease-decelerate",
    "peer-data-[mobile=open]/sidebar:pointer-events-auto"
  ]

  @valid_variants ~w(solid outline ghost elevated)
  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Surface treatment per variant and color (semantic tokens only).
  @color_config %{
    "solid" => %{
      "neutral" => "bg-surface-1 text-foreground border-border-strong",
      "primary" => "bg-primary text-primary-foreground border-primary",
      "secondary" => "bg-secondary text-secondary-foreground border-secondary",
      "success" => "bg-success text-success-foreground border-success",
      "danger" => "bg-danger text-danger-foreground border-danger",
      "warning" => "bg-warning text-warning-foreground border-warning",
      "info" => "bg-info text-info-foreground border-info"
    },
    "outline" => %{
      "neutral" => "bg-surface-1 text-foreground border-border-strong",
      "primary" => "bg-surface-1 text-foreground border-primary",
      "secondary" => "bg-surface-1 text-foreground border-secondary",
      "success" => "bg-surface-1 text-foreground border-success",
      "danger" => "bg-surface-1 text-foreground border-danger",
      "warning" => "bg-surface-1 text-foreground border-warning",
      "info" => "bg-surface-1 text-foreground border-info"
    },
    "ghost" => %{
      "neutral" => "bg-transparent text-foreground border-transparent",
      "primary" => "bg-transparent text-foreground border-transparent",
      "secondary" => "bg-transparent text-foreground border-transparent",
      "success" => "bg-transparent text-foreground border-transparent",
      "danger" => "bg-transparent text-foreground border-transparent",
      "warning" => "bg-transparent text-foreground border-transparent",
      "info" => "bg-transparent text-foreground border-transparent"
    },
    "elevated" => %{
      "neutral" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "primary" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "secondary" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "success" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "danger" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "warning" => "bg-surface-1 text-foreground border-transparent shadow-dropdown",
      "info" => "bg-surface-1 text-foreground border-transparent shadow-dropdown"
    }
  }

  # Compile-time check that every variant/color combination is defined.
  for variant <- @valid_variants, color <- @valid_colors do
    if !get_in(@color_config, [variant, color]) do
      raise CompileError, description: "Missing color config for variant=#{variant}, color=#{color}"
    end
  end

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Panel ID (auto-generated if omitted). Targeted by the toggle helpers.")

  attr(:side, :string,
    default: "left",
    values: ~w(left right),
    doc: "Edge the sidebar is anchored to"
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style of the panel surface"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the panel"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Expanded panel width and interior padding"
  )

  attr(:open, :boolean,
    default: true,
    doc: "Initial expanded state on first render. The panel owns its state after mount."
  )

  attr(:collapsible, :string,
    default: "offcanvas",
    values: ~w(icon offcanvas none),
    doc: "Desktop collapse behaviour: shrink to an icon rail, hide off-canvas, or stay fixed"
  )

  attr(:label, :string,
    default: "Sidebar",
    doc: ~s{Accessible name for the navigation landmark. Use with i18n: gettext("Sidebar")}
  )

  attr(:on_open, JS,
    default: %JS{},
    doc: "JS commands to run when the panel opens/expands"
  )

  attr(:on_close, JS,
    default: %JS{},
    doc: "JS commands to run when the panel closes/collapses"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:header, doc: "Pinned top region (brand, logo)")
  slot(:inner_block, required: true, doc: "Scrollable main content (navigation)")
  slot(:footer, doc: "Pinned bottom region (account, status)")

  @doc """
  Renders a responsive, collapsible sidebar panel.

  Compose it inside a flex container next to your main content. It is a plain
  navigation panel — drive it with the `toggle/2`, `show/2`, and `hide/2` helpers
  from a trigger elsewhere on the page.

  ## Examples

      <.sidebar id="app-sidebar" side="left" collapsible="icon" color="neutral">
        <:header>Acme</:header>
        <nav>...</nav>
        <:footer>...</:footer>
      </.sidebar>
  """
  @spec sidebar(map()) :: Rendered.t()
  def sidebar(assigns) do
    assigns = assign_new(assigns, :id, fn -> generate_id() end)

    assigns =
      assign(
        assigns,
        :panel_classes,
        merge([
          base_classes(),
          collapse_classes(),
          side_classes(assigns.side),
          width_classes(assigns.size),
          color_classes(assigns.variant, assigns.color),
          assigns.class
        ])
      )

    ~H"""
    <nav
      id={@id}
      phx-hook=".PulsarSidebar"
      tabindex="-1"
      aria-label={@label}
      data-side={@side}
      data-collapsible={@collapsible}
      data-state={if @open, do: "expanded", else: "collapsed"}
      data-mobile="closed"
      data-on-open={@on_open}
      data-on-close={@on_close}
      class={@panel_classes}
      {@rest}
    >
      <div :if={@header != []} class={["shrink-0", header_classes(@size)]}>
        {render_slot(@header)}
      </div>

      <div class={["flex flex-col flex-1 min-h-0 overflow-y-auto", content_classes(@size)]}>
        {render_slot(@inner_block)}
      </div>

      <div :if={@footer != []} class={["shrink-0", footer_classes(@size)]}>
        {render_slot(@footer)}
      </div>
    </nav>

    <div
      data-sidebar-backdrop
      aria-hidden="true"
      phx-click={JS.dispatch("pulsar:sidebar-hide", to: "##{@id}")}
      class={backdrop_classes()}
    />

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarSidebar">
      const MOBILE_QUERY = "(max-width: 1023px)"
      const FOCUSABLE =
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

      export default {
        mounted() {
          this.mql = window.matchMedia(MOBILE_QUERY)
          this.state = this.el.dataset.state === "collapsed" ? "collapsed" : "expanded"
          this.mobileOpen = false
          this.previousFocus = null
          this.bodyOverflow = ""

          this._onToggle = () => this.toggle()
          this._onShow = () => this.show()
          this._onHide = () => this.hide()
          this._onKeydown = (e) => this.handleKeydown(e)

          this.el.addEventListener("pulsar:sidebar-toggle", this._onToggle)
          this.el.addEventListener("pulsar:sidebar-show", this._onShow)
          this.el.addEventListener("pulsar:sidebar-hide", this._onHide)
          this.el.addEventListener("keydown", this._onKeydown)
        },

        isMobile() {
          return this.mql.matches
        },

        toggle() {
          if (this.isMobile()) {
            this.mobileOpen ? this.closeDrawer() : this.openDrawer()
          } else {
            this.state === "expanded" ? this.collapse() : this.expand()
          }
        },

        show() {
          this.isMobile() ? this.openDrawer() : this.expand()
        },

        hide() {
          this.isMobile() ? this.closeDrawer() : this.collapse()
        },

        expand() {
          this.setState("expanded")
        },

        collapse() {
          this.setState("collapsed")
        },

        setState(value) {
          if (this.state === value) return
          this.state = value
          this.el.dataset.state = value
          this.runCallback(value === "expanded" ? "onOpen" : "onClose")
        },

        openDrawer() {
          if (this.mobileOpen) return
          this.mobileOpen = true
          this.previousFocus = document.activeElement
          this.el.dataset.mobile = "open"
          this.lockScroll()
          this.focusFirst()
          this.runCallback("onOpen")
        },

        closeDrawer() {
          if (!this.mobileOpen) return
          this.mobileOpen = false
          this.el.dataset.mobile = "closed"
          this.unlockScroll()
          if (this.previousFocus && this.previousFocus.focus) this.previousFocus.focus()
          this.previousFocus = null
          this.runCallback("onClose")
        },

        handleKeydown(e) {
          if (!this.isMobile() || !this.mobileOpen) return
          if (e.key === "Escape") {
            e.preventDefault()
            this.closeDrawer()
          } else if (e.key === "Tab") {
            this.trapFocus(e)
          }
        },

        focusableItems() {
          return Array.from(this.el.querySelectorAll(FOCUSABLE)).filter((el) => el.offsetParent !== null)
        },

        focusFirst() {
          const items = this.focusableItems()
          ;(items[0] || this.el).focus()
        },

        trapFocus(e) {
          const items = this.focusableItems()
          if (items.length === 0) {
            e.preventDefault()
            this.el.focus()
            return
          }
          const first = items[0]
          const last = items[items.length - 1]
          if (e.shiftKey && document.activeElement === first) {
            e.preventDefault()
            last.focus()
          } else if (!e.shiftKey && document.activeElement === last) {
            e.preventDefault()
            first.focus()
          }
        },

        lockScroll() {
          this.bodyOverflow = document.body.style.overflow
          document.body.style.overflow = "hidden"
        },

        unlockScroll() {
          document.body.style.overflow = this.bodyOverflow
        },

        runCallback(name) {
          const encoded = this.el.dataset[name]
          if (encoded && encoded !== "[]" && this.liveSocket) {
            this.liveSocket.execJS(this.el, encoded)
          }
        },

        updated() {
          this.el.dataset.state = this.state
          this.el.dataset.mobile = this.mobileOpen ? "open" : "closed"
        },

        destroyed() {
          this.unlockScroll()
          this.el.removeEventListener("pulsar:sidebar-toggle", this._onToggle)
          this.el.removeEventListener("pulsar:sidebar-show", this._onShow)
          this.el.removeEventListener("pulsar:sidebar-hide", this._onHide)
          this.el.removeEventListener("keydown", this._onKeydown)
        }
      }
    </script>
    """
  end

  @doc """
  Toggles the sidebar.

  Below the `lg` breakpoint this opens/closes the drawer; at or above it,
  expands/collapses the panel. Pass the panel `id`.

      <button phx-click={Sidebar.toggle("app-sidebar")}>Menu</button>
  """
  @spec toggle(JS.t(), String.t()) :: JS.t()
  def toggle(js \\ %JS{}, id) do
    JS.dispatch(js, "pulsar:sidebar-toggle", to: "##{id}")
  end

  @doc """
  Opens (mobile) or expands (desktop) the sidebar. Pass the panel `id`.
  """
  @spec show(JS.t(), String.t()) :: JS.t()
  def show(js \\ %JS{}, id) do
    JS.dispatch(js, "pulsar:sidebar-show", to: "##{id}")
  end

  @doc """
  Closes (mobile) or collapses (desktop) the sidebar. Pass the panel `id`.
  """
  @spec hide(JS.t(), String.t()) :: JS.t()
  def hide(js \\ %JS{}, id) do
    JS.dispatch(js, "pulsar:sidebar-hide", to: "##{id}")
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec base_classes() :: String.t()
  defp base_classes, do: @panel_base_classes

  @spec collapse_classes() :: String.t()
  defp collapse_classes, do: @collapse_classes

  @spec backdrop_classes() :: [String.t()]
  defp backdrop_classes, do: @backdrop_classes

  # Edge anchoring, separating border, and the off-canvas drawer transform.
  @spec side_classes(String.t()) :: String.t()
  defp side_classes("right") do
    "right-0 border-l data-[mobile=closed]:translate-x-full lg:data-[mobile=closed]:translate-x-0"
  end

  defp side_classes(_left) do
    "left-0 border-r data-[mobile=closed]:-translate-x-full lg:data-[mobile=closed]:translate-x-0"
  end

  @spec width_classes(String.t()) :: String.t()
  defp width_classes(size), do: @size_config[size][:width] || ""

  @spec color_classes(String.t(), String.t()) :: String.t()
  defp color_classes(variant, color), do: @color_config[variant][color] || ""

  @spec header_classes(String.t()) :: String.t()
  defp header_classes(size), do: @size_config[size][:header] || ""

  @spec content_classes(String.t()) :: String.t()
  defp content_classes(size), do: @size_config[size][:content] || ""

  @spec footer_classes(String.t()) :: String.t()
  defp footer_classes(size), do: @size_config[size][:footer] || ""
end
