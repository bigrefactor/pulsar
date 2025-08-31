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
      <div :if={@loading && @variant != "link" && @loading_content != []}>
        {render_slot(@loading_content)}
      </div>
      <svg :if={@loading && @show_loading_spinner && @variant != "link" && (@loading_content == [])} aria-hidden="true" class={spinner_size_classes(@size)} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
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
    font-medium cursor-pointer transition-shadow transition-transform duration-200 ease-in-out
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
  defp color_classes("solid", "neutral"), do: "bg-neutral text-neutral-foreground hover:bg-neutral/90 active:bg-neutral/80 dark:bg-dark-neutral dark:text-dark-neutral-foreground dark:hover:bg-dark-neutral/90 dark:active:bg-dark-neutral/80"
  defp color_classes("solid", "primary"), do: "bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/80 dark:bg-dark-primary dark:text-dark-primary-foreground dark:hover:bg-dark-primary/90 dark:active:bg-dark-primary/80"
  defp color_classes("solid", "secondary"), do: "bg-secondary text-secondary-foreground hover:bg-secondary/90 active:bg-secondary/80 dark:bg-dark-secondary dark:text-dark-secondary-foreground dark:hover:bg-dark-secondary/90 dark:active:bg-dark-secondary/80"
  defp color_classes("solid", "success"), do: "bg-success text-success-foreground hover:bg-success/90 active:bg-success/80 dark:bg-dark-success dark:text-dark-success-foreground dark:hover:bg-dark-success/90 dark:active:bg-dark-success/80"
  defp color_classes("solid", "danger"), do: "bg-danger text-danger-foreground hover:bg-danger/90 active:bg-danger/80 dark:bg-dark-danger dark:text-dark-danger-foreground dark:hover:bg-dark-danger/90 dark:active:bg-dark-danger/80"
  defp color_classes("solid", "warning"), do: "bg-warning text-warning-foreground hover:bg-warning/90 active:bg-warning/80 dark:bg-dark-warning dark:text-dark-warning-foreground dark:hover:bg-dark-warning/90 dark:active:bg-dark-warning/80"
  defp color_classes("solid", "info"), do: "bg-info text-info-foreground hover:bg-info/90 active:bg-info/80 dark:bg-dark-info dark:text-dark-info-foreground dark:hover:bg-dark-info/90 dark:active:bg-dark-info/80"

  defp color_classes("outline", "neutral"), do: "border-2 border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover active:bg-surface-1-active dark:active:bg-dark-surface-1-active"
  defp color_classes("outline", "primary"), do: "border-2 border-primary bg-background text-primary hover:bg-primary/5 active:bg-primary/10 dark:border-dark-primary dark:bg-dark-background dark:text-dark-primary dark:hover:bg-dark-primary/10 dark:active:bg-dark-primary/20"
  defp color_classes("outline", "secondary"), do: "border-2 border-secondary bg-background text-secondary hover:bg-secondary/5 active:bg-secondary/10 dark:border-dark-secondary dark:bg-dark-background dark:text-dark-secondary dark:hover:bg-dark-secondary/10 dark:active:bg-dark-secondary/20"
  defp color_classes("outline", "success"), do: "border-2 border-success bg-background text-success hover:bg-success/5 active:bg-success/10 dark:border-dark-success dark:bg-dark-background dark:text-dark-success dark:hover:bg-dark-success/10 dark:active:bg-dark-success/20"
  defp color_classes("outline", "danger"), do: "border-2 border-danger bg-background text-danger hover:bg-danger/5 active:bg-danger/10 dark:border-dark-danger dark:bg-dark-background dark:text-dark-danger dark:hover:bg-dark-danger/10 dark:active:bg-dark-danger/20"
  defp color_classes("outline", "warning"), do: "border-2 border-warning bg-background text-warning hover:bg-warning/5 active:bg-warning/10 dark:border-dark-warning dark:bg-dark-background dark:text-dark-warning dark:hover:bg-dark-warning/10 dark:active:bg-dark-warning/20"
  defp color_classes("outline", "info"), do: "border-2 border-info bg-background text-info hover:bg-info/5 active:bg-info/10 dark:border-dark-info dark:bg-dark-background dark:text-dark-info dark:hover:bg-dark-info/10 dark:active:bg-dark-info/20"

  defp color_classes("ghost", "neutral"), do: "text-foreground dark:text-dark-foreground hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover active:bg-surface-1-active dark:active:bg-dark-surface-1-active"
  defp color_classes("ghost", "primary"), do: "text-primary hover:bg-primary/10 active:bg-primary/20 dark:text-dark-primary dark:hover:bg-dark-primary/10 dark:active:bg-dark-primary/20"
  defp color_classes("ghost", "secondary"), do: "text-secondary hover:bg-secondary/10 active:bg-secondary/20 dark:text-dark-secondary dark:hover:bg-dark-secondary/10 dark:active:bg-dark-secondary/20"
  defp color_classes("ghost", "success"), do: "text-success hover:bg-success/10 active:bg-success/20 dark:text-dark-success dark:hover:bg-dark-success/10 dark:active:bg-dark-success/20"
  defp color_classes("ghost", "danger"), do: "text-danger hover:bg-danger/10 active:bg-danger/20 dark:text-dark-danger dark:hover:bg-dark-danger/10 dark:active:bg-dark-danger/20"
  defp color_classes("ghost", "warning"), do: "text-warning hover:bg-warning/10 active:bg-warning/20 dark:text-dark-warning dark:hover:bg-dark-warning/10 dark:active:bg-dark-warning/20"
  defp color_classes("ghost", "info"), do: "text-info hover:bg-info/10 active:bg-info/20 dark:text-dark-info dark:hover:bg-dark-info/10 dark:active:bg-dark-info/20"

  defp color_classes("link", "neutral"), do: "text-muted-foreground dark:text-dark-muted-foreground hover:text-foreground dark:hover:text-dark-foreground"
  defp color_classes("link", "primary"), do: "text-primary hover:text-primary/80 dark:text-dark-primary dark:hover:text-dark-primary/80"
  defp color_classes("link", "secondary"), do: "text-secondary hover:text-secondary/80 dark:text-dark-secondary dark:hover:text-dark-secondary/80"
  defp color_classes("link", "success"), do: "text-success hover:text-success/80 dark:text-dark-success dark:hover:text-dark-success/80"
  defp color_classes("link", "danger"), do: "text-danger hover:text-danger/80 dark:text-dark-danger dark:hover:text-dark-danger/80"
  defp color_classes("link", "warning"), do: "text-warning hover:text-warning/80 dark:text-dark-warning dark:hover:text-dark-warning/80"
  defp color_classes("link", "info"), do: "text-info hover:text-info/80 dark:text-dark-info dark:hover:text-dark-info/80"

  # Spinner size classes based on button size
  defp spinner_size_classes("xs"), do: "h-3 w-3 animate-spin"
  defp spinner_size_classes("sm"), do: "h-4 w-4 animate-spin"
  defp spinner_size_classes("md"), do: "h-4 w-4 animate-spin"
  defp spinner_size_classes("lg"), do: "h-5 w-5 animate-spin"
  defp spinner_size_classes("xl"), do: "h-6 w-6 animate-spin"

end
