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
      raise ArgumentError, "Checkbox component requires :name when :field is not provided"
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

  @doc """
  Renders a group of styled checkbox components.

  This function wraps Stellar.Components.Checkbox.checkbox_group with Pulsar's styling system.
  Uses Stellar's wrapper_class attribute to apply card styling to individual checkbox containers.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible checkbox group component
  - **Card Integration**: Apply card styling to all checkboxes in the group using `card=true`
  - **Data-Driven Styling**: Leverage `data-state` attributes for checked/unchecked styling
  - **Consistent Styling**: All group checkboxes share the same styling attributes
  - **Full Stellar API**: All Stellar checkbox group props and slots are supported

  ## Examples

      # Basic vertical group
      <.checkbox_group field={@form[:interests]} options={@interest_options} />

      # Card-style checkboxes with variants
      <.checkbox_group 
        field={@form[:features]} 
        options={@features}
        card
        variant="outline"
        color="primary" 
        size="lg"
      />

      # With legend and select all
      <.checkbox_group field={@form[:permissions]} options={@permissions}>
        <:legend class="font-semibold text-lg">User Permissions</:legend>
        <:select_all class="mb-4">Select All Permissions</:select_all>
      </.checkbox_group>

      # Custom label template
      <.checkbox_group field={@form[:categories]} options={@categories}>
        <:label :let={category} class="font-medium text-gray-700">
          <%= String.capitalize(category) %>
        </:label>
      </.checkbox_group>

  ## Card Styling

  When `card=true`, each checkbox option is wrapped in a styled container with:
  - Interactive hover and focus states
  - Data attributes for checked/unchecked styling (`data-state`)
  - Card variants (solid, outline, ghost) with color theming
  - Automatic error state styling (red) for invalid fields

  The wrapper classes are built using existing card helper functions and respond to:
  - `data-state="checked|unchecked"` - Selection state for conditional styling
  - `data-disabled="true|false"` - Disabled state styling
  """

  # Pulsar-specific styling attributes for checkbox group
  attr :card, :boolean,
    default: false,
    doc: "Apply card styling to all checkboxes in the group"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant (applies when card=true)"

  attr :color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme for all checkboxes (overridden by error state)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size for all checkboxes"

  # Stellar checkbox group attributes - passed through
  attr :field, FormField, required: true, doc: "Phoenix form field for the checkbox group"
  attr :options, :list, required: true, doc: "List of options in Phoenix format"
  attr :required, :boolean, default: false, doc: "Mark checkbox group as required"
  attr :disabled, :boolean, default: false, doc: "Disable all checkboxes in the group"
  attr :class, :string, default: "", doc: "Additional CSS classes for the fieldset container"
  attr :rest, :global, doc: "Additional HTML attributes"

  # Pass through Stellar's slots
  slot :legend, doc: "Legend content for fieldset"
  slot :select_all, doc: "Select all checkbox content"
  slot :label, doc: "Template for each checkbox label"

  @spec checkbox_group(map()) :: Rendered.t()
  def checkbox_group(assigns) do
    # Detect errors for color override
    has_errors = has_field_errors(assigns)
    effective_color = if has_errors, do: "danger", else: assigns.color

    # Build checkbox classes using existing helper functions
    checkbox_class =
      merge([
        base_checkbox_classes(),
        size_classes(assigns.size),
        color_classes(effective_color),
        state_classes(assigns.disabled, has_errors)
      ])

    # Build wrapper classes for card styling (uses Stellar's new wrapper_class)
    wrapper_class =
      if assigns.card do
        merge([
          card_base_classes(),
          card_variant_classes(assigns.variant, effective_color),
          card_size_classes(assigns.size),
          card_state_classes(assigns.disabled, has_errors)
        ])
      else
        ""
      end

    # Assign computed values to assigns
    assigns =
      assigns
      |> assign(:checkbox_class, checkbox_class)
      |> assign(:wrapper_class, wrapper_class)
      |> assign(:effective_color, effective_color)

    # Pass all attributes to Stellar with our styling
    ~H"""
    <StellarCheckbox.checkbox_group
      field={@field}
      options={@options}
      required={@required}
      disabled={@disabled}
      class={@class}
      checkbox_class={@checkbox_class}
      wrapper_class={@wrapper_class}
      {@rest}
    >
      <:legend :for={legend <- @legend} class={legend[:class] || ""}>
        {render_slot(legend)}
      </:legend>
      <:select_all
        :for={select_all <- @select_all}
        class={select_all[:class] || ""}
        label_class={select_all[:label_class] || ""}
        checkbox_class={select_all[:checkbox_class] || ""}
      >
        {render_slot(select_all)}
      </:select_all>
      <:label :let={label_text} :for={label <- @label} class={label[:class] || ""}>
        {render_slot(label, label_text)}
      </:label>
    </StellarCheckbox.checkbox_group>
    """
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
      aria-invalid={if @invalid, do: "true", else: "false"}
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
        aria-invalid={if @invalid, do: "true", else: "false"}
        {@rest}
      />

      <div class="flex-1 min-w-0">
        {render_slot(@inner_block)}
      </div>
    </label>
    """
  end

  # Base styles for checkbox input with custom checkmark
  defp base_checkbox_classes do
    """
    appearance-none relative cursor-pointer transition-all duration-200 ease-in-out
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 
    focus-visible:ring-ring dark:focus-visible:ring-dark-ring
    disabled:cursor-not-allowed disabled:opacity-50
    before:content-[''] before:absolute before:inset-0 before:rounded-inherit 
    before:border-2 before:transition-all before:duration-200 before:ease-in-out
    after:content-['✓'] after:absolute after:inset-0 after:flex after:items-center after:justify-center
    after:text-current after:font-bold after:transition-all after:duration-200 after:ease-in-out
    after:scale-0 after:opacity-0 
    data-[checked=true]:after:scale-100 data-[checked=true]:after:opacity-100
    data-[indeterminate=true]:after:content-['−'] data-[indeterminate=true]:after:scale-100 data-[indeterminate=true]:after:opacity-100
    """
  end

  # Size classes for checkbox
  defp size_classes("xs"), do: "h-3 w-3 rounded before:rounded after:text-[8px]"
  defp size_classes("sm"), do: "h-4 w-4 rounded before:rounded after:text-[10px]"
  defp size_classes("md"), do: "h-5 w-5 rounded-md before:rounded-md after:text-xs"
  defp size_classes("lg"), do: "h-6 w-6 rounded-md before:rounded-md after:text-sm"
  defp size_classes("xl"), do: "h-7 w-7 rounded-lg before:rounded-lg after:text-base"

  # Color classes for checkbox
  defp color_classes("neutral"),
    do:
      "text-neutral-foreground dark:text-dark-neutral-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-neutral dark:data-[checked=true]:before:border-dark-neutral data-[checked=true]:before:bg-neutral dark:data-[checked=true]:before:bg-dark-neutral data-[indeterminate=true]:before:border-neutral dark:data-[indeterminate=true]:before:border-dark-neutral data-[indeterminate=true]:before:bg-neutral dark:data-[indeterminate=true]:before:bg-dark-neutral"

  defp color_classes("primary"),
    do:
      "text-primary-foreground dark:text-dark-primary-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-primary dark:data-[checked=true]:before:border-dark-primary data-[checked=true]:before:bg-primary dark:data-[checked=true]:before:bg-dark-primary data-[indeterminate=true]:before:border-primary dark:data-[indeterminate=true]:before:border-dark-primary data-[indeterminate=true]:before:bg-primary dark:data-[indeterminate=true]:before:bg-dark-primary"

  defp color_classes("secondary"),
    do:
      "text-secondary-foreground dark:text-dark-secondary-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-secondary dark:data-[checked=true]:before:border-dark-secondary data-[checked=true]:before:bg-secondary dark:data-[checked=true]:before:bg-dark-secondary data-[indeterminate=true]:before:border-secondary dark:data-[indeterminate=true]:before:border-dark-secondary data-[indeterminate=true]:before:bg-secondary dark:data-[indeterminate=true]:before:bg-dark-secondary"

  defp color_classes("success"),
    do:
      "text-success-foreground dark:text-dark-success-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-success dark:data-[checked=true]:before:border-dark-success data-[checked=true]:before:bg-success dark:data-[checked=true]:before:bg-dark-success data-[indeterminate=true]:before:border-success dark:data-[indeterminate=true]:before:border-dark-success data-[indeterminate=true]:before:bg-success dark:data-[indeterminate=true]:before:bg-dark-success"

  defp color_classes("danger"),
    do:
      "text-danger-foreground dark:text-dark-danger-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-danger dark:data-[checked=true]:before:border-dark-danger data-[checked=true]:before:bg-danger dark:data-[checked=true]:before:bg-dark-danger data-[indeterminate=true]:before:border-danger dark:data-[indeterminate=true]:before:border-dark-danger data-[indeterminate=true]:before:bg-danger dark:data-[indeterminate=true]:before:bg-dark-danger"

  defp color_classes("warning"),
    do:
      "text-warning-foreground dark:text-dark-warning-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-warning dark:data-[checked=true]:before:border-dark-warning data-[checked=true]:before:bg-warning dark:data-[checked=true]:before:bg-dark-warning data-[indeterminate=true]:before:border-warning dark:data-[indeterminate=true]:before:border-dark-warning data-[indeterminate=true]:before:bg-warning dark:data-[indeterminate=true]:before:bg-dark-warning"

  defp color_classes("info"),
    do:
      "text-info-foreground dark:text-dark-info-foreground before:border-border dark:before:border-dark-border data-[checked=true]:before:border-info dark:data-[checked=true]:before:border-dark-info data-[checked=true]:before:bg-info dark:data-[checked=true]:before:bg-dark-info data-[indeterminate=true]:before:border-info dark:data-[indeterminate=true]:before:border-dark-info data-[indeterminate=true]:before:bg-info dark:data-[indeterminate=true]:before:bg-dark-info"

  # State classes for disabled/invalid states
  defp state_classes(disabled, invalid) do
    [
      disabled && "before:bg-surface-2 dark:before:bg-dark-surface-2",
      invalid && "before:border-danger dark:before:border-dark-danger"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Base card classes shared by all card variants
  defp card_base_classes do
    """
    flex items-start gap-3 rounded-lg cursor-pointer transition-all duration-200 ease-in-out
    focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ring 
    dark:focus-within:ring-dark-ring has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50
    """
  end

  # Card size classes
  defp card_size_classes("xs"), do: "p-2 gap-2 text-xs"
  defp card_size_classes("sm"), do: "p-3 gap-2 text-sm"
  defp card_size_classes("md"), do: "p-4 gap-3"
  defp card_size_classes("lg"), do: "p-5 gap-4 text-lg"
  defp card_size_classes("xl"), do: "p-6 gap-5 text-xl"

  # Solid card variants
  defp card_variant_classes("solid", "neutral") do
    [
      "bg-neutral/10 hover:bg-neutral/20 dark:bg-dark-neutral/20 dark:hover:bg-dark-neutral/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "primary") do
    [
      "bg-primary/10 hover:bg-primary/20 dark:bg-dark-primary/20 dark:hover:bg-dark-primary/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "secondary") do
    [
      "bg-secondary/10 hover:bg-secondary/20 dark:bg-dark-secondary/20 dark:hover:bg-dark-secondary/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "success") do
    [
      "bg-success/10 hover:bg-success/20 dark:bg-dark-success/20 dark:hover:bg-dark-success/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "danger") do
    [
      "bg-danger/10 hover:bg-danger/20 dark:bg-dark-danger/20 dark:hover:bg-dark-danger/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "warning") do
    [
      "bg-warning/10 hover:bg-warning/20 dark:bg-dark-warning/20 dark:hover:bg-dark-warning/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("solid", "info") do
    [
      "bg-info/10 hover:bg-info/20 dark:bg-dark-info/20 dark:hover:bg-dark-info/30",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  # Outline card variants
  defp card_variant_classes("outline", "neutral") do
    [
      "bg-background dark:bg-dark-background",
      "border-2 border-border hover:border-primary/50 dark:border-dark-border dark:hover:border-dark-primary/50",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "primary") do
    [
      "bg-background hover:bg-primary/5 dark:bg-dark-background dark:hover:bg-dark-primary/10",
      "border-2 border-primary/30 hover:border-primary dark:border-dark-primary/30 dark:hover:border-dark-primary",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "secondary") do
    [
      "bg-background hover:bg-secondary/5 dark:bg-dark-background dark:hover:bg-dark-secondary/10",
      "border-2 border-secondary/30 hover:border-secondary dark:border-dark-secondary/30 dark:hover:border-dark-secondary",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "success") do
    [
      "bg-background hover:bg-success/5 dark:bg-dark-background dark:hover:bg-dark-success/10",
      "border-2 border-success/30 hover:border-success dark:border-dark-success/30 dark:hover:border-dark-success",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "danger") do
    [
      "bg-background hover:bg-danger/5 dark:bg-dark-background dark:hover:bg-dark-danger/10",
      "border-2 border-danger/30 hover:border-danger dark:border-dark-danger/30 dark:hover:border-dark-danger",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "warning") do
    [
      "bg-background hover:bg-warning/5 dark:bg-dark-background dark:hover:bg-dark-warning/10",
      "border-2 border-warning/30 hover:border-warning dark:border-dark-warning/30 dark:hover:border-dark-warning",
      "hover:shadow-md"
    ]
  end

  defp card_variant_classes("outline", "info") do
    [
      "bg-background hover:bg-info/5 dark:bg-dark-background dark:hover:bg-dark-info/10",
      "border-2 border-info/30 hover:border-info dark:border-dark-info/30 dark:hover:border-dark-info",
      "hover:shadow-md"
    ]
  end

  # Ghost card variants
  defp card_variant_classes("ghost", "neutral") do
    [
      "bg-transparent hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "primary") do
    [
      "bg-transparent hover:bg-primary/10 dark:hover:bg-dark-primary/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "secondary") do
    [
      "bg-transparent hover:bg-secondary/10 dark:hover:bg-dark-secondary/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "success") do
    [
      "bg-transparent hover:bg-success/10 dark:hover:bg-dark-success/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "danger") do
    [
      "bg-transparent hover:bg-danger/10 dark:hover:bg-dark-danger/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "warning") do
    [
      "bg-transparent hover:bg-warning/10 dark:hover:bg-dark-warning/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  defp card_variant_classes("ghost", "info") do
    [
      "bg-transparent hover:bg-info/10 dark:hover:bg-dark-info/10",
      "border-2 border-transparent",
      "hover:shadow-sm"
    ]
  end

  # Card state classes
  defp card_state_classes(disabled, invalid) do
    [
      disabled && "bg-surface-2 dark:bg-dark-surface-2 border-border/50 dark:border-dark-border/50",
      invalid && "border-danger dark:border-dark-danger bg-danger/5 dark:bg-dark-danger/10"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Helper for error detection
  defp has_field_errors(%{field: %FormField{errors: errs}}) when is_list(errs) and errs != [], do: true
  defp has_field_errors(_), do: false
end
