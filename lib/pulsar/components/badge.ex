defmodule Pulsar.Components.Badge do
  @moduledoc """
  Badge component for displaying labels, tags, and status indicators.

  Provides styled badges with optional start and end addon content. Perfect for 
  tags, status indicators, and multi-select displays that need additional 
  interactivity or decoration.

  ## Features

  - **Multiple Variants**: solid, outline, and ghost for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Start/End Addons**: Add icons, buttons, or other content before or after text

  ## Examples

      # Simple badge
      <.badge>New</.badge>

      # Colored badge with variant
      <.badge color="primary" variant="outline">Featured</.badge>

      # Badge with status icon
      <.badge color="success">
        <:start_addon>
          <.icon name="hero-check-circle" variant="micro" size="xs" />
        </:start_addon>
        Completed
      </.badge>

      # Badge with remove button
      <.badge color="danger">
        Error
        <:end_addon>
          <button phx-click="remove_error">
            <.icon name="hero-x-mark" variant="micro" size="xs" />
          </button>
        </:end_addon>
      </.badge>

      # Badge with both start and end content
      <.badge color="info">
        <:start_addon>
          <.icon name="hero-star" variant="micro" size="xs" />
        </:start_addon>
        Featured
        <:end_addon>
          <button phx-click="remove_featured">
            <.icon name="hero-x-mark" variant="micro" size="xs" />
          </button>
        </:end_addon>
      </.badge>

  ## Composition

  The badge is a pure display component. All interactivity is added through
  the addon slots, giving you complete control over behavior and styling.
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the badge"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the badge"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the badge"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, required: true, doc: "Badge content"
  slot :start_addon, doc: "Content at the start of the badge (before text)"
  slot :end_addon, doc: "Content at the end of the badge (after text)"

  @doc """
  Renders a styled badge with optional start and end addon content.

  The badge uses semantic color tokens and supports all standard variants.
  Any interactivity is added through the addon slots.
  """
  def badge(assigns) do
    class =
      merge([
        base_badge_classes(),
        variant_classes(assigns.variant),
        color_classes(assigns.variant, assigns.color),
        size_classes(assigns.size),
        assigns.class
      ])

    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class} {@rest}>
      {render_slot(@start_addon)}
      {render_slot(@inner_block)}
      {render_slot(@end_addon)}
    </span>
    """
  end

  # Base styles shared by all badge variants
  defp base_badge_classes do
    "inline-flex items-center font-medium rounded-md transition-colors duration-200 focus-within:outline-none focus-within:ring-2 focus-within:ring-current focus-within:ring-offset-2"
  end

  # Variant-specific structure and borders
  defp variant_classes("outline"), do: "border"
  defp variant_classes(_), do: ""

  # Color classes by variant - following Pulsar color system
  defp color_classes("solid", "neutral"),
    do: "bg-neutral text-neutral-foreground dark:bg-dark-neutral dark:text-dark-neutral-foreground"

  defp color_classes("solid", "primary"),
    do: "bg-primary text-primary-foreground dark:bg-dark-primary dark:text-dark-primary-foreground"

  defp color_classes("solid", "secondary"),
    do: "bg-secondary text-secondary-foreground dark:bg-dark-secondary dark:text-dark-secondary-foreground"

  defp color_classes("solid", "success"),
    do: "bg-success text-success-foreground dark:bg-dark-success dark:text-dark-success-foreground"

  defp color_classes("solid", "danger"),
    do: "bg-danger text-danger-foreground dark:bg-dark-danger dark:text-dark-danger-foreground"

  defp color_classes("solid", "warning"),
    do: "bg-warning text-warning-foreground dark:bg-dark-warning dark:text-dark-warning-foreground"

  defp color_classes("solid", "info"),
    do: "bg-info text-info-foreground dark:bg-dark-info dark:text-dark-info-foreground"

  defp color_classes("outline", "neutral"),
    do:
      "border-border dark:border-dark-border text-neutral dark:text-dark-neutral bg-background dark:bg-dark-background"

  defp color_classes("outline", "primary"),
    do:
      "border-primary dark:border-dark-primary text-primary dark:text-dark-primary bg-background dark:bg-dark-background"

  defp color_classes("outline", "secondary"),
    do:
      "border-secondary dark:border-dark-secondary text-secondary dark:text-dark-secondary bg-background dark:bg-dark-background"

  defp color_classes("outline", "success"),
    do:
      "border-success dark:border-dark-success text-success dark:text-dark-success bg-background dark:bg-dark-background"

  defp color_classes("outline", "danger"),
    do: "border-danger dark:border-dark-danger text-danger dark:text-dark-danger bg-background dark:bg-dark-background"

  defp color_classes("outline", "warning"),
    do:
      "border-warning dark:border-dark-warning text-warning dark:text-dark-warning bg-background dark:bg-dark-background"

  defp color_classes("outline", "info"),
    do: "border-info dark:border-dark-info text-info dark:text-dark-info bg-background dark:bg-dark-background"

  defp color_classes("ghost", "neutral"),
    do: "text-neutral dark:text-dark-neutral hover:bg-neutral/10 dark:hover:bg-dark-neutral/10"

  defp color_classes("ghost", "primary"),
    do: "text-primary dark:text-dark-primary hover:bg-primary/10 dark:hover:bg-dark-primary/10"

  defp color_classes("ghost", "secondary"),
    do: "text-secondary dark:text-dark-secondary hover:bg-secondary/10 dark:hover:bg-dark-secondary/10"

  defp color_classes("ghost", "success"),
    do: "text-success dark:text-dark-success hover:bg-success/10 dark:hover:bg-dark-success/10"

  defp color_classes("ghost", "danger"),
    do: "text-danger dark:text-dark-danger hover:bg-danger/10 dark:hover:bg-dark-danger/10"

  defp color_classes("ghost", "warning"),
    do: "text-warning dark:text-dark-warning hover:bg-warning/10 dark:hover:bg-dark-warning/10"

  defp color_classes("ghost", "info"), do: "text-info dark:text-dark-info hover:bg-info/10 dark:hover:bg-dark-info/10"

  # Size classes with proper proportions
  defp size_classes("xs"), do: "text-xs px-2 py-0.5 gap-1"
  defp size_classes("sm"), do: "text-sm px-2 py-0.5 gap-1"
  defp size_classes("md"), do: "text-sm px-2.5 py-0.5 gap-1.5"
  defp size_classes("lg"), do: "text-base px-3 py-1 gap-1.5"
  defp size_classes("xl"), do: "text-lg px-3.5 py-1 gap-2"
end
