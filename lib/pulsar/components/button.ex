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
    values: ~w(neutral primary secondary success danger warning),
    doc: "Color scheme of the button"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the button"

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

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block,
    required: true,
    doc: "Button content"

  @doc """
  Renders a styled button component.

  This function wraps Stellar.Components.Button with Pulsar's styling system.
  All Stellar props are passed through, with additional styling applied based
  on the `:variant` and `:size` attributes.
  """
  def button(assigns) do
    # Build complete class string using TailwindMerge
    # Skip size classes for link variant to behave like real text links
    size = if assigns.variant == "link", do: "", else: size_classes(assigns.size)
    
    assigns =
      assign(assigns, :merged_classes,
        merge([
          button_base(assigns.variant),
          variant_classes(assigns.variant, assigns.color),
          size,
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
      {render_slot(@inner_block)}
    </StellarButton.button>
    """
  end

  # Base button styles by variant
  defp button_base("link") do
    """
    inline font-medium cursor-pointer focus-visible:outline-none
    disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed
    data-[loading=true]:pointer-events-none data-[loading=true]:opacity-50 data-[loading=true]:cursor-wait
    data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[disabled=true]:cursor-not-allowed
    """
  end
  
  defp button_base(_other) do
    """
    inline-flex items-center justify-center font-medium cursor-pointer
    transition-all duration-200 ease-in-out
    hover:scale-[1.02] active:scale-[0.98]
    motion-reduce:hover:scale-100 motion-reduce:active:scale-100 motion-reduce:transition-none
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2
    focus-visible:ring-ring dark:focus-visible:ring-dark-ring
    disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed
    data-[loading=true]:pointer-events-none data-[loading=true]:opacity-50 data-[loading=true]:cursor-wait
    data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[disabled=true]:cursor-not-allowed
    """
  end

  # Variant and color combination styles
  defp variant_classes("solid", color) do
    solid_color_classes(color) <> " shadow-sm hover:shadow-md transition-shadow duration-200"
  end

  defp variant_classes("outline", color) do
    outline_color_classes(color) <> " border-2 shadow-sm hover:shadow-md transition-shadow duration-200"
  end

  defp variant_classes("ghost", color) do
    ghost_color_classes(color)
  end

  defp variant_classes("link", color) do
    link_color_classes(color) <> " underline-offset-4 hover:underline focus-visible:ring-0 focus-visible:ring-offset-0 focus-visible:underline"
  end

  # Solid variant color styles
  defp solid_color_classes("neutral") do
    "bg-gray-600 text-white hover:bg-gray-700 active:bg-gray-800 dark:bg-gray-500 dark:hover:bg-gray-400 dark:active:bg-gray-600"
  end

  defp solid_color_classes("primary") do
    "bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700 dark:bg-primary-600 dark:hover:bg-primary-500 dark:active:bg-primary-700"
  end

  defp solid_color_classes("secondary") do
    "bg-secondary-500 text-white hover:bg-secondary-600 active:bg-secondary-700 dark:bg-secondary-600 dark:hover:bg-secondary-500 dark:active:bg-secondary-700"
  end

  defp solid_color_classes("success") do
    "bg-success-500 text-white hover:bg-success-600 active:bg-success-700 dark:bg-success-600 dark:hover:bg-success-500 dark:active:bg-success-700"
  end

  defp solid_color_classes("danger") do
    "bg-danger-500 text-white hover:bg-danger-600 active:bg-danger-700 dark:bg-danger-600 dark:hover:bg-danger-500 dark:active:bg-danger-700"
  end

  defp solid_color_classes("warning") do
    "bg-warning-500 text-warning-900 hover:bg-warning-600 active:bg-warning-700 dark:bg-warning-400 dark:text-warning-900 dark:hover:bg-warning-300 dark:active:bg-warning-500"
  end

  # Outline variant color styles
  defp outline_color_classes("neutral") do
    "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary active:bg-surface-active dark:active:bg-dark-surface-active"
  end

  defp outline_color_classes("primary") do
    "border-primary-500 bg-background text-primary-600 hover:bg-primary-50 active:bg-primary-100 dark:border-primary-400 dark:bg-dark-background dark:text-primary-400 dark:hover:bg-primary-900/20 dark:active:bg-primary-900/40"
  end

  defp outline_color_classes("secondary") do
    "border-secondary-500 bg-background text-secondary-600 hover:bg-secondary-50 active:bg-secondary-100 dark:border-secondary-400 dark:bg-dark-background dark:text-secondary-400 dark:hover:bg-secondary-900/20 dark:active:bg-secondary-900/40"
  end

  defp outline_color_classes("success") do
    "border-success-500 bg-background text-success-600 hover:bg-success-50 active:bg-success-100 dark:border-success-400 dark:bg-dark-background dark:text-success-400 dark:hover:bg-success-900/20 dark:active:bg-success-900/40"
  end

  defp outline_color_classes("danger") do
    "border-danger-500 bg-background text-danger-600 hover:bg-danger-50 active:bg-danger-100 dark:border-danger-400 dark:bg-dark-background dark:text-danger-400 dark:hover:bg-danger-900/20 dark:active:bg-danger-900/40"
  end

  defp outline_color_classes("warning") do
    "border-warning-500 bg-background text-warning-600 hover:bg-warning-50 active:bg-warning-100 dark:border-warning-400 dark:bg-dark-background dark:text-warning-400 dark:hover:bg-warning-900/20 dark:active:bg-warning-900/40"
  end

  # Ghost variant color styles
  defp ghost_color_classes("neutral") do
    "text-foreground dark:text-dark-foreground hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary active:bg-surface-active dark:active:bg-dark-surface-active"
  end

  defp ghost_color_classes("primary") do
    "text-primary-600 hover:bg-primary-100 active:bg-primary-200 dark:text-primary-400 dark:hover:bg-primary-900/20 dark:active:bg-primary-900/40"
  end

  defp ghost_color_classes("secondary") do
    "text-secondary-600 hover:bg-secondary-100 active:bg-secondary-200 dark:text-secondary-400 dark:hover:bg-secondary-900/20 dark:active:bg-secondary-900/40"
  end

  defp ghost_color_classes("success") do
    "text-success-600 hover:bg-success-100 active:bg-success-200 dark:text-success-400 dark:hover:bg-success-900/20 dark:active:bg-success-900/40"
  end

  defp ghost_color_classes("danger") do
    "text-danger-600 hover:bg-danger-100 active:bg-danger-200 dark:text-danger-400 dark:hover:bg-danger-900/20 dark:active:bg-danger-900/40"
  end

  defp ghost_color_classes("warning") do
    "text-warning-600 hover:bg-warning-100 active:bg-warning-200 dark:text-warning-400 dark:hover:bg-warning-900/20 dark:active:bg-warning-900/40"
  end

  # Link variant color styles
  defp link_color_classes("neutral") do
    "text-muted dark:text-dark-muted hover:text-foreground dark:hover:text-dark-foreground"
  end

  defp link_color_classes("primary") do
    "text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-200"
  end

  defp link_color_classes("secondary") do
    "text-secondary-600 hover:text-secondary-800 dark:text-secondary-400 dark:hover:text-secondary-200"
  end

  defp link_color_classes("success") do
    "text-success-600 hover:text-success-800 dark:text-success-400 dark:hover:text-success-200"
  end

  defp link_color_classes("danger") do
    "text-danger-600 hover:text-danger-800 dark:text-danger-400 dark:hover:text-danger-200"
  end

  defp link_color_classes("warning") do
    "text-warning-600 hover:text-warning-800 dark:text-warning-400 dark:hover:text-warning-200"
  end

  # Size-specific styles
  defp size_classes("xs") do
    "h-6 px-2 text-xs gap-1 rounded-md"
  end

  defp size_classes("sm") do
    "h-8 px-3 text-sm gap-1.5 rounded-md"
  end

  defp size_classes("md") do
    "h-10 px-4 py-2 gap-2 rounded-lg"
  end

  defp size_classes("lg") do
    "h-12 px-6 text-lg gap-2.5 rounded-lg"
  end

  defp size_classes("xl") do
    "h-14 px-8 text-xl gap-3 rounded-lg"
  end

end
