defmodule Pulsar.Components.Badge do
  @moduledoc """
  Badge component for displaying labels, tags, and removable tokens.

  Provides styled badges with optional start and end addon content, and an
  optional built-in remove control. Perfect for tags, status indicators, filter
  chips, and multi-select tokens.

  ## Features

  - **Multiple Variants**: solid, outline, and ghost for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Start/End Addons**: Add icons, buttons, or other content before or after text
  - **Removable**: `on_remove` renders a labeled dismiss control
  - **Interactive Labels**: `as={:div}` lets the badge host a popover panel

  ## Examples

      # Simple badge
      <.badge>New</.badge>

      # Colored badge with variant
      <.badge color="primary" variant="outline">Featured</.badge>

      # Badge with status icon
      <.badge color="success">
        <:start_addon>
          <.icon name="hero-check-circle-micro" size="xs" />
        </:start_addon>
        Completed
      </.badge>

      # Removable token
      <.badge on_remove={JS.push("remove_tag", value: %{id: 7})} remove_label={gettext("Remove tag Draft")}>
        Draft
      </.badge>

      # Badge with both start and end content
      <.badge color="info">
        <:start_addon>
          <.icon name="hero-star-micro" size="xs" />
        </:start_addon>
        Featured
        <:end_addon>12</:end_addon>
      </.badge>

  ## Two-action tokens

  A filter chip has two targets: the label edits what the token matches, the
  dismiss control removes it. Render the label as a button and pair it with
  `on_remove`. Both controls get their own 24px pointer target and focus ring, so
  it stays clear which one is focused.

      <.badge on_remove={JS.patch(~p"/widgets")} remove_label={gettext("Remove filter Status")}>
        <button type="button" phx-click="edit_filter">Status: Published</button>
      </.badge>

  Pass `as={:div}` when the label opens a popover. A popover panel is a `<div>`,
  which is not legal inside the default `<span>`:

      <.badge as={:div} on_remove={JS.patch(~p"/widgets")} remove_label={gettext("Remove filter Status")}>
        <.popover id="filter-status-panel">
          <:trigger><button type="button">Status: Published</button></:trigger>
          <.filter_editor />
        </.popover>
      </.badge>

  ## Composition

  Beyond `on_remove`, interactivity comes from the slots. A `<button>` or `<a>`
  placed directly in a slot picks up the badge's control styling; nested content
  (such as the inside of a hosted popover panel) is left alone.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  # Size configuration for badges
  @size_config %{
    "lg" => "text-base px-3 py-1 gap-1.5",
    "md" => "text-sm px-2.5 py-0.5 gap-1.5",
    "sm" => "text-sm px-2 py-0.5 gap-1",
    "xl" => "text-lg px-3.5 py-1 gap-2",
    "xs" => "text-xs px-2 py-0.5 gap-1"
  }

  # Base badge styling classes
  @badge_base_classes "inline-flex items-center font-medium rounded-field " <>
                        "transition-colors duration-fast ease-standard"

  # Styling for interactive controls the badge contains: a guaranteed ≥24px
  # pointer target (WCAG 2.5.8) and a focus ring on the control itself, so a token
  # carrying two controls shows which one has focus. Scoped to direct children, so
  # it reaches a control placed in a slot but never the contents of a popover
  # panel the badge hosts. Plain content (icons, status dots) is left untouched.
  @control_classes "[&>button]:inline-flex [&>button]:items-center [&>button]:justify-center " <>
                     "[&>button]:min-h-6 [&>button]:min-w-6 [&>button]:rounded-field " <>
                     "[&>button]:hover:bg-current/10 [&>button]:focus-visible:outline-none " <>
                     "[&>button]:focus-visible:ring-2 [&>button]:focus-visible:ring-current " <>
                     "[&>a]:inline-flex [&>a]:items-center [&>a]:justify-center " <>
                     "[&>a]:min-h-6 [&>a]:min-w-6 [&>a]:rounded-field " <>
                     "[&>a]:hover:bg-current/10 [&>a]:focus-visible:outline-none " <>
                     "[&>a]:focus-visible:ring-2 [&>a]:focus-visible:ring-current"

  # Addon slots wrap their content, so they carry the control styling for their
  # own children.
  @addon_classes "inline-flex items-center " <> @control_classes

  # Color configuration for each variant
  @color_config %{
    "ghost" => %{
      "danger" => "text-danger hover:bg-danger/10",
      "info" => "text-info hover:bg-info/10",
      "neutral" => "text-foreground hover:bg-neutral/10",
      "primary" => "text-primary hover:bg-primary/10",
      "secondary" => "text-secondary hover:bg-secondary/10",
      "success" => "text-success hover:bg-success/10",
      "warning" => "text-warning hover:bg-warning/10"
    },
    "outline" => %{
      "danger" => "border border-danger text-danger bg-background",
      "info" => "border border-info text-info bg-background",
      "neutral" => "border border-border-strong text-foreground bg-background",
      "primary" => "border border-primary text-primary bg-background",
      "secondary" => "border border-secondary text-secondary bg-background",
      "success" => "border border-success text-success bg-background",
      "warning" => "border border-warning text-warning bg-background"
    },
    "solid" => %{
      "danger" => "bg-danger text-danger-foreground",
      "info" => "bg-info text-info-foreground",
      "neutral" => "bg-neutral text-neutral-foreground",
      "primary" => "bg-primary text-primary-foreground",
      "secondary" => "bg-secondary text-secondary-foreground",
      "success" => "bg-success text-success-foreground",
      "warning" => "bg-warning text-warning-foreground"
    }
  }

  # ============================================================================
  # BADGE COMPONENT
  # ============================================================================

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

  attr :as, :atom,
    default: :span,
    values: [:span, :div],
    doc: "Element type to render as. Use `:div` when the badge hosts flow content, such as a popover panel."

  attr :on_remove, JS,
    default: %JS{},
    doc: "JS commands to run when the built-in remove control is activated. Requires `remove_label`."

  attr :remove_label, :string,
    default: nil,
    doc:
      ~s{Accessible label for the remove control, naming what it removes. Use with i18n: gettext("Remove filter Status")}

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, required: true, doc: "Badge content"
  slot :start_addon, doc: "Content at the start of the badge (before text)"
  slot :end_addon, doc: "Content at the end of the badge (after text)"

  @doc """
  Renders a styled badge with optional start and end addon content.

  The badge uses semantic color tokens and supports all standard variants. Set
  `on_remove` for a dismissible token; other interactivity comes from the slots.
  """
  @spec badge(map()) :: Rendered.t()
  def badge(assigns) do
    validate_remove!(assigns.on_remove, assigns.remove_label)

    assigns =
      assigns
      |> assign(:class, build_badge_classes(assigns))
      |> assign(:addon_classes, @addon_classes)
      |> assign(:tag_name, to_string(assigns.as))
      |> assign(:removable, assigns.on_remove != %JS{})

    ~H"""
    <.dynamic_tag tag_name={@tag_name} class={@class} {@rest}>
      <span :if={@start_addon != []} class={@addon_classes}>{render_slot(@start_addon)}</span>
      {render_slot(@inner_block)}
      <span :if={@end_addon != []} class={@addon_classes}>{render_slot(@end_addon)}</span>
      <button :if={@removable} type="button" phx-click={@on_remove} aria-label={@remove_label}>
        <svg
          class="size-3.5"
          viewBox="0 0 20 20"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          aria-hidden="true"
        >
          <path d="M6 6l8 8M14 6l-8 8" />
        </svg>
      </button>
    </.dynamic_tag>
    """
  end

  # ============================================================================
  # BADGE HELPER FUNCTIONS
  # ============================================================================

  # The dismiss control is icon-only, so remove_label is its only accessible name.
  defp validate_remove!(on_remove, remove_label) do
    if on_remove != %JS{} and is_nil(remove_label) do
      raise ArgumentError,
            "<.badge on_remove={...}> requires remove_label naming what is removed, " <>
              "e.g. remove_label={gettext(\"Remove filter Status\")}"
    end
  end

  # Builds the merged class string for badge
  defp build_badge_classes(assigns) do
    merge([
      base_badge_classes(),
      variant_color_classes(assigns.variant, assigns.color),
      size_classes(assigns.size),
      assigns.class
    ])
  end

  # Base styles shared by all badge variants
  @spec base_badge_classes() :: String.t()
  defp base_badge_classes do
    @badge_base_classes <> " " <> @control_classes
  end

  # Get size classes from config
  @spec size_classes(String.t()) :: String.t()
  defp size_classes(size) do
    @size_config[size] || ""
  end

  # Get variant and color classes from config
  @spec variant_color_classes(String.t(), String.t()) :: String.t()
  defp variant_color_classes(variant, color) do
    @color_config[variant][color] || ""
  end
end
