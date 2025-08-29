defmodule Pulsar.Components.Button do
  @moduledoc """
  Styled button component built on Stellar.Components.Button.

  Provides beautiful, accessible buttons with semantic variants and consistent styling.
  All styling is applied via Tailwind CSS utilities with semantic color tokens that
  support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible button component
  - **Semantic Variants**: primary, secondary, success, error, warning, ghost, outline, link
  - **Multiple Sizes**: sm, md, lg, icon
  - **Dark Mode**: Automatic light/dark mode support
  - **Full Stellar API**: All Stellar button props are supported

  ## Examples

      # Basic usage
      <.button variant="primary">Save Changes</.button>

      # With size and loading state
      <.button variant="success" size="lg" loading={@saving}>
        Submit Form
      </.button>

      # Navigation button
      <.button variant="outline" navigate={~p"/dashboard"}>
        Go to Dashboard
      </.button>

      # Custom styling
      <.button variant="primary" class="w-full justify-start">
        <.icon name="hero-plus" class="mr-2 h-4 w-4" />
        Add Item
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
    default: "primary",
    values: ~w(primary secondary success error warning ghost outline link),
    doc: "Visual style variant of the button"

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg icon),
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
    merged_classes =
      merge([
        button_base(),
        variant_classes(assigns.variant),
        size_classes(assigns.size),
        assigns.class
      ])

    # Update class and remove Pulsar-specific attrs
    assigns =
      assigns
      |> assign(:class, merged_classes)
      |> assign(:variant, nil)
      |> assign(:size, nil)

    ~H"""
    <StellarButton.button {assigns}>
      {render_slot(@inner_block)}
    </StellarButton.button>
    """
  end

  # Base button styles applied to all variants
  defp button_base do
    """
    inline-flex items-center justify-center font-medium transition-colors cursor-pointer
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2
    focus-visible:ring-ring dark:focus-visible:ring-dark-ring
    disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed
    data-[loading=true]:pointer-events-none data-[loading=true]:opacity-50 data-[loading=true]:cursor-wait
    data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[disabled=true]:cursor-not-allowed
    """
  end

  # Variant-specific styles
  defp variant_classes("primary") do
    """
    bg-primary-500 text-white shadow-sm
    hover:bg-primary-600 active:bg-primary-700
    dark:bg-primary-600 dark:hover:bg-primary-500 dark:active:bg-primary-700
    """
  end

  defp variant_classes("secondary") do
    """
    bg-secondary-500 text-white shadow-sm
    hover:bg-secondary-600 active:bg-secondary-700
    dark:bg-secondary-600 dark:hover:bg-secondary-500 dark:active:bg-secondary-700
    """
  end

  defp variant_classes("success") do
    """
    bg-success-500 text-white shadow-sm
    hover:bg-success-600 active:bg-success-700
    dark:bg-success-600 dark:hover:bg-success-500 dark:active:bg-success-700
    """
  end

  defp variant_classes("error") do
    """
    bg-error-500 text-white shadow-sm
    hover:bg-error-600 active:bg-error-700
    dark:bg-error-600 dark:hover:bg-error-500 dark:active:bg-error-700
    """
  end

  defp variant_classes("warning") do
    """
    bg-warning-500 text-warning-900 shadow-sm
    hover:bg-warning-600 active:bg-warning-700
    dark:bg-warning-400 dark:text-warning-900
    dark:hover:bg-warning-300 dark:active:bg-warning-500
    """
  end

  defp variant_classes("ghost") do
    """
    text-foreground dark:text-dark-foreground
    hover:bg-gray-100 active:bg-gray-200
    dark:hover:bg-gray-800 dark:active:bg-gray-700
    """
  end

  defp variant_classes("outline") do
    """
    border-2 border-border dark:border-dark-border
    bg-background dark:bg-dark-background
    text-foreground dark:text-dark-foreground shadow-sm
    hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary
    active:bg-gray-200 dark:active:bg-gray-700
    """
  end

  defp variant_classes("link") do
    """
    text-primary-500 dark:text-primary-400
    underline-offset-4 hover:underline
    focus-visible:ring-0 focus-visible:ring-offset-0
    focus-visible:underline
    """
  end

  # Size-specific styles
  defp size_classes("sm") do
    "h-8 px-3 text-sm gap-1.5 rounded-md"
  end

  defp size_classes("md") do
    "h-10 px-4 py-2 gap-2 rounded-lg"
  end

  defp size_classes("lg") do
    "h-12 px-6 text-lg gap-2.5 rounded-lg"
  end

  defp size_classes("icon") do
    "h-10 w-10 p-0 rounded-lg"
  end
end
