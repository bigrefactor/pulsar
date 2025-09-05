defmodule Pulsar.Components.Icon do
  @moduledoc """
  Icon component supporting Heroicons with flexible sizing and coloring.

  Provides access to all Heroicons variants (outline, solid, mini, micro) with
  Pulsar's semantic color system and responsive sizing.

  ## Heroicons Variants

  - **outline**: 24×24 stroke-based icons (default)
  - **solid**: 24×24 filled icons
  - **mini**: 20×20 filled icons for compact interfaces
  - **micro**: 16×16 filled icons for very tight spaces

  ## Examples

      # Basic outline icon (decorative by default)
      <.icon name="hero-check" />

      # Solid variant with color
      <.icon name="hero-heart" variant="solid" color="danger" />

      # Micro icon scaled up
      <.icon name="hero-x-mark" variant="micro" size="lg" />

      # Current color (inherits from parent)
      <.icon name="hero-information-circle" color="current" />

      # Informative icon with accessible label
      <.icon name="hero-exclamation-triangle" color="warning" aria_label="Warning" />

  ## Size and Scaling

  The size attribute scales any variant:
  - `xs`: 12px (w-3 h-3)
  - `sm`: 16px (w-4 h-4)
  - `md`: 20px (w-5 h-5) - default
  - `lg`: 24px (w-6 h-6)
  - `xl`: 32px (w-8 h-8)

  ## Color System

  Uses Pulsar's semantic color tokens with automatic dark mode support.
  The `current` color inherits the text color from the parent element.

  ## Accessibility

  Icons are decorative by default with `aria-hidden="true"`. For informative icons
  that convey meaning, provide an `aria_label`:

      # Decorative icon (default)
      <.icon name="hero-star" />
      # Renders: <span aria-hidden="true" ... />

      # Informative icon
      <.icon name="hero-exclamation-triangle" aria_label="Warning" />
      # Renders: <span role="img" aria-label="Warning" ... />

  You can override the default behavior by setting `aria-hidden` in the rest attributes.
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  alias Phoenix.LiveView.Rendered

  # Size configuration for icon component
  @size_config %{
    "lg" => "w-6 h-6",
    "md" => "w-5 h-5",
    "sm" => "w-4 h-4",
    "xl" => "w-8 h-8",
    "xs" => "w-3 h-3"
  }

  # Color configuration for icon component
  @color_config %{
    "current" => "text-current",
    "danger" => "text-danger dark:text-dark-danger",
    "info" => "text-info dark:text-dark-info",
    "neutral" => "text-neutral dark:text-dark-neutral",
    "primary" => "text-primary dark:text-dark-primary",
    "secondary" => "text-secondary dark:text-dark-secondary",
    "success" => "text-success dark:text-dark-success",
    "warning" => "text-warning dark:text-dark-warning"
  }

  attr :name, :string,
    required: true,
    doc: "Heroicon name (e.g., 'hero-check', 'hero-x-mark')"

  attr :variant, :string,
    default: "outline",
    values: ~w(outline solid mini micro),
    doc: "Heroicon variant - which icon set to use"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Icon size - scales the icon via CSS"

  attr :color, :string,
    default: "current",
    values: ~w(current neutral primary secondary success danger warning info),
    doc: "Icon color using semantic color tokens"

  attr :aria_label, :string,
    default: nil,
    doc: "Accessible label for informative icons. When provided, icon becomes informative with role='img'"

  attr :aria_hidden, :string,
    default: nil,
    doc: "Override default aria-hidden behavior. Set to 'false' to make decorative icons visible to screen readers"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders an icon using Heroicons with Pulsar styling.

  Icons use CSS-based rendering for efficiency. The component automatically
  applies the correct Heroicon class name, size scaling, and semantic colors.
  """
  @spec icon(map()) :: Rendered.t()
  def icon(assigns) do
    assigns =
      assigns
      |> assign_classes()
      |> assign_aria_attributes()

    ~H"""
    <span class={@class} role={@role} aria-label={@computed_aria_label} aria-hidden={@computed_aria_hidden} {@rest} />
    """
  end

  # ============================================================================
  # ICON HELPER FUNCTIONS
  # ============================================================================

  # Build the Heroicon CSS class name based on icon name and variant
  defp build_heroicon_class(name, variant) do
    case {name, variant} do
      {"hero-" <> icon_name, "outline"} -> "hero-#{icon_name}"
      {"hero-" <> icon_name, "solid"} -> "hero-#{icon_name}-solid"
      {"hero-" <> icon_name, "mini"} -> "hero-#{icon_name}-mini"
      {"hero-" <> icon_name, "micro"} -> "hero-#{icon_name}-micro"
      # Pass through non-heroicon names
      {name, _} -> name
    end
  end

  # Get size classes from configuration map
  @spec get_size_classes(String.t()) :: String.t()
  defp get_size_classes(size) do
    @size_config[size]
  end

  # Get color classes from configuration map
  @spec get_color_classes(String.t()) :: String.t()
  defp get_color_classes(color) do
    @color_config[color]
  end

  # ============================================================================
  # ASSIGNMENT HELPERS
  # ============================================================================

  # Assign CSS classes with TailwindMerge
  defp assign_classes(assigns) do
    heroicon_class = build_heroicon_class(assigns.name, assigns.variant)

    class =
      merge([
        heroicon_class,
        get_size_classes(assigns.size),
        get_color_classes(assigns.color),
        assigns.class
      ])

    assign(assigns, :class, class)
  end

  # Assign computed ARIA attributes based on whether icon is decorative or informative
  defp assign_aria_attributes(assigns) do
    cond do
      # User explicitly set aria-hidden - respect their choice
      assigns.aria_hidden != nil ->
        assigns
        |> assign(:computed_aria_hidden, assigns.aria_hidden)
        |> assign(:computed_aria_label, assigns.aria_label)
        |> assign(:role, nil)

      # Has accessible label - make it informative
      assigns.aria_label != nil ->
        assigns
        |> assign(:computed_aria_hidden, nil)
        |> assign(:computed_aria_label, assigns.aria_label)
        |> assign(:role, "img")

      # Default - decorative icon
      true ->
        assigns
        |> assign(:computed_aria_hidden, "true")
        |> assign(:computed_aria_label, nil)
        |> assign(:role, nil)
    end
  end
end
