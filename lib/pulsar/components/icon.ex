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

      # Basic outline icon
      <.icon name="hero-check" />

      # Solid variant with color
      <.icon name="hero-heart" variant="solid" color="danger" />

      # Micro icon scaled up
      <.icon name="hero-x-mark" variant="micro" size="lg" />

      # Current color (inherits from parent)
      <.icon name="hero-information-circle" color="current" />

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
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

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

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders an icon using Heroicons with Pulsar styling.

  Icons use CSS-based rendering for efficiency. The component automatically
  applies the correct Heroicon class name, size scaling, and semantic colors.
  """
  def icon(assigns) do
    # Build the Heroicon class name
    heroicon_class = build_heroicon_class(assigns.name, assigns.variant)

    # Merge all classes
    class =
      merge([
        heroicon_class,
        get_size_classes(assigns.size),
        get_color_classes(assigns.color),
        assigns.class
      ])

    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class} {@rest} />
    """
  end

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

  # Size classes - scales any variant
  defp get_size_classes("xs"), do: "w-3 h-3"
  defp get_size_classes("sm"), do: "w-4 h-4"
  defp get_size_classes("md"), do: "w-5 h-5"
  defp get_size_classes("lg"), do: "w-6 h-6"
  defp get_size_classes("xl"), do: "w-8 h-8"

  # Color classes using semantic tokens with dark mode support
  defp get_color_classes("current"), do: "text-current"
  defp get_color_classes("neutral"), do: "text-neutral dark:text-dark-neutral"
  defp get_color_classes("primary"), do: "text-primary dark:text-dark-primary"
  defp get_color_classes("secondary"), do: "text-secondary dark:text-dark-secondary"
  defp get_color_classes("success"), do: "text-success dark:text-dark-success"
  defp get_color_classes("danger"), do: "text-danger dark:text-dark-danger"
  defp get_color_classes("warning"), do: "text-warning dark:text-dark-warning"
  defp get_color_classes("info"), do: "text-info dark:text-dark-info"
end
