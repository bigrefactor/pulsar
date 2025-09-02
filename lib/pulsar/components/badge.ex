defmodule Pulsar.Components.Badge do
  @moduledoc """
  Badge component for displaying labels, tags, and status indicators.

  Provides styled badges with optional remove functionality, using the Icon
  component for remove buttons. Perfect for tags, status indicators, and
  multi-select displays.

  ## Features

  - **Multiple Variants**: solid, outline, and ghost for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Removable Option**: Optional remove button with smooth animations
  - **Custom Actions**: Slot for additional buttons or content
  - **Phoenix Integration**: Built-in LiveView JS commands for removal
  - **Accessible**: Proper ARIA labels for remove functionality

  ## Examples

      # Simple badge
      <.badge>New</.badge>

      # Colored badge with variant
      <.badge color="primary" variant="outline">Featured</.badge>

      # Removable badge with custom removal
      <.badge removable on_remove={JS.push("remove_tag") |> JS.hide(to: "#badge-1")}>
        Phoenix
      </.badge>

      # Size variations
      <.badge size="lg" color="success">Completed</.badge>

      # With custom action slot
      <.badge>
        Important
        <:action>
          <button type="button" class="ml-1">
            <.icon name="hero-information-circle" size="sm" />
          </button>
        </:action>
      </.badge>

  ## Removable Badges

  When `removable` is true, badges automatically include a remove button with
  proper accessibility features. The default removal includes a smooth transition.

  ## Dependencies

  This component uses `Pulsar.Components.Icon` for remove buttons. Ensure Icon
  is available in your application.
  """

  use Phoenix.Component

  import Pulsar.Components.Icon, only: [icon: 1]
  import TailwindMerge, only: [merge: 1]

  alias Phoenix.LiveView.JS

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

  attr :removable, :boolean,
    default: false,
    doc: "Add remove button to badge"

  attr :remove_aria_label, :string,
    default: "Remove badge",
    doc: "Accessible label for the remove button"

  attr :on_remove, :any,
    default: nil,
    doc: "Phoenix.LiveView.JS command for removal, or event name string"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, required: true, doc: "Badge content"
  slot :action, doc: "Optional custom action buttons"

  @doc """
  Renders a styled badge with optional remove functionality.

  The badge uses semantic color tokens and supports all standard variants.
  When removable is true, automatically includes a properly labeled remove button.
  """
  def badge(assigns) do
    # Determine the remove handler
    remove_js =
      case assigns.on_remove do
        nil -> default_remove_js()
        %JS{} = js -> js
        event_name when is_binary(event_name) -> JS.push(event_name)
        _ -> default_remove_js()
      end

    # Build classes
    class =
      merge([
        get_badge_classes(assigns.variant, assigns.color, assigns.size),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:remove_js, remove_js)
      |> assign(:remove_icon_size, get_remove_icon_size(assigns.size))

    ~H"""
    <span class={@class} {@rest}>
      {render_slot(@inner_block)}
      
    <!-- Removable button -->
      <button
        :if={@removable}
        type="button"
        class="ml-1.5 -mr-1 hover:bg-black/10 dark:hover:bg-white/10 rounded-full p-0.5 focus:outline-none focus:ring-1 focus:ring-current transition-colors cursor-pointer"
        aria-label={@remove_aria_label}
        phx-click={@remove_js}
      >
        <.icon name="hero-x-mark" variant="micro" size={@remove_icon_size} color="current" aria-hidden="true" />
      </button>
      
    <!-- Custom action slot -->
      {render_slot(@action)}
    </span>
    """
  end

  # Default removal JS with smooth transition
  defp default_remove_js do
    JS.transition(
      "transition-all transform ease-out duration-200",
      to: :target,
      time: 200
    )
    |> JS.add_class("scale-95 opacity-0", to: :target)
    |> JS.hide(time: 200, to: :target)
  end

  # Modular badge styling system
  defp get_badge_classes(variant, color, size) do
    merge([
      base_badge_classes(),
      variant_classes(variant),
      color_classes(variant, color),
      size_classes(size)
    ])
  end

  # Base styles shared by all badge variants
  defp base_badge_classes do
    "inline-flex items-center font-medium transition-colors duration-200 focus-within:outline-none focus-within:ring-2 focus-within:ring-current focus-within:ring-offset-2"
  end

  # Variant-specific structure and borders
  defp variant_classes("solid"), do: "rounded-md"
  defp variant_classes("outline"), do: "rounded-md border"
  defp variant_classes("ghost"), do: "rounded-md"

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

  # Remove icon size mapping
  defp get_remove_icon_size("xs"), do: "xs"
  defp get_remove_icon_size("sm"), do: "xs"
  defp get_remove_icon_size("md"), do: "sm"
  defp get_remove_icon_size("lg"), do: "sm"
  defp get_remove_icon_size("xl"), do: "md"
end
