defmodule Pulsar.Components.Navbar do
  @moduledoc """
  Top app-bar for app-shell navigation.

  Renders a banner with `left`, `center`, and `right` regions you compose freely —
  brand, search field, navigation, notifications, a user menu. The navbar owns the
  surface, height, sticky positioning, and alignment; what goes in each region is
  up to you.

  Pair it with a sidebar by wiring `on_menu_toggle` to the sidebar's toggle helper.
  The navbar then renders a menu button that drives it.

  ## Examples

      <.navbar>
        <:left><span class="font-semibold">Acme</span></:left>
        <:right>
          <button class="rounded-field px-2 py-1.5">Account</button>
        </:right>
      </.navbar>

      # A centered search field, brand on the left, account on the right
      <.navbar>
        <:left><.logo /></:left>
        <:center>
          <input type="search" placeholder="Search" class="w-full max-w-sm rounded-field px-3 py-1.5" />
        </:center>
        <:right><.user_menu /></:right>
      </.navbar>

      # Drive a sidebar from the menu button (`Sidebar` is your generated module)
      <.navbar on_menu_toggle={Sidebar.toggle("app-sidebar")} menu_controls="app-sidebar">
        <:left><.logo /></:left>
      </.navbar>

      # Sticky to the top of the viewport
      <.navbar sticky>
        <:left>Acme</:left>
      </.navbar>
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # Inline ID generator
  defp generate_id(prefix \\ "navbar") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Bar height, horizontal padding, and the gap between regions per size.
  @size_config %{
    "xs" => "h-12 px-2 gap-2",
    "sm" => "h-14 px-3 gap-2",
    "md" => "h-16 px-4 gap-3",
    "lg" => "h-20 px-6 gap-4",
    "xl" => "h-24 px-8 gap-4"
  }

  # Layout and the surface contract shared by every navbar.
  @bar_base_classes [
    "relative flex items-center w-full",
    "border-b",
    "focus-visible:outline-none"
  ]

  # Menu button (hamburger): a square, comfortably-sized hit target.
  @menu_button_classes [
    "inline-flex items-center justify-center size-9 shrink-0 rounded-field",
    "transition-colors duration-fast ease-standard hover:bg-foreground/10",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
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

  # When the bar is sticky, focusable controls scrolled to below it would be
  # obscured. The sibling/descendant scroll-margin pushes those controls clear of
  # the sticky band. Values approximate the per-size bar height.
  @sticky_scroll_margin %{
    "xs" => "[&~*]:scroll-mt-12 [&~*_*]:scroll-mt-12",
    "sm" => "[&~*]:scroll-mt-14 [&~*_*]:scroll-mt-14",
    "md" => "[&~*]:scroll-mt-16 [&~*_*]:scroll-mt-16",
    "lg" => "[&~*]:scroll-mt-20 [&~*_*]:scroll-mt-20",
    "xl" => "[&~*]:scroll-mt-24 [&~*_*]:scroll-mt-24"
  }

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Banner ID (auto-generated if omitted)")

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style of the bar surface"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the bar"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Bar height, horizontal padding, and region gap"
  )

  attr(:sticky, :boolean,
    default: false,
    doc: "Pin the bar to the top of the viewport as content scrolls"
  )

  attr(:label, :string,
    default: nil,
    doc: ~s{Accessible name for the banner. Useful when a page has more than one. Use with i18n: gettext("...")}
  )

  attr(:on_menu_toggle, JS,
    default: %JS{},
    doc:
      ~s{JS commands run when the menu button is pressed. Renders the button when set, e.g. `Sidebar.toggle("app-sidebar")`.}
  )

  attr(:menu_label, :string,
    default: "Menu",
    doc: ~s{Accessible name for the menu button. Use with i18n: gettext("Menu")}
  )

  attr(:menu_controls, :string,
    default: nil,
    doc: ~s{`id` of the element the menu button controls (e.g. a sidebar), exposed as `aria-controls`}
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:left, doc: "Leading region (brand, logo, search)")
  slot(:center, doc: "Centered region")
  slot(:right, doc: "Trailing region (notifications, user menu)")

  @doc """
  Renders a top app-bar.

  Compose content into the `left`, `center`, and `right` regions. Provide
  `on_menu_toggle` to render a menu button that drives a sidebar or any other
  target.

  ## Examples

      <.navbar sticky>
        <:left>Acme</:left>
        <:right><.user_menu /></:right>
      </.navbar>
  """
  @spec navbar(map()) :: Rendered.t()
  def navbar(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> generate_id() end)
      |> assign(:show_menu, assigns.on_menu_toggle != %JS{})

    assigns =
      assign(
        assigns,
        :bar_classes,
        merge([
          bar_base_classes(),
          color_classes(assigns.variant, assigns.color),
          size_classes(assigns.size),
          sticky_classes(assigns.sticky, assigns.size),
          assigns.class
        ])
      )

    ~H"""
    <header id={@id} aria-label={@label} class={@bar_classes} {@rest}>
      <div :if={@show_menu or @left != []} class="flex items-center gap-2 shrink-0">
        <button
          :if={@show_menu}
          type="button"
          data-navbar-toggle
          phx-click={@on_menu_toggle}
          aria-label={@menu_label}
          aria-controls={@menu_controls}
          class={menu_button_classes()}
        >
          <Icon.icon name="hero-bars-3" size="md" />
        </button>
        <div :if={@left != []} class="flex items-center gap-2">
          {render_slot(@left)}
        </div>
      </div>

      <div class="flex flex-1 items-center justify-center min-w-0">
        {render_slot(@center)}
      </div>

      <div :if={@right != []} class="flex items-center justify-end gap-2 shrink-0">
        {render_slot(@right)}
      </div>
    </header>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec bar_base_classes() :: [String.t()]
  defp bar_base_classes, do: @bar_base_classes

  @spec menu_button_classes() :: [String.t()]
  defp menu_button_classes, do: @menu_button_classes

  @spec size_classes(String.t()) :: String.t()
  defp size_classes(size), do: @size_config[size]

  @spec color_classes(String.t(), String.t()) :: String.t()
  defp color_classes(variant, color), do: @color_config[variant][color]

  @spec sticky_classes(boolean(), String.t()) :: String.t()
  defp sticky_classes(true, size), do: "sticky top-0 z-docked #{sticky_scroll_margin(size)}"
  defp sticky_classes(false, _size), do: ""

  @spec sticky_scroll_margin(String.t()) :: String.t()
  defp sticky_scroll_margin(size), do: @sticky_scroll_margin[size] || @sticky_scroll_margin["md"]
end
