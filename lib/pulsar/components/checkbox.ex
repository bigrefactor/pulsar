defmodule Pulsar.Components.Checkbox do
  @moduledoc """
  Styled checkbox component built on Stellar.Components.Checkbox.

  Provides beautiful, accessible checkboxes with animated checkmark, semantic variants,
  and consistent styling. All styling is applied via Tailwind CSS utilities with semantic
  color tokens that support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible checkbox component
  - **Size Variants**: xs, sm, md, lg, xl for complete range
  - **Color Variants**: neutral, primary, secondary, success, danger, warning for consistent theming
  - **Indeterminate State**: Full tri-state support with visual animation
  - **Card-style Options**: Enhanced layouts for rich checkbox experiences
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar checkbox props are supported

  ## Examples

      # Basic checkbox
      <.checkbox field={@form[:terms_accepted]} />

      # With color and size
      <.checkbox field={@form[:newsletter]} color="primary" size="lg" />

      # Indeterminate state for "select all" scenarios
      <.checkbox 
        field={@form[:select_all]} 
        indeterminate={@partial_selection}
        color="success"
      />

      # Card-style checkbox for rich layouts
      <.checkbox 
        field={@form[:plan]} 
        card
        variant="outline"
        color="primary" 
        size="lg"
        value="premium"
      >
        <div class="font-medium">Premium Plan</div>
        <div class="text-sm text-muted-foreground mt-1">Advanced features and priority support</div>
        <div class="text-sm font-semibold mt-2">$29/month</div>
      </.checkbox>

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback.

  ## Stellar Integration

  This component wraps Stellar.Components.Checkbox and passes through all its props:
  - `:field` - Phoenix form field integration
  - `:checked`, `:indeterminate` - State management
  - `:value`, `:unchecked_value` - Value handling
  - `:disabled`, `:required` - Form states
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered
  alias Stellar.Components.Checkbox, as: StellarCheckbox

  # Pulsar-specific styling attributes
  attr :card, :boolean,
    default: false,
    doc: "Render as a clickable card layout"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant (applies to card when card=true)"

  attr :color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the checkbox (overridden by error state)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the checkbox"

  # Stellar checkbox attributes - copied from Stellar.Components.Checkbox
  attr :field, FormField, default: nil, doc: "Phoenix form field"

  # Core attributes
  attr :id, :string,
    default: nil,
    doc: "Checkbox ID (auto-generated if not provided)"

  attr :name, :string,
    default: nil,
    doc: "Checkbox name (from field if not provided)"

  attr :value, :any,
    default: "true",
    doc: "Value when checkbox is checked"

  attr :checked, :boolean,
    default: false,
    doc: "Checkbox state (from field if not provided)"

  attr :unchecked_value, :string,
    default: "false",
    doc: "Hidden input value when unchecked"

  attr :indeterminate, :boolean,
    default: false,
    doc: "Tri-state checkbox support"

  attr :render_hidden, :boolean,
    default: true,
    doc: "Render hidden input for unchecked value"

  # State attributes
  attr :required, :boolean,
    default: false,
    doc: "Mark checkbox as required"

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the checkbox"

  # State override (optional)
  attr :invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"

  # Styling
  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  # Global attributes (allows all Phoenix and HTML attributes)
  attr :rest, :global, doc: "Additional HTML attributes"

  # Card variant slots
  slot :inner_block, doc: "Main content for card variant (replaces checkbox content)"

  @doc """
  Renders a styled checkbox component.

  This function wraps Stellar.Components.Checkbox with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via CSS classes
  that respond to the checkbox's data attributes.

  ## Default vs Card Variant
  - **default**: Standard checkbox with clean, modern styling
  - **card**: Rich checkbox layout with dedicated slots for structured content

  ## Examples

      # Standard checkbox
      <.checkbox field={@form[:terms]} color="primary" />

      # Rich card layout  
      <.checkbox card field={@form[:plan]} value="pro">
        <div class="font-medium">Pro Plan</div>
        <div class="text-sm text-muted-foreground mt-1">Everything in Basic plus advanced features</div>
        <div class="text-sm font-semibold mt-2">$19/month</div>
      </.checkbox>
  """
  @spec checkbox(map()) :: Rendered.t()
  def checkbox(assigns) do
    # Validate required attributes
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Checkbox requires :field or :name; provide :name only when not using a Phoenix form field"
    end

    # Detect errors and compute automatic color
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Build class string for checkbox input
    input_class =
      merge([
        base_checkbox_classes(),
        size_classes(assigns.size),
        color_classes(effective_color),
        state_classes(assigns.disabled, invalid),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:input_class, input_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)

    if assigns.card do
      render_card_checkbox(assigns)
    else
      render_default_checkbox(assigns)
    end
  end

  # Default checkbox variant
  defp render_default_checkbox(assigns) do
    ~H"""
    <StellarCheckbox.checkbox
      field={@field}
      id={@id}
      name={@name}
      value={@value}
      checked={@checked}
      unchecked_value={@unchecked_value}
      indeterminate={@indeterminate}
      render_hidden={@render_hidden}
      required={@required}
      disabled={@disabled}
      class={@input_class}
      aria-invalid={@invalid && "true"}
      {@rest}
    />
    """
  end

  # Card variant with generic content slot
  defp render_card_checkbox(assigns) do
    container_class =
      [
        [card_base_classes()],
        card_variant_classes(assigns.variant, assigns.effective_color),
        [card_size_classes(assigns.size)],
        [card_state_classes(assigns.disabled, assigns.invalid)]
      ]
      |> List.flatten()
      |> merge()

    assigns = assign(assigns, :container_class, container_class)

    ~H"""
    <label class={@container_class}>
      <StellarCheckbox.checkbox
        field={@field}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        unchecked_value={@unchecked_value}
        indeterminate={@indeterminate}
        render_hidden={@render_hidden}
        required={@required}
        disabled={@disabled}
        class={@input_class}
        aria-invalid={@invalid && "true"}
        {@rest}
      />

      <div class="flex-1 min-w-0">
        {render_slot(@inner_block)}
      </div>
    </label>
    """
  end

  # Base styles for checkbox input with custom checkmark
  @spec base_checkbox_classes() :: String.t()
  defp base_checkbox_classes do
    [
      "appearance-none relative cursor-pointer transition-all duration-200 ease-in-out",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
      "focus-visible:ring-ring dark:focus-visible:ring-dark-ring",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "before:content-[''] before:absolute before:inset-0 before:rounded-inherit",
      "before:border-2 before:transition-all before:duration-200 before:ease-in-out",
      "after:content-['✓'] after:absolute after:inset-0 after:flex after:items-center after:justify-center",
      "after:text-current after:font-bold after:transition-all after:duration-200 after:ease-in-out",
      "after:scale-0 after:opacity-0",
      "data-[checked=true]:after:scale-100 data-[checked=true]:after:opacity-100",
      "data-[indeterminate=true]:after:content-['−'] data-[indeterminate=true]:after:scale-100 data-[indeterminate=true]:after:opacity-100"
    ]
    |> Enum.join(" ")
  end

  # Size classes for checkbox
  @spec size_classes(String.t()) :: String.t()
  defp size_classes("xs"), do: "h-3 w-3 rounded before:rounded after:text-[8px]"
  defp size_classes("sm"), do: "h-4 w-4 rounded before:rounded after:text-[10px]"
  defp size_classes("md"), do: "h-5 w-5 rounded-md before:rounded-md after:text-xs"
  defp size_classes("lg"), do: "h-6 w-6 rounded-md before:rounded-md after:text-sm"
  defp size_classes("xl"), do: "h-7 w-7 rounded-lg before:rounded-lg after:text-base"

  # Color classes for checkbox
  @spec color_classes(String.t()) :: String.t()
  defp color_classes(color) do
    [
      "before:border-border dark:before:border-dark-border",
      checkbox_border_classes(color),
      checkbox_background_classes(color),
      checkbox_text_classes(color)
    ]
    |> List.flatten()
    |> Enum.join(" ")
  end

  # Border classes for each color
  @spec checkbox_border_classes(String.t()) :: list(String.t())
  defp checkbox_border_classes("neutral") do
    [
      "data-[checked=true]:before:border-neutral dark:data-[checked=true]:before:border-dark-neutral",
      "data-[indeterminate=true]:before:border-neutral dark:data-[indeterminate=true]:before:border-dark-neutral"
    ]
  end

  defp checkbox_border_classes("primary") do
    [
      "data-[checked=true]:before:border-primary dark:data-[checked=true]:before:border-dark-primary",
      "data-[indeterminate=true]:before:border-primary dark:data-[indeterminate=true]:before:border-dark-primary"
    ]
  end

  defp checkbox_border_classes("secondary") do
    [
      "data-[checked=true]:before:border-secondary dark:data-[checked=true]:before:border-dark-secondary",
      "data-[indeterminate=true]:before:border-secondary dark:data-[indeterminate=true]:before:border-dark-secondary"
    ]
  end

  defp checkbox_border_classes("success") do
    [
      "data-[checked=true]:before:border-success dark:data-[checked=true]:before:border-dark-success",
      "data-[indeterminate=true]:before:border-success dark:data-[indeterminate=true]:before:border-dark-success"
    ]
  end

  defp checkbox_border_classes("danger") do
    [
      "data-[checked=true]:before:border-danger dark:data-[checked=true]:before:border-dark-danger",
      "data-[indeterminate=true]:before:border-danger dark:data-[indeterminate=true]:before:border-dark-danger"
    ]
  end

  defp checkbox_border_classes("warning") do
    [
      "data-[checked=true]:before:border-warning dark:data-[checked=true]:before:border-dark-warning",
      "data-[indeterminate=true]:before:border-warning dark:data-[indeterminate=true]:before:border-dark-warning"
    ]
  end

  defp checkbox_border_classes("info") do
    [
      "data-[checked=true]:before:border-info dark:data-[checked=true]:before:border-dark-info",
      "data-[indeterminate=true]:before:border-info dark:data-[indeterminate=true]:before:border-dark-info"
    ]
  end

  # Background classes for each color
  @spec checkbox_background_classes(String.t()) :: list(String.t())
  defp checkbox_background_classes("neutral") do
    [
      "data-[checked=true]:before:bg-neutral dark:data-[checked=true]:before:bg-dark-neutral",
      "data-[indeterminate=true]:before:bg-neutral dark:data-[indeterminate=true]:before:bg-dark-neutral"
    ]
  end

  defp checkbox_background_classes("primary") do
    [
      "data-[checked=true]:before:bg-primary dark:data-[checked=true]:before:bg-dark-primary",
      "data-[indeterminate=true]:before:bg-primary dark:data-[indeterminate=true]:before:bg-dark-primary"
    ]
  end

  defp checkbox_background_classes("secondary") do
    [
      "data-[checked=true]:before:bg-secondary dark:data-[checked=true]:before:bg-dark-secondary",
      "data-[indeterminate=true]:before:bg-secondary dark:data-[indeterminate=true]:before:bg-dark-secondary"
    ]
  end

  defp checkbox_background_classes("success") do
    [
      "data-[checked=true]:before:bg-success dark:data-[checked=true]:before:bg-dark-success",
      "data-[indeterminate=true]:before:bg-success dark:data-[indeterminate=true]:before:bg-dark-success"
    ]
  end

  defp checkbox_background_classes("danger") do
    [
      "data-[checked=true]:before:bg-danger dark:data-[checked=true]:before:bg-dark-danger",
      "data-[indeterminate=true]:before:bg-danger dark:data-[indeterminate=true]:before:bg-dark-danger"
    ]
  end

  defp checkbox_background_classes("warning") do
    [
      "data-[checked=true]:before:bg-warning dark:data-[checked=true]:before:bg-dark-warning",
      "data-[indeterminate=true]:before:bg-warning dark:data-[indeterminate=true]:before:bg-dark-warning"
    ]
  end

  defp checkbox_background_classes("info") do
    [
      "data-[checked=true]:before:bg-info dark:data-[checked=true]:before:bg-dark-info",
      "data-[indeterminate=true]:before:bg-info dark:data-[indeterminate=true]:before:bg-dark-info"
    ]
  end

  # Text/checkmark classes for each color using semantic foreground colors
  @spec checkbox_text_classes(String.t()) :: list(String.t())
  defp checkbox_text_classes("neutral") do
    [
      "data-[checked=true]:after:text-neutral-foreground dark:data-[checked=true]:after:text-dark-neutral-foreground",
      "data-[indeterminate=true]:after:text-neutral-foreground dark:data-[indeterminate=true]:after:text-dark-neutral-foreground"
    ]
  end

  defp checkbox_text_classes("primary") do
    [
      "data-[checked=true]:after:text-primary-foreground dark:data-[checked=true]:after:text-dark-primary-foreground",
      "data-[indeterminate=true]:after:text-primary-foreground dark:data-[indeterminate=true]:after:text-dark-primary-foreground"
    ]
  end

  defp checkbox_text_classes("secondary") do
    [
      "data-[checked=true]:after:text-secondary-foreground dark:data-[checked=true]:after:text-dark-secondary-foreground",
      "data-[indeterminate=true]:after:text-secondary-foreground dark:data-[indeterminate=true]:after:text-dark-secondary-foreground"
    ]
  end

  defp checkbox_text_classes("success") do
    [
      "data-[checked=true]:after:text-success-foreground dark:data-[checked=true]:after:text-dark-success-foreground",
      "data-[indeterminate=true]:after:text-success-foreground dark:data-[indeterminate=true]:after:text-dark-success-foreground"
    ]
  end

  defp checkbox_text_classes("danger") do
    [
      "data-[checked=true]:after:text-danger-foreground dark:data-[checked=true]:after:text-dark-danger-foreground",
      "data-[indeterminate=true]:after:text-danger-foreground dark:data-[indeterminate=true]:after:text-dark-danger-foreground"
    ]
  end

  defp checkbox_text_classes("warning") do
    [
      "data-[checked=true]:after:text-warning-foreground dark:data-[checked=true]:after:text-dark-warning-foreground",
      "data-[indeterminate=true]:after:text-warning-foreground dark:data-[indeterminate=true]:after:text-dark-warning-foreground"
    ]
  end

  defp checkbox_text_classes("info") do
    [
      "data-[checked=true]:after:text-info-foreground dark:data-[checked=true]:after:text-dark-info-foreground",
      "data-[indeterminate=true]:after:text-info-foreground dark:data-[indeterminate=true]:after:text-dark-info-foreground"
    ]
  end

  # State classes for disabled/invalid states
  @spec state_classes(boolean(), boolean()) :: String.t()
  defp state_classes(disabled, invalid) do
    [
      disabled &&
        "before:bg-surface-2 dark:before:bg-dark-surface-2 before:border-border/50 dark:before:border-dark-border/50",
      invalid && "before:border-danger dark:before:border-dark-danger"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Base card classes shared by all card variants
  @spec card_base_classes() :: String.t()
  defp card_base_classes do
    [
      "flex items-center gap-3 rounded-lg cursor-pointer transition-all duration-200 ease-in-out",
      "focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ring",
      "dark:focus-within:ring-dark-ring has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50",
      "mb-3 last:mb-0"
    ]
    |> Enum.join(" ")
  end

  # Card size classes
  @spec card_size_classes(String.t()) :: String.t()
  defp card_size_classes("xs"), do: "p-2 gap-2 text-xs"
  defp card_size_classes("sm"), do: "p-3 gap-2 text-sm"
  defp card_size_classes("md"), do: "p-4 gap-3"
  defp card_size_classes("lg"), do: "p-5 gap-4 text-lg"
  defp card_size_classes("xl"), do: "p-6 gap-5 text-xl"

  # Card variant classes using helper functions to reduce repetition
  @spec card_variant_classes(String.t(), String.t()) :: list(String.t())
  defp card_variant_classes("solid", color) do
    [
      card_solid_background(color),
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("outline", color) do
    [
      card_outline_background(color),
      card_outline_border(color),
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("ghost", color) do
    [
      card_ghost_background(color),
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  # Helper functions for card variant styling
  @spec card_solid_background(String.t()) :: String.t()
  defp card_solid_background(color) do
    "bg-#{color}/10 hover:bg-#{color}/20 dark:bg-dark-#{color}/20 dark:hover:bg-dark-#{color}/30"
  end

  @spec card_outline_background(String.t()) :: String.t()
  defp card_outline_background("neutral") do
    "bg-background dark:bg-dark-background"
  end

  defp card_outline_background(color) do
    "bg-background hover:bg-#{color}/5 dark:bg-dark-background dark:hover:bg-dark-#{color}/10"
  end

  @spec card_outline_border(String.t()) :: String.t()
  defp card_outline_border("neutral") do
    "border-2 border-border hover:border-primary/50 dark:border-dark-border dark:hover:border-dark-primary/50"
  end

  defp card_outline_border(color) do
    "border-2 border-#{color}/30 hover:border-#{color} dark:border-dark-#{color}/30 dark:hover:border-dark-#{color}"
  end

  @spec card_ghost_background(String.t()) :: String.t()
  defp card_ghost_background("neutral") do
    "bg-transparent hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover"
  end

  defp card_ghost_background(color) do
    "bg-transparent hover:bg-#{color}/10 dark:hover:bg-dark-#{color}/10"
  end

  # Card state classes
  @spec card_state_classes(boolean(), boolean()) :: String.t()
  defp card_state_classes(disabled, invalid) do
    [
      disabled && "bg-surface-2 dark:bg-dark-surface-2 border-border/50 dark:border-dark-border/50",
      invalid && "border-danger dark:border-dark-danger bg-danger/5 dark:bg-dark-danger/10"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Helper for error detection - checks if a Phoenix form field has validation errors
  @spec has_field_errors(map()) :: boolean()
  defp has_field_errors(%{field: %FormField{errors: errors}}) when is_list(errors) do
    not Enum.empty?(errors)
  end

  defp has_field_errors(_assigns), do: false
end
