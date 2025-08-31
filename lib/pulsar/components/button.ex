defmodule Pulsar.Components.Button do
  @moduledoc """
  Styled button component built on Stellar.Components.Button.

  Provides beautiful, accessible buttons with semantic variants and consistent styling.
  All styling is applied via Tailwind CSS utilities with semantic color tokens that
  support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible button component
  - **Variants**: solid, outline, ghost, link with semantic styling
  - **Colors**: neutral, primary, secondary, success, danger, warning for consistent theming
  - **Multiple Sizes**: xs, sm, md, lg, xl for complete range
  - **Dark Mode**: Automatic light/dark mode support
  - **Full Stellar API**: All Stellar button props are supported

  ## Examples

      # Basic usage
      <.button variant="solid" color="primary">Save Changes</.button>

      # With size and loading state
      <.button variant="solid" color="success" size="lg" loading={@saving}>
        Submit Form
      </.button>

      # Navigation button
      <.button variant="outline" color="primary" navigate={~p"/dashboard"}>
        Go to Dashboard
      </.button>

      # Icon-only button with accessibility
      <.button variant="solid" color="primary" size="sm" class="w-8 p-0" aria_label="Add item">
        +
      </.button>

      # Custom styling
      <.button variant="solid" color="primary" class="w-full justify-start">
        <span>📁</span> Add Item
      </.button>

  ## Stellar Integration

  This component wraps Stellar.Components.Button and passes through all its props:
  - `:as` - Render as button, a, or div
  - `:loading`, `:disabled`, `:pressed` - Interactive states
  - `:navigate`, `:href`, `:patch` - Navigation options
  - `:controls`, `:expanded` - ARIA attributes
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component
  alias Stellar.Components.Button, as: StellarButton

  import TailwindMerge, only: [merge: 1]

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost link),
    doc: "Visual style variant of the button"

  attr :color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the button"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the button. Note: link variant ignores size to preserve natural text flow"

  # Stellar button attributes - copied from Stellar.Components.Button
  attr :as, :atom,
    values: [:button, :a, :div],
    default: :button,
    doc: "Element type to render as"

  attr :type, :string,
    values: ~w(button submit reset),
    default: "button",
    doc: "Button type attribute"

  # Navigation (mutually exclusive)
  attr :href, :string,
    default: nil,
    doc: "External URL to navigate to"

  attr :navigate, :string,
    default: nil,
    doc: "Phoenix route to navigate to"

  attr :patch, :string,
    default: nil,
    doc: "Phoenix route to patch navigate to"

  # State
  attr :loading, :boolean,
    default: false,
    doc: "Show loading state"

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the button"

  attr :pressed, :atom,
    values: [true, false, nil],
    default: nil,
    doc: "Toggle button pressed state"

  attr :expanded, :any,
    default: nil,
    doc: "Disclosure/dropdown expanded state"

  attr :controls, :string,
    default: nil,
    doc: "ID of element controlled by this button"

  # ARIA
  attr :haspopup, :string,
    values: ~w(menu listbox tree grid dialog false),
    default: "false",
    doc: "ARIA haspopup value"

  # Core
  attr :id, :string,
    default: nil,
    doc: "Button ID"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :aria_label, :string,
    default: nil,
    doc: "Accessible label for icon-only buttons"

  attr :show_loading_spinner, :boolean,
    default: true,
    doc: "Show automatic spinner when loading (can be disabled for custom loading content)"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block,
    required: true,
    doc: "Button content"

  slot :loading_content,
    required: false,
    doc: "Custom loading content that replaces inner_block when button is loading"

  @doc """
  Renders a styled button component.

  This function wraps Stellar.Components.Button with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via data attributes
  for better maintainability and smaller class strings.

  ## Size Behavior
  - **solid, outline, ghost variants**: Size controls height, padding, and text size
  - **link variant**: Size is ignored to preserve natural text flow. Links adapt to surrounding text.

  ## Examples

      # Link buttons ignore size - they flow with surrounding text
      <.button variant="link" size="lg">Download</.button>  # size ignored
      
      # Other variants respect size
      <.button variant="solid" size="lg">Download</.button>  # h-12, px-6, text-lg
  """
  def button(assigns) do
    # Build complete class string using TailwindMerge - only include needed classes
    assigns =
      assign(assigns, :merged_classes,
        merge([
          base_button_classes(),
          variant_classes(assigns.variant),
          (if assigns.variant == "link", do: "", else: size_classes(assigns.size)),
          color_classes(assigns.variant, assigns.color),
          assigns.class
        ])
      )

    ~H"""
    <StellarButton.button
      as={@as}
      type={@type}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      loading={@loading}
      disabled={@disabled}
      pressed={@pressed}
      expanded={@expanded}
      controls={@controls}
      haspopup={@haspopup}
      id={@id}
      class={@merged_classes}
      aria-label={@aria_label}
      {@rest}
    >
      <div :if={@loading && @loading_content != []}>
        {render_slot(@loading_content)}
      </div>
      <svg :if={@loading && @show_loading_spinner && (@loading_content == [])} class={spinner_size_classes(@size)} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"></circle>
        <path fill="currentColor" class="opacity-75" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <div :if={!@loading || @loading_content == []}>
        {render_slot(@inner_block)}
      </div>
    </StellarButton.button>
    """
  end

  # Base styles shared by all buttons
  defp base_button_classes do
    """
    font-medium cursor-pointer transition-all duration-200 ease-in-out
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 
    focus-visible:ring-ring dark:focus-visible:ring-dark-ring
    disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed
    data-[loading=true]:pointer-events-none data-[loading=true]:opacity-50 data-[loading=true]:cursor-wait
    data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[disabled=true]:cursor-not-allowed
    """
  end

  # Variant-specific layout and behavior
  defp variant_classes("link") do
    "inline underline-offset-4 hover:underline focus-visible:ring-0 focus-visible:ring-offset-0 focus-visible:underline"
  end

  defp variant_classes(_other) do
    """
    inline-flex items-center justify-center shadow-sm hover:shadow-md
    hover:scale-[1.02] active:scale-[0.98]
    motion-reduce:hover:scale-100 motion-reduce:active:scale-100 motion-reduce:transition-none
    """
  end

  # Size classes
  defp size_classes("xs"), do: "h-6 px-2 text-xs gap-1 rounded-md"
  defp size_classes("sm"), do: "h-8 px-3 text-sm gap-1 rounded-md"
  defp size_classes("md"), do: "h-10 px-4 gap-2 rounded-lg"
  defp size_classes("lg"), do: "h-12 px-6 text-lg gap-2 rounded-lg"
  defp size_classes("xl"), do: "h-14 px-8 text-xl gap-3 rounded-xl"

  # Color classes by variant
  defp color_classes("solid", "neutral"), do: "bg-neutral-500 text-white hover:bg-neutral-600 active:bg-neutral-700 dark:bg-neutral-600 dark:hover:bg-neutral-500 dark:active:bg-neutral-700"
  defp color_classes("solid", "primary"), do: "bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700 dark:bg-primary-600 dark:hover:bg-primary-500 dark:active:bg-primary-700"
  defp color_classes("solid", "secondary"), do: "bg-secondary-500 text-white hover:bg-secondary-600 active:bg-secondary-700 dark:bg-secondary-600 dark:hover:bg-secondary-500 dark:active:bg-secondary-700"
  defp color_classes("solid", "success"), do: "bg-success-500 text-white hover:bg-success-600 active:bg-success-700 dark:bg-success-600 dark:hover:bg-success-500 dark:active:bg-success-700"
  defp color_classes("solid", "danger"), do: "bg-danger-500 text-white hover:bg-danger-600 active:bg-danger-700 dark:bg-danger-600 dark:hover:bg-danger-500 dark:active:bg-danger-700"
  defp color_classes("solid", "warning"), do: "bg-warning-500 text-warning-950 hover:bg-warning-600 active:bg-warning-700 dark:bg-warning-400 dark:text-warning-950 dark:hover:bg-warning-300 dark:active:bg-warning-500"
  defp color_classes("solid", "info"), do: "bg-info-500 text-white hover:bg-info-600 active:bg-info-700 dark:bg-info-600 dark:hover:bg-info-500 dark:active:bg-info-700"

  defp color_classes("outline", "neutral"), do: "border-2 border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary active:bg-surface-active dark:active:bg-dark-surface-active"
  defp color_classes("outline", "primary"), do: "border-2 border-primary-500 bg-background text-primary-600 hover:bg-primary-50 active:bg-primary-100 dark:border-primary-400 dark:bg-dark-background dark:text-primary-400 dark:hover:bg-primary-900/20 dark:active:bg-primary-900/40"
  defp color_classes("outline", "secondary"), do: "border-2 border-secondary-500 bg-background text-secondary-600 hover:bg-secondary-50 active:bg-secondary-100 dark:border-secondary-400 dark:bg-dark-background dark:text-secondary-400 dark:hover:bg-secondary-900/20 dark:active:bg-secondary-900/40"
  defp color_classes("outline", "success"), do: "border-2 border-success-500 bg-background text-success-600 hover:bg-success-50 active:bg-success-100 dark:border-success-400 dark:bg-dark-background dark:text-success-400 dark:hover:bg-success-900/20 dark:active:bg-success-900/40"
  defp color_classes("outline", "danger"), do: "border-2 border-danger-500 bg-background text-danger-600 hover:bg-danger-50 active:bg-danger-100 dark:border-danger-400 dark:bg-dark-background dark:text-danger-400 dark:hover:bg-danger-900/20 dark:active:bg-danger-900/40"
  defp color_classes("outline", "warning"), do: "border-2 border-warning-500 bg-background text-warning-600 hover:bg-warning-50 active:bg-warning-100 dark:border-warning-400 dark:bg-dark-background dark:text-warning-400 dark:hover:bg-warning-900/20 dark:active:bg-warning-900/40"
  defp color_classes("outline", "info"), do: "border-2 border-info-500 bg-background text-info-600 hover:bg-info-50 active:bg-info-100 dark:border-info-400 dark:bg-dark-background dark:text-info-400 dark:hover:bg-info-900/20 dark:active:bg-info-900/40"

  defp color_classes("ghost", "neutral"), do: "text-foreground dark:text-dark-foreground hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary active:bg-surface-active dark:active:bg-dark-surface-active"
  defp color_classes("ghost", "primary"), do: "text-primary-600 hover:bg-primary-100 active:bg-primary-200 dark:text-primary-400 dark:hover:bg-primary-900/20 dark:active:bg-primary-900/40"
  defp color_classes("ghost", "secondary"), do: "text-secondary-600 hover:bg-secondary-100 active:bg-secondary-200 dark:text-secondary-400 dark:hover:bg-secondary-900/20 dark:active:bg-secondary-900/40"
  defp color_classes("ghost", "success"), do: "text-success-600 hover:bg-success-100 active:bg-success-200 dark:text-success-400 dark:hover:bg-success-900/20 dark:active:bg-success-900/40"
  defp color_classes("ghost", "danger"), do: "text-danger-600 hover:bg-danger-100 active:bg-danger-200 dark:text-danger-400 dark:hover:bg-danger-900/20 dark:active:bg-danger-900/40"
  defp color_classes("ghost", "warning"), do: "text-warning-600 hover:bg-warning-100 active:bg-warning-200 dark:text-warning-400 dark:hover:bg-warning-900/20 dark:active:bg-warning-900/40"
  defp color_classes("ghost", "info"), do: "text-info-600 hover:bg-info-100 active:bg-info-200 dark:text-info-400 dark:hover:bg-info-900/20 dark:active:bg-info-900/40"

  defp color_classes("link", "neutral"), do: "text-muted dark:text-dark-muted hover:text-foreground dark:hover:text-dark-foreground"
  defp color_classes("link", "primary"), do: "text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-200"
  defp color_classes("link", "secondary"), do: "text-secondary-600 hover:text-secondary-800 dark:text-secondary-400 dark:hover:text-secondary-200"
  defp color_classes("link", "success"), do: "text-success-600 hover:text-success-800 dark:text-success-400 dark:hover:text-success-200"
  defp color_classes("link", "danger"), do: "text-danger-600 hover:text-danger-800 dark:text-danger-400 dark:hover:text-danger-200"
  defp color_classes("link", "warning"), do: "text-warning-600 hover:text-warning-800 dark:text-warning-400 dark:hover:text-warning-200"
  defp color_classes("link", "info"), do: "text-info-600 hover:text-info-800 dark:text-info-400 dark:hover:text-info-200"

  # Spinner size classes based on button size
  defp spinner_size_classes("xs"), do: "h-3 w-3 animate-spin"
  defp spinner_size_classes("sm"), do: "h-4 w-4 animate-spin"
  defp spinner_size_classes("md"), do: "h-4 w-4 animate-spin"
  defp spinner_size_classes("lg"), do: "h-5 w-5 animate-spin"
  defp spinner_size_classes("xl"), do: "h-6 w-6 animate-spin"

end
