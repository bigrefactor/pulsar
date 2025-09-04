defmodule Pulsar.Components.RadioGroup do
  @moduledoc """
  Styled radio group component built on Stellar.Components.RadioGroup.

  Provides beautiful, accessible radio button groups with custom design and card-style
  layouts. All styling is applied via Tailwind CSS utilities with semantic color tokens
  that support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible radio group component with roving tabindex
  - **Custom Radio Design**: Styled radio buttons with smooth animations
  - **Card-style Options**: Rich card layouts with descriptions and custom content
   - **Flexible Layouts**: Use the `class` attribute for any layout (flex, grid, etc.)
  - **Size Variants**: xs, sm, md, lg, xl for complete range
  - **Color Variants**: neutral, primary, secondary, success, danger, warning, info for consistent theming
  - **Hover and Focus States**: Smooth interactive feedback
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar radio group props are supported

  ## Examples

      # Basic radio group
      <.radio_group field={@form[:plan]}>
        <:option value="basic">Basic Plan</:option>
        <:option value="pro">Pro Plan</:option>
        <:option value="enterprise">Enterprise Plan</:option>
      </.radio_group>

      # With size and color variants (horizontal layout)
      <.radio_group field={@form[:size]} color="primary" size="lg" class="flex flex-row gap-6">
        <:option value="sm">Small</:option>
        <:option value="md">Medium</:option>
        <:option value="lg">Large</:option>
      </.radio_group>

      # Card-style layout with descriptions
      <.radio_group field={@form[:plan]} card variant="outline" color="primary">
        <:option value="basic">
          <div class="font-medium">Basic Plan</div>
          <div class="text-sm text-muted-foreground mt-1">Perfect for individuals</div>
          <div class="text-sm font-semibold mt-2">$10/month</div>
        </:option>
        <:option value="pro">
          <div class="font-medium">Pro Plan</div>
          <div class="text-sm text-muted-foreground mt-1">Great for teams</div>
          <div class="text-sm font-semibold mt-2">$25/month</div>
        </:option>
      </.radio_group>

      # Grid layout with cards
      <.radio_group field={@form[:theme]} card class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <:option value="light">
          <div class="text-center">
            <div class="text-2xl mb-2">☀️</div>
            <div class="font-medium">Light</div>
          </div>
        </:option>
        <:option value="dark">
          <div class="text-center">
            <div class="text-2xl mb-2">🌙</div>
            <div class="font-medium">Dark</div>
          </div>
        </:option>
        <:option value="auto">
          <div class="text-center">
            <div class="text-2xl mb-2">💻</div>
            <div class="font-medium">Auto</div>
          </div>
        </:option>
      </.radio_group>

      # Card-only selection (hidden radio inputs)
      <.radio_group field={@form[:plan]} card hide_radios variant="outline">
        <:option value="starter">
          <div class="text-center">
            <div class="text-2xl mb-2">🚀</div>
            <div class="font-medium">Starter</div>
            <div class="text-sm text-muted-foreground">Get started quickly</div>
          </div>
        </:option>
        <:option value="professional">
          <div class="text-center">
            <div class="text-2xl mb-2">💼</div>
            <div class="font-medium">Professional</div>
            <div class="text-sm text-muted-foreground">For growing teams</div>
          </div>
        </:option>
      </.radio_group>

  ## Stellar Integration

  This component wraps Stellar.Components.RadioGroup and passes through all its props:
  - `:field` - Phoenix form field integration with automatic validation
  - `:name`, `:value` - Form control attributes
  - `:orientation` - Keyboard navigation direction
  - `:disabled`, `:required`, `:invalid` - Form states
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered
  alias Stellar.Components.RadioGroup, as: StellarRadioGroup

  # Card style (matching checkbox pattern)
  attr(:card, :boolean,
    default: false,
    doc: "Render options as clickable cards"
  )

  attr(:hide_radios, :boolean,
    default: false,
    doc: "Hide the radio inputs (useful for card-only selection)"
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant (applies when card=true)"
  )

  # Common styling
  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the radio group"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the radio buttons and cards"
  )

  # Stellar radio group attributes - copied from Stellar.Components.RadioGroup
  attr(:field, FormField, default: nil, doc: "Phoenix form field for automatic validation")

  # Core attributes
  attr(:id, :string, default: nil, doc: "Radio group ID (auto-generated if not provided)")
  attr(:name, :string, default: nil, doc: "Name for the radio group")
  attr(:value, :any, default: nil, doc: "Currently selected value")

  # Radio group-specific attributes
  attr(:orientation, :string,
    default: "vertical",
    values: ["horizontal", "vertical"],
    doc: "Orientation affects arrow key navigation"
  )

  # State attributes
  attr(:disabled, :boolean, default: false)
  attr(:invalid, :boolean, default: nil, doc: "Marks the radio group as having validation errors")
  attr(:required, :boolean, default: false, doc: "Marks the radio group as required")

  # Styling
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:label_color, :string,
    default: "neutral",
    values: ~w(neutral inherit),
    doc: "Label text color: neutral (default) or inherit to match radio color"
  )

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes like aria-label, aria-labelledby")

  # Slots for radio options
  slot :option, required: true, doc: "Radio option" do
    attr(:value, :any, required: true)
    attr(:disabled, :boolean)
    attr(:checked, :boolean, doc: "Override automatic checked state")
    attr(:class, :string, doc: "Additional CSS classes for this option")
  end

  @doc """
  Renders a styled radio group component.

  This function wraps Stellar.Components.RadioGroup with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via CSS classes
  that respond to the radio group's card and layout state.

  ## Card vs Layout

  - **card**: Visual style - renders options as clickable cards
  - **class**: Spatial arrangement - use Tailwind classes for flex, grid, etc.

  ## Examples

      # Standard radio group
      <.radio_group field={@form[:plan]} color="primary" size="lg">
        <:option value="basic">Basic Plan</:option>
        <:option value="pro">Pro Plan</:option>
      </.radio_group>

      # Card style with flex layout
      <.radio_group field={@form[:plan]} card variant="outline">
        <:option value="basic">
          <div class="font-medium">Basic Plan</div>
          <div class="text-sm text-muted-foreground">Perfect for individuals</div>
        </:option>
      </.radio_group>

      # Card style with grid layout  
      <.radio_group field={@form[:theme]} card class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <:option value="light">Light Theme</:option>
        <:option value="dark">Dark Theme</:option>
        <:option value="auto">Auto Theme</:option>
      </.radio_group>
  """
  @spec radio_group(map()) :: Rendered.t()
  def radio_group(assigns) do
    # Detect errors and compute automatic color
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Compute name and value from field if not provided (presence-aware, not truthy)
    # Note: ID is handled by Stellar's normalize_field_props, no need to duplicate
    computed_name =
      if Map.has_key?(assigns, :name) and not is_nil(assigns.name) do
        assigns.name
      else
        if assigns[:field] do
          to_string(assigns.field.name)
        end
      end

    computed_value =
      if Map.has_key?(assigns, :value) and not is_nil(assigns.value) do
        assigns.value
      else
        if assigns[:field] do
          assigns.field.value
        end
      end

    # Build class string for radio group container with incremental approach
    container_class =
      [
        container_base_classes(),
        assigns.class
      ]
      |> Enum.filter(&(&1 != ""))
      |> merge()

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)
      |> assign(:computed_name, computed_name)
      |> assign(:computed_value, computed_value)

    ~H"""
    <StellarRadioGroup.radio_group
      :let={group}
      field={@field}
      id={@id}
      name={@computed_name}
      value={@computed_value}
      orientation={@orientation}
      disabled={@disabled}
      invalid={@invalid}
      required={@required}
      class={@container_class}
      {@rest}
    >
      <%= for {option, index} <- Enum.with_index(@option) do %>
        {render_radio_option(assigns, option, group, index)}
      <% end %>
    </StellarRadioGroup.radio_group>
    """
  end

  # Render individual radio option with group context from Stellar
  defp render_radio_option(assigns, option, group, option_index) do
    # Generate unique ID for this radio option using deterministic indexing
    radio_id = "#{group.id}-#{option_index}"

    # Determine checked state - explicit checked attribute takes precedence
    checked =
      if Map.has_key?(option, :checked) do
        Map.get(option, :checked)
      else
        values_equal?(group.value, option.value)
      end

    # Determine disabled state
    disabled = Map.get(option, :disabled, false) || group.disabled

    # Create new assigns with computed values
    option_assigns =
      assigns
      |> assign(:option, option)
      |> assign(:group, group)
      |> assign(:radio_id, radio_id)
      |> assign(:option_checked, checked)
      |> assign(:option_disabled, disabled)

    if assigns.card do
      render_card_radio(option_assigns)
    else
      render_default_radio(option_assigns)
    end
  end

  # Standard radio with label
  defp render_default_radio(assigns) do
    # Build radio input classes
    radio_input_class =
      if assigns.hide_radios do
        "sr-only"
      else
        radio_input_classes(assigns.effective_color, assigns.size)
      end

    assigns = assign(assigns, :radio_input_class, radio_input_class)

    ~H"""
    <div class={
      merge(
        [radio_option_base_classes(), @option_disabled && "opacity-50", Map.get(@option, :class, "")]
        |> Enum.filter(& &1)
      )
    }>
      <input
        type="radio"
        id={@radio_id}
        name={@group.name}
        value={@option.value}
        checked={@option_checked}
        required={@group.required}
        disabled={@option_disabled}
        aria-invalid={@group.invalid && "true"}
        aria-required={@group.required && "true"}
        class={@radio_input_class}
      />
      <label for={@radio_id} class={radio_label_classes(@size, @effective_color, @label_color)}>
        {render_slot(@option)}
      </label>
    </div>
    """
  end

  # Card-style radio (matching checkbox card pattern)
  # Data attributes data-checked and data-disabled are provided on card labels
  # for custom styling hooks and JavaScript integration
  defp render_card_radio(assigns) do
    # Build card container classes
    container_class =
      [
        card_base_classes(assigns.effective_color, assigns.size),
        card_variant_classes(assigns.variant, assigns.effective_color),
        card_state_classes(assigns.option_disabled, assigns.invalid),
        Map.get(assigns.option, :class, "")
      ]
      |> Enum.filter(&(&1 != ""))
      |> merge()

    # Build radio input classes
    radio_class =
      if assigns.hide_radios do
        "sr-only"
      else
        radio_input_classes(assigns.effective_color, assigns.size)
      end

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:radio_class, radio_class)

    ~H"""
    <label
      for={@radio_id}
      class={@container_class}
      data-checked={(@option_checked && "true") || "false"}
      data-disabled={(@option_disabled && "true") || "false"}
      data-state={if @option_checked, do: "checked", else: "unchecked"}
    >
      <input
        type="radio"
        id={@radio_id}
        name={@group.name}
        value={@option.value}
        checked={@option_checked}
        required={@group.required}
        disabled={@option_disabled}
        aria-invalid={@group.invalid && "true"}
        aria-required={@group.required && "true"}
        aria-describedby={"#{@radio_id}-content"}
        class={@radio_class}
      />
      <div
        class="flex-1 min-w-0 overflow-hidden"
        id={"#{@radio_id}-content"}
      >
        {render_slot(@option)}
      </div>
    </label>
    """
  end

  # Base styles for radio group container
  @spec container_base_classes() :: String.t()
  defp container_base_classes do
    "flex flex-col gap-3"
  end

  # Radio color classes - only generates needed classes for the selected color
  @spec radio_color_classes(String.t()) :: String.t()
  defp radio_color_classes(color) do
    [
      radio_border_classes(color),
      radio_background_classes(color),
      radio_ring_classes(color),
      radio_foreground_classes(color)
    ]
    |> merge()
  end

  # Radio border classes for each color
  @spec radio_border_classes(String.t()) :: String.t()
  defp radio_border_classes("neutral") do
    "border-border dark:border-dark-border checked:border-neutral dark:checked:border-dark-neutral"
  end

  defp radio_border_classes("primary") do
    "border-border dark:border-dark-border checked:border-primary dark:checked:border-dark-primary"
  end

  defp radio_border_classes("secondary") do
    "border-border dark:border-dark-border checked:border-secondary dark:checked:border-dark-secondary"
  end

  defp radio_border_classes("success") do
    "border-border dark:border-dark-border checked:border-success dark:checked:border-dark-success"
  end

  defp radio_border_classes("danger") do
    "border-border dark:border-dark-border checked:border-danger dark:checked:border-dark-danger"
  end

  defp radio_border_classes("warning") do
    "border-border dark:border-dark-border checked:border-warning dark:checked:border-dark-warning"
  end

  defp radio_border_classes("info") do
    "border-border dark:border-dark-border checked:border-info dark:checked:border-dark-info"
  end

  # Radio background classes for each color
  @spec radio_background_classes(String.t()) :: String.t()
  defp radio_background_classes("neutral") do
    "bg-background dark:bg-dark-background checked:bg-neutral dark:checked:bg-dark-neutral"
  end

  defp radio_background_classes("primary") do
    "bg-background dark:bg-dark-background checked:bg-primary dark:checked:bg-dark-primary"
  end

  defp radio_background_classes("secondary") do
    "bg-background dark:bg-dark-background checked:bg-secondary dark:checked:bg-dark-secondary"
  end

  defp radio_background_classes("success") do
    "bg-background dark:bg-dark-background checked:bg-success dark:checked:bg-dark-success"
  end

  defp radio_background_classes("danger") do
    "bg-background dark:bg-dark-background checked:bg-danger dark:checked:bg-dark-danger"
  end

  defp radio_background_classes("warning") do
    "bg-background dark:bg-dark-background checked:bg-warning dark:checked:bg-dark-warning"
  end

  defp radio_background_classes("info") do
    "bg-background dark:bg-dark-background checked:bg-info dark:checked:bg-dark-info"
  end

  # Radio ring classes for focus states
  @spec radio_ring_classes(String.t()) :: String.t()
  defp radio_ring_classes("neutral") do
    "focus-visible:ring-neutral dark:focus-visible:ring-dark-neutral"
  end

  defp radio_ring_classes("primary") do
    "focus-visible:ring-primary dark:focus-visible:ring-dark-primary"
  end

  defp radio_ring_classes("secondary") do
    "focus-visible:ring-secondary dark:focus-visible:ring-dark-secondary"
  end

  defp radio_ring_classes("success") do
    "focus-visible:ring-success dark:focus-visible:ring-dark-success"
  end

  defp radio_ring_classes("danger") do
    "focus-visible:ring-danger dark:focus-visible:ring-dark-danger"
  end

  defp radio_ring_classes("warning") do
    "focus-visible:ring-warning dark:focus-visible:ring-dark-warning"
  end

  defp radio_ring_classes("info") do
    "focus-visible:ring-info dark:focus-visible:ring-dark-info"
  end

  # Radio foreground classes for the before pseudo-element (the inner dot)
  @spec radio_foreground_classes(String.t()) :: String.t()
  defp radio_foreground_classes("neutral") do
    "before:bg-neutral-foreground dark:before:bg-dark-neutral-foreground"
  end

  defp radio_foreground_classes("primary") do
    "before:bg-primary-foreground dark:before:bg-dark-primary-foreground"
  end

  defp radio_foreground_classes("secondary") do
    "before:bg-secondary-foreground dark:before:bg-dark-secondary-foreground"
  end

  defp radio_foreground_classes("success") do
    "before:bg-success-foreground dark:before:bg-dark-success-foreground"
  end

  defp radio_foreground_classes("danger") do
    "before:bg-danger-foreground dark:before:bg-dark-danger-foreground"
  end

  defp radio_foreground_classes("warning") do
    "before:bg-warning-foreground dark:before:bg-dark-warning-foreground"
  end

  defp radio_foreground_classes("info") do
    "before:bg-info-foreground dark:before:bg-dark-info-foreground"
  end

  # Radio size classes - direct size application
  @spec radio_size_classes(String.t()) :: String.t()
  defp radio_size_classes("xs"), do: "w-3 h-3"
  defp radio_size_classes("sm"), do: "w-4 h-4"
  defp radio_size_classes("md"), do: "w-5 h-5"
  defp radio_size_classes("lg"), do: "w-6 h-6"
  defp radio_size_classes("xl"), do: "w-7 h-7"

  # Radio size classes for the ::before pseudo-element
  @spec radio_before_size_classes(String.t()) :: String.t()
  defp radio_before_size_classes("xs"), do: "before:inset-0.5"
  defp radio_before_size_classes("sm"), do: "before:inset-0.5"
  defp radio_before_size_classes("md"), do: "before:inset-1"
  defp radio_before_size_classes("lg"), do: "before:inset-1.5"
  defp radio_before_size_classes("xl"), do: "before:inset-1.5"

  # Card padding and gap classes (only applied when card=true)
  @spec card_padding_classes(String.t()) :: String.t()
  defp card_padding_classes("xs"), do: "p-2 gap-2"
  defp card_padding_classes("sm"), do: "p-3 gap-2"
  defp card_padding_classes("md"), do: "p-4 gap-3"
  defp card_padding_classes("lg"), do: "p-5 gap-4"
  defp card_padding_classes("xl"), do: "p-6 gap-5"

  # Base classes for radio option container
  @spec radio_option_base_classes() :: String.t()
  defp radio_option_base_classes do
    """
    relative flex items-center gap-3
    """
  end

  # Base classes for radio input - now built with separate functions
  @spec radio_input_classes(String.t(), String.t()) :: String.t()
  defp radio_input_classes(color, size) do
    [
      radio_input_base_classes(),
      radio_size_classes(size),
      radio_before_size_classes(size),
      radio_color_classes(color),
      radio_hover_classes(color)
    ]
    |> List.flatten()
    |> merge()
  end

  # Core radio input styles without size or color
  @spec radio_input_base_classes() :: String.t()
  defp radio_input_base_classes do
    """
    appearance-none relative cursor-pointer transition-all duration-200 ease-in-out
    rounded-full border-2 
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2
    disabled:cursor-not-allowed disabled:opacity-50
    before:content-[''] before:absolute before:rounded-full 
    before:transition-all before:duration-200 
    before:scale-0 before:opacity-0
    checked:before:scale-100 checked:before:opacity-100
    """
  end

  # Hover classes for radio inputs
  @spec radio_hover_classes(String.t()) :: String.t()
  defp radio_hover_classes("neutral") do
    "hover:border-neutral/70 dark:hover:border-dark-neutral/70 hover:shadow-sm"
  end

  defp radio_hover_classes("primary") do
    "hover:border-primary/70 dark:hover:border-dark-primary/70 hover:shadow-sm"
  end

  defp radio_hover_classes("secondary") do
    "hover:border-secondary/70 dark:hover:border-dark-secondary/70 hover:shadow-sm"
  end

  defp radio_hover_classes("success") do
    "hover:border-success/70 dark:hover:border-dark-success/70 hover:shadow-sm"
  end

  defp radio_hover_classes("danger") do
    "hover:border-danger/70 dark:hover:border-dark-danger/70 hover:shadow-sm"
  end

  defp radio_hover_classes("warning") do
    "hover:border-warning/70 dark:hover:border-dark-warning/70 hover:shadow-sm"
  end

  defp radio_hover_classes("info") do
    "hover:border-info/70 dark:hover:border-dark-info/70 hover:shadow-sm"
  end

  # Classes for radio labels (standard non-card)
  @spec radio_label_classes(String.t(), String.t(), String.t()) :: String.t()
  defp radio_label_classes(size, color, label_color) do
    base_classes = "cursor-pointer select-none transition-all duration-200 flex-1 min-w-0"
    effective_label_color = if label_color == "inherit", do: color, else: "neutral"

    [
      base_classes,
      radio_label_text_classes(size),
      radio_label_color_classes(effective_label_color)
    ]
    |> merge()
  end

  # Text size classes for radio labels
  @spec radio_label_text_classes(String.t()) :: String.t()
  defp radio_label_text_classes("xs"), do: "text-xs"
  defp radio_label_text_classes("sm"), do: "text-sm"
  defp radio_label_text_classes("md"), do: "text-base"
  defp radio_label_text_classes("lg"), do: "text-lg"
  defp radio_label_text_classes("xl"), do: "text-xl"

  # Color classes for radio labels
  @spec radio_label_color_classes(String.t()) :: String.t()
  defp radio_label_color_classes("neutral"), do: "text-foreground dark:text-dark-foreground"
  defp radio_label_color_classes("primary"), do: "text-primary dark:text-dark-primary"
  defp radio_label_color_classes("secondary"), do: "text-secondary dark:text-dark-secondary"
  defp radio_label_color_classes("success"), do: "text-success dark:text-dark-success"
  defp radio_label_color_classes("danger"), do: "text-danger dark:text-dark-danger"
  defp radio_label_color_classes("warning"), do: "text-warning dark:text-dark-warning"
  defp radio_label_color_classes("info"), do: "text-info dark:text-dark-info"

  # Card base styles (without CSS variables)
  @spec card_base_classes(String.t(), String.t()) :: String.t()
  defp card_base_classes(color, size) do
    [
      "relative flex items-start rounded-lg border-2",
      "cursor-pointer transition-all duration-200 ease-in-out",
      "focus-within:ring-2 focus-within:ring-offset-2",
      card_padding_classes(size),
      card_size_text_classes(size),
      card_focus_ring_classes(color)
    ]
    |> merge()
  end

  # Card focus ring classes by color
  @spec card_focus_ring_classes(String.t()) :: String.t()
  defp card_focus_ring_classes("neutral"), do: "focus-within:ring-neutral dark:focus-within:ring-dark-neutral"

  defp card_focus_ring_classes("primary"), do: "focus-within:ring-primary dark:focus-within:ring-dark-primary"

  defp card_focus_ring_classes("secondary"), do: "focus-within:ring-secondary dark:focus-within:ring-dark-secondary"

  defp card_focus_ring_classes("success"), do: "focus-within:ring-success dark:focus-within:ring-dark-success"

  defp card_focus_ring_classes("danger"), do: "focus-within:ring-danger dark:focus-within:ring-dark-danger"

  defp card_focus_ring_classes("warning"), do: "focus-within:ring-warning dark:focus-within:ring-dark-warning"

  defp card_focus_ring_classes("info"), do: "focus-within:ring-info dark:focus-within:ring-dark-info"

  # Card variant styles with direct color classes
  @spec card_variant_classes(String.t(), String.t()) :: String.t()
  defp card_variant_classes("solid", color) do
    [
      "border-transparent",
      card_variant_background_classes("solid", color),
      card_variant_hover_classes("solid", color),
      card_variant_checked_classes("solid", color)
    ]
    |> Enum.join(" ")
  end

  defp card_variant_classes("outline", color) do
    [
      card_variant_background_classes("outline", color),
      card_variant_border_classes("outline", color),
      card_variant_hover_classes("outline", color),
      card_variant_checked_classes("outline", color)
    ]
    |> Enum.join(" ")
  end

  defp card_variant_classes("ghost", color) do
    [
      "border-transparent bg-transparent",
      card_variant_hover_classes("ghost", color),
      card_variant_checked_classes("ghost", color)
    ]
    |> Enum.join(" ")
  end

  # Card background classes by variant
  @spec card_variant_background_classes(String.t(), String.t()) :: String.t()
  defp card_variant_background_classes("solid", _color), do: "bg-background dark:bg-dark-background"

  defp card_variant_background_classes("outline", _color), do: "bg-background dark:bg-dark-background"

  defp card_variant_background_classes("ghost", _color), do: "bg-transparent"

  # Card border classes by variant and color
  @spec card_variant_border_classes(String.t(), String.t()) :: String.t()
  defp card_variant_border_classes("outline", _color), do: "border-border dark:border-dark-border"

  # Card hover classes by variant and color
  @spec card_variant_hover_classes(String.t(), String.t()) :: String.t()
  defp card_variant_hover_classes("solid", "neutral"), do: "hover:bg-neutral/10 dark:hover:bg-dark-neutral/10"

  defp card_variant_hover_classes("solid", "primary"), do: "hover:bg-primary/10 dark:hover:bg-dark-primary/10"

  defp card_variant_hover_classes("solid", "secondary"), do: "hover:bg-secondary/10 dark:hover:bg-dark-secondary/10"

  defp card_variant_hover_classes("solid", "success"), do: "hover:bg-success/10 dark:hover:bg-dark-success/10"

  defp card_variant_hover_classes("solid", "danger"), do: "hover:bg-danger/10 dark:hover:bg-dark-danger/10"

  defp card_variant_hover_classes("solid", "warning"), do: "hover:bg-warning/10 dark:hover:bg-dark-warning/10"

  defp card_variant_hover_classes("solid", "info"), do: "hover:bg-info/10 dark:hover:bg-dark-info/10"

  defp card_variant_hover_classes("outline", "neutral"),
    do: "hover:border-neutral/50 dark:hover:border-dark-neutral/50 hover:bg-neutral/5 dark:hover:bg-dark-neutral/5"

  defp card_variant_hover_classes("outline", "primary"),
    do: "hover:border-primary/50 dark:hover:border-dark-primary/50 hover:bg-primary/5 dark:hover:bg-dark-primary/5"

  defp card_variant_hover_classes("outline", "secondary"),
    do:
      "hover:border-secondary/50 dark:hover:border-dark-secondary/50 hover:bg-secondary/5 dark:hover:bg-dark-secondary/5"

  defp card_variant_hover_classes("outline", "success"),
    do: "hover:border-success/50 dark:hover:border-dark-success/50 hover:bg-success/5 dark:hover:bg-dark-success/5"

  defp card_variant_hover_classes("outline", "danger"),
    do: "hover:border-danger/50 dark:hover:border-dark-danger/50 hover:bg-danger/5 dark:hover:bg-dark-danger/5"

  defp card_variant_hover_classes("outline", "warning"),
    do: "hover:border-warning/50 dark:hover:border-dark-warning/50 hover:bg-warning/5 dark:hover:bg-dark-warning/5"

  defp card_variant_hover_classes("outline", "info"),
    do: "hover:border-info/50 dark:hover:border-dark-info/50 hover:bg-info/5 dark:hover:bg-dark-info/5"

  defp card_variant_hover_classes("ghost", "neutral"), do: "hover:bg-neutral/10 dark:hover:bg-dark-neutral/10"

  defp card_variant_hover_classes("ghost", "primary"), do: "hover:bg-primary/10 dark:hover:bg-dark-primary/10"

  defp card_variant_hover_classes("ghost", "secondary"), do: "hover:bg-secondary/10 dark:hover:bg-dark-secondary/10"

  defp card_variant_hover_classes("ghost", "success"), do: "hover:bg-success/10 dark:hover:bg-dark-success/10"

  defp card_variant_hover_classes("ghost", "danger"), do: "hover:bg-danger/10 dark:hover:bg-dark-danger/10"

  defp card_variant_hover_classes("ghost", "warning"), do: "hover:bg-warning/10 dark:hover:bg-dark-warning/10"

  defp card_variant_hover_classes("ghost", "info"), do: "hover:bg-info/10 dark:hover:bg-dark-info/10"

  # Card checked state classes by variant and color - using :checked pseudo-class
  @spec card_variant_checked_classes(String.t(), String.t()) :: String.t()
  defp card_variant_checked_classes("solid", "neutral"),
    do: "has-[:checked]:bg-neutral/20 dark:has-[:checked]:bg-dark-neutral/20"

  defp card_variant_checked_classes("solid", "primary"),
    do: "has-[:checked]:bg-primary/20 dark:has-[:checked]:bg-dark-primary/20"

  defp card_variant_checked_classes("solid", "secondary"),
    do: "has-[:checked]:bg-secondary/20 dark:has-[:checked]:bg-dark-secondary/20"

  defp card_variant_checked_classes("solid", "success"),
    do: "has-[:checked]:bg-success/20 dark:has-[:checked]:bg-dark-success/20"

  defp card_variant_checked_classes("solid", "danger"),
    do: "has-[:checked]:bg-danger/20 dark:has-[:checked]:bg-dark-danger/20"

  defp card_variant_checked_classes("solid", "warning"),
    do: "has-[:checked]:bg-warning/20 dark:has-[:checked]:bg-dark-warning/20"

  defp card_variant_checked_classes("solid", "info"),
    do: "has-[:checked]:bg-info/20 dark:has-[:checked]:bg-dark-info/20"

  defp card_variant_checked_classes("outline", "neutral"),
    do:
      "has-[:checked]:border-neutral dark:has-[:checked]:border-dark-neutral has-[:checked]:bg-neutral/10 dark:has-[:checked]:bg-dark-neutral/10"

  defp card_variant_checked_classes("outline", "primary"),
    do:
      "has-[:checked]:border-primary dark:has-[:checked]:border-dark-primary has-[:checked]:bg-primary/10 dark:has-[:checked]:bg-dark-primary/10"

  defp card_variant_checked_classes("outline", "secondary"),
    do:
      "has-[:checked]:border-secondary dark:has-[:checked]:border-dark-secondary has-[:checked]:bg-secondary/10 dark:has-[:checked]:bg-dark-secondary/10"

  defp card_variant_checked_classes("outline", "success"),
    do:
      "has-[:checked]:border-success dark:has-[:checked]:border-dark-success has-[:checked]:bg-success/10 dark:has-[:checked]:bg-dark-success/10"

  defp card_variant_checked_classes("outline", "danger"),
    do:
      "has-[:checked]:border-danger dark:has-[:checked]:border-dark-danger has-[:checked]:bg-danger/10 dark:has-[:checked]:bg-dark-danger/10"

  defp card_variant_checked_classes("outline", "warning"),
    do:
      "has-[:checked]:border-warning dark:has-[:checked]:border-dark-warning has-[:checked]:bg-warning/10 dark:has-[:checked]:bg-dark-warning/10"

  defp card_variant_checked_classes("outline", "info"),
    do:
      "has-[:checked]:border-info dark:has-[:checked]:border-dark-info has-[:checked]:bg-info/10 dark:has-[:checked]:bg-dark-info/10"

  defp card_variant_checked_classes("ghost", "neutral"),
    do: "has-[:checked]:bg-neutral/15 dark:has-[:checked]:bg-dark-neutral/15"

  defp card_variant_checked_classes("ghost", "primary"),
    do: "has-[:checked]:bg-primary/15 dark:has-[:checked]:bg-dark-primary/15"

  defp card_variant_checked_classes("ghost", "secondary"),
    do: "has-[:checked]:bg-secondary/15 dark:has-[:checked]:bg-dark-secondary/15"

  defp card_variant_checked_classes("ghost", "success"),
    do: "has-[:checked]:bg-success/15 dark:has-[:checked]:bg-dark-success/15"

  defp card_variant_checked_classes("ghost", "danger"),
    do: "has-[:checked]:bg-danger/15 dark:has-[:checked]:bg-dark-danger/15"

  defp card_variant_checked_classes("ghost", "warning"),
    do: "has-[:checked]:bg-warning/15 dark:has-[:checked]:bg-dark-warning/15"

  defp card_variant_checked_classes("ghost", "info"),
    do: "has-[:checked]:bg-info/15 dark:has-[:checked]:bg-dark-info/15"

  # Card text size styles
  @spec card_size_text_classes(String.t()) :: String.t()
  defp card_size_text_classes("xs"), do: "text-xs"
  defp card_size_text_classes("sm"), do: "text-sm"
  defp card_size_text_classes("md"), do: "text-base"
  defp card_size_text_classes("lg"), do: "text-lg"
  defp card_size_text_classes("xl"), do: "text-xl"

  # Card state styles
  @spec card_state_classes(boolean(), boolean()) :: String.t()
  defp card_state_classes(disabled, invalid) do
    [
      disabled && "opacity-50 cursor-not-allowed",
      invalid && "border-danger ring-1 ring-danger ring-offset-1"
    ]
    |> Enum.filter(& &1)
    |> merge()
  end

  # Helper for proper value comparison using Phoenix's normalization
  @spec values_equal?(any(), any()) :: boolean()
  defp values_equal?(val1, val2) do
    Form.normalize_value("radio", val1) ==
      Form.normalize_value("radio", val2)
  end

  # Helper for error detection - checks if a Phoenix form field has validation errors
  @spec has_field_errors(map()) :: boolean()
  defp has_field_errors(%{field: %FormField{errors: errs}}) when is_list(errs) and errs != [], do: true

  defp has_field_errors(_), do: false
end
