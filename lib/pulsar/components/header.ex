defmodule Pulsar.Components.Header do
  @moduledoc """
  Header component for page structure with title, subtitle, actions, and breadcrumb navigation.

  Provides styled page headers with semantic variants, consistent accessibility, and
  smart layout handling. All styling is applied via Tailwind CSS utilities with
  semantic color tokens that support both light and dark modes.

    ## Features

    - **Variants**: solid, outline, ghost for different visual emphasis levels
    - **Colors**: All semantic colors (neutral, primary, secondary, success, danger, warning, info)
    - **Typography Scaling**: Multiple sizes (xs, sm, md, lg, xl) for proper hierarchy
    - **Semantic Headings**: Configurable heading level (h1-h6) for proper document structure
    - **Breadcrumb Navigation**: Automatic chevron separators with ARIA support
    - **Responsive Layout**: Actions stack on mobile, inline on desktop
    - **Accessibility-First**: WCAG 2.2 AA compliance with proper ARIA attributes

  ## Examples

      # Simple header with default styling
      <.header>
        Dashboard
      </.header>

      # Header with subtitle
      <.header>
        User Management
        <:subtitle>
          Manage users, roles, and permissions
        </:subtitle>
      </.header>

      # Header with actions
      <.header>
        Products
        <:subtitle>
          {length(@products)} total products
        </:subtitle>
        <:actions>
          <.button variant="outline" color="neutral">Export</.button>
          <.button variant="solid" color="primary">Add Product</.button>
        </:actions>
      </.header>

        # Header with variant and color styling
        <.header variant="solid" color="primary" size="lg">
          Welcome Back!
          <:subtitle>
            Here's what's happening with your projects
          </:subtitle>
        </.header>

        # Section header with proper heading level
        <.header as="h2" size="lg">
          User Profile
          <:subtitle>
            Manage your account settings and preferences
          </:subtitle>
        </.header>

        # Minimal header with ghost variant
        <.header variant="ghost" size="sm">
          Settings
          <:actions>
            <.link navigate={~p"/help"}>Help</.link>
          </:actions>
        </.header>

      # Header with breadcrumb navigation
      <.header>
        <:breadcrumb navigate={~p"/"}>
          Home
        </:breadcrumb>
        <:breadcrumb navigate={~p"/products"}>
          Products
        </:breadcrumb>
        <:breadcrumb>
          Electronics
        </:breadcrumb>

        Electronics
        <:subtitle>
          Browse our selection of electronic products
        </:subtitle>
        <:actions>
          <.button>Add Product</.button>
        </:actions>
      </.header>

      # Sticky header with divider
      <.header sticky={true} divider={true} variant="outline">
        Article Title
        <:actions>
          <.button variant="ghost" size="sm">Edit</.button>
          <.button variant="ghost" size="sm">Share</.button>
        </:actions>
      </.header>

  ## Variants

  - **ghost** (default): Minimal styling with text-only emphasis
  - **outline**: Border styling with subtle background
  - **solid**: Full background color with strong visual emphasis

  ## Accessibility Features

  - **Semantic Structure**: Proper HTML5 header and heading elements
  - **Breadcrumb Navigation**: ARIA landmarks and navigation semantics
  - **Focus Management**: Proper tab order for interactive elements
  - **Screen Reader Support**: Descriptive labels and structure
  - **Color Contrast**: Sufficient contrast ratios for all variants
  """

  use Phoenix.Component

  import Pulsar.Components.Icon, only: [icon: 1]
  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Link

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for header typography
  @size_config %{
    "lg" => %{
      subtitle: "text-base text-muted-foreground",
      title: "text-3xl font-semibold"
    },
    "md" => %{
      subtitle: "text-sm text-muted-foreground",
      title: "text-2xl font-semibold"
    },
    "sm" => %{
      subtitle: "text-sm text-muted-foreground",
      title: "text-xl font-semibold"
    },
    "xl" => %{
      subtitle: "text-lg text-muted-foreground",
      title: "text-4xl font-semibold"
    },
    "xs" => %{
      subtitle: "text-xs text-muted-foreground",
      title: "text-lg font-semibold"
    }
  }

  # Base header styling classes
  @header_base_classes [
    "flex flex-col gap-4"
  ]

  # Color configuration for each variant
  @color_config %{
    "ghost" => %{
      "danger" => "text-danger",
      "info" => "text-info",
      "neutral" => "",
      "primary" => "text-primary",
      "secondary" => "text-secondary",
      "success" => "text-success",
      "warning" => "text-warning"
    },
    "outline" => %{
      "danger" => "border-b border-danger-200 pb-4 text-danger",
      "info" => "border-b border-info-200 pb-4 text-info",
      "neutral" => "border-b border-neutral-200 pb-4",
      "primary" => "border-b border-primary-200 pb-4 text-primary",
      "secondary" => "border-b border-secondary-200 pb-4 text-secondary",
      "success" => "border-b border-success-200 pb-4 text-success",
      "warning" => "border-b border-warning-200 pb-4 text-warning"
    },
    "solid" => %{
      "danger" => "bg-danger-100 text-danger-900 p-6 rounded-box",
      "info" => "bg-info-100 text-info-900 p-6 rounded-box",
      "neutral" => "bg-neutral-100 text-neutral-900 p-6 rounded-box",
      "primary" => "bg-primary-100 text-primary-900 p-6 rounded-box",
      "secondary" => "bg-secondary-100 text-secondary-900 p-6 rounded-box",
      "success" => "bg-success-100 text-success-900 p-6 rounded-box",
      "warning" => "bg-warning-100 text-warning-900 p-6 rounded-box"
    }
  }

  # ============================================================================
  # COMPONENT ATTRIBUTES
  # ============================================================================

  attr :variant, :string,
    default: "ghost",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the header"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the header"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the header text"

  attr :as, :string,
    default: "h1",
    values: ~w(h1 h2 h3 h4 h5 h6),
    doc: "HTML heading element to use for semantic structure"

  attr :sticky, :boolean,
    default: false,
    doc: "Whether header sticks to top of viewport when scrolling"

  attr :divider, :boolean,
    default: false,
    doc: "Show a divider line below the header (in addition to variant styling)"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  # ============================================================================
  # COMPONENT SLOTS
  # ============================================================================

  slot :inner_block,
    required: true,
    doc: "The main title content"

  slot :subtitle,
    doc: "Optional subtitle or description text"

  slot :actions,
    doc: "Optional actions like buttons or links, aligned to the right on desktop"

  slot :breadcrumb, doc: "Breadcrumb navigation items with automatic chevron separators" do
    attr :navigate, :any, doc: "Phoenix LiveView navigation path"
    attr :patch, :any, doc: "Phoenix LiveView patch path"
    attr :href, :string, doc: "Direct href for external links"
  end

  # ============================================================================
  # COMPONENT IMPLEMENTATION
  # ============================================================================

  @doc """
  Renders a page header with title, optional subtitle, actions, and breadcrumb navigation.
  """
  @spec header(map()) :: Rendered.t()
  def header(assigns) do
    validate_breadcrumbs!(assigns.breadcrumb)

    assigns =
      assigns
      |> assign(:size_classes, @size_config[assigns.size])
      |> assign(:merged_classes, build_header_classes(assigns))

    ~H"""
    <header class={@merged_classes} data-component="header" {@rest}>
      <nav :if={length(@breadcrumb) > 0} aria-label="Breadcrumb" data-role="breadcrumb">
        <ol class="flex items-center flex-wrap gap-1 text-sm text-muted-foreground">
          <li :for={{breadcrumb, index} <- Enum.with_index(@breadcrumb)} class="flex items-center">
            <.icon
              :if={index > 0}
              name="hero-chevron-right"
              variant="micro"
              size="xs"
              color="neutral"
              class="mx-1"
              aria-hidden="true"
            />
            <span
              :if={index == length(@breadcrumb) - 1}
              aria-current="page"
              class="font-medium text-foreground"
            >
              {render_slot(breadcrumb)}
            </span>
            <Link.a
              :if={index != length(@breadcrumb) - 1 && Map.get(breadcrumb, :navigate)}
              navigate={Map.get(breadcrumb, :navigate)}
              variant="ghost"
              color="muted"
              size="inherit"
            >
              {render_slot(breadcrumb)}
            </Link.a>
            <Link.a
              :if={index != length(@breadcrumb) - 1 && Map.get(breadcrumb, :patch)}
              patch={Map.get(breadcrumb, :patch)}
              variant="ghost"
              color="muted"
              size="inherit"
            >
              {render_slot(breadcrumb)}
            </Link.a>
            <Link.a
              :if={index != length(@breadcrumb) - 1 && Map.get(breadcrumb, :href)}
              href={Map.get(breadcrumb, :href)}
              variant="ghost"
              color="muted"
              size="inherit"
            >
              {render_slot(breadcrumb)}
            </Link.a>
            <span
              :if={
                index != length(@breadcrumb) - 1 && !Map.get(breadcrumb, :navigate) && !Map.get(breadcrumb, :patch) &&
                  !Map.get(breadcrumb, :href)
              }
              class="text-muted-foreground"
            >
              {render_slot(breadcrumb)}
            </span>
          </li>
        </ol>
      </nav>

      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4" data-role="content">
        <div class="flex-1 min-w-0" data-role="title">
          <.dynamic_tag tag_name={@as} class={@size_classes.title}>
            {render_slot(@inner_block)}
          </.dynamic_tag>
          <div :if={length(@subtitle) > 0} class={[@size_classes.subtitle, "mt-1"]}>
            {render_slot(@subtitle)}
          </div>
        </div>

        <div :if={length(@actions) > 0} class="flex-shrink-0" data-role="actions">
          <div class="flex items-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>
      </div>

      <hr :if={@divider && @variant != "outline"} class="border-border" />
    </header>
    """
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  # Build the merged CSS classes for the header
  defp build_header_classes(assigns) do
    merge([
      @header_base_classes,
      sticky_classes(assigns.sticky, assigns.size),
      variant_classes(assigns.variant, assigns.color),
      assigns.class
    ])
  end

  # Get variant-specific classes
  defp variant_classes(variant, color) do
    @color_config[variant][color]
  end

  # Get sticky positioning classes.
  #
  # When the header is sticky, focusable controls below it would be obscured
  # by the opaque header when scrolled into view via keyboard (WCAG 2.4.11).
  # The sibling/descendant scroll-margin pushes those controls clear of the
  # sticky band. Values approximate the per-size header height — consumers
  # who render dense breadcrumb + subtitle + actions stacks may want to also
  # set `scroll-padding-top` on `html` for an exact match.
  defp sticky_classes(true, size), do: "sticky top-0 z-docked bg-background #{sticky_scroll_margin(size)}"
  defp sticky_classes(false, _size), do: ""

  @sticky_scroll_margin %{
    "xs" => "[&~*]:scroll-mt-12 [&~*_*]:scroll-mt-12",
    "sm" => "[&~*]:scroll-mt-14 [&~*_*]:scroll-mt-14",
    "md" => "[&~*]:scroll-mt-16 [&~*_*]:scroll-mt-16",
    "lg" => "[&~*]:scroll-mt-20 [&~*_*]:scroll-mt-20",
    "xl" => "[&~*]:scroll-mt-24 [&~*_*]:scroll-mt-24"
  }

  defp sticky_scroll_margin(size), do: @sticky_scroll_margin[size] || @sticky_scroll_margin["md"]

  # Validate breadcrumb slots don't have multiple navigation props
  defp validate_breadcrumbs!(breadcrumbs) do
    Enum.each(breadcrumbs, fn breadcrumb ->
      nav_props = [
        {Map.get(breadcrumb, :navigate), :navigate},
        {Map.get(breadcrumb, :patch), :patch},
        {Map.get(breadcrumb, :href), :href}
      ]

      provided_props =
        nav_props
        |> Enum.filter(fn {value, _key} -> value != nil end)
        |> Enum.map(fn {_value, key} -> key end)

      if length(provided_props) > 1 do
        props_string = Enum.map_join(provided_props, ", ", &inspect/1)

        raise ArgumentError,
              "Breadcrumb can only have one navigation prop. Found: #{props_string}"
      end
    end)
  end
end
