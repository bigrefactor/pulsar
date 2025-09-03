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
  - **Grid and Flex Layouts**: Flexible layout options for different UI needs
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

      # With size and color variants
      <.radio_group field={@form[:size]} color="primary" size="lg" orientation="horizontal">
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
      <.radio_group field={@form[:theme]} card layout="grid" columns={3}>
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
  - `:error_message` - Validation error display
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

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

  # Layout (independent of card)
  attr(:layout, :string,
    default: "flex",
    values: ~w(flex grid),
    doc: "Layout arrangement for the radio options"
  )

  attr(:columns, :integer,
    default: 2,
    doc: "Number of columns for grid layout"
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
    doc: "Orientation affects arrow key navigation (ignored when layout='grid')"
  )

  # State attributes
  attr(:disabled, :boolean, default: false)
  attr(:invalid, :boolean, default: nil, doc: "Marks the radio group as having validation errors")
  attr(:required, :boolean, default: false, doc: "Marks the radio group as required")

  # Error handling
  attr(:error_message, :string, default: nil, doc: "Error message for invalid state")

  # Styling
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes like aria-label, aria-labelledby")

  # Slots for radio options
  slot :option, required: true, doc: "Radio option" do
    attr(:value, :any, required: true)
    attr(:disabled, :boolean)
    attr(:checked, :boolean, doc: "Override automatic checked state")
  end

  @doc """
  Renders a styled radio group component.

  This function wraps Stellar.Components.RadioGroup with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via CSS classes
  that respond to the radio group's card and layout state.

  ## Card vs Layout

  - **card**: Visual style - renders options as clickable cards
  - **layout**: Spatial arrangement - flex or grid layout
  - These can be combined independently

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
      <.radio_group field={@form[:theme]} card layout="grid" columns={3}>
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

    # Compute name, value, and id from field if not provided
    name = assigns[:name] || (assigns[:field] && assigns.field.name)
    current_value = assigns[:value] || (assigns[:field] && assigns.field.value)
    computed_id = assigns[:id] || (assigns[:field] && assigns.field.id)

    # Build class string for radio group container
    container_class =
      merge([
        base_container_classes(),
        layout_classes(assigns.layout, assigns.orientation),
        layout_grid_classes(assigns.layout, assigns.columns),
        card_size_classes(assigns.card, assigns.size),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)
      |> assign(:computed_name, name)
      |> assign(:computed_value, current_value)
      |> assign(:computed_id, computed_id)

    ~H"""
    <StellarRadioGroup.radio_group
      field={@field}
      id={@computed_id}
      name={@computed_name}
      value={@computed_value}
      orientation={@orientation}
      disabled={@disabled}
      invalid={@invalid}
      required={@required}
      error_message={@error_message}
      class={@container_class}
      data-card={@card && "true" || "false"}
      data-variant={@variant}
      data-color={@effective_color}
      data-size={@size}
      data-hide-radios={@hide_radios && "true" || "false"}
      {@rest}
      :let={group}
    >
      <%= for option <- @option do %>
        <%= render_radio_option(assigns, option, group) %>
      <% end %>
    </StellarRadioGroup.radio_group>
    """
  end

  # Render individual radio option with group context from Stellar
  defp render_radio_option(assigns, option, group) do
    # Generate unique ID for this radio option
    radio_id = "#{group.id}-#{:erlang.phash2(option.value)}"

    # Determine checked state
    checked =
      Map.get(option, :checked, false) || to_string(group.value) == to_string(option.value)

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
    ~H"""
    <div class={radio_option_base_classes()}>
      <input
        type="radio"
        id={@radio_id}
        name={@group.name}
        value={@option.value}
        checked={@option_checked}
        required={@group.required}
        disabled={@option_disabled}
        aria-invalid={@group.invalid && "true"}
        class={merge([radio_input_base_classes(), if(@hide_radios, do: "sr-only", else: nil)])}
      />
      <label for={@radio_id} class={radio_label_classes()}>
        <%= render_slot(@option) %>
      </label>
    </div>
    """
  end

  # Card-style radio (matching checkbox card pattern)
  defp render_card_radio(assigns) do
    container_class =
      merge([
        card_base_classes(),
        card_variant_classes(assigns.variant, assigns.effective_color),
        card_size_text_classes(assigns.size),
        card_state_classes(assigns.option_disabled, assigns.invalid)
      ])

    radio_class = if assigns.hide_radios, do: "sr-only", else: radio_input_base_classes()

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:radio_class, radio_class)

    ~H"""
    <label 
      for={@radio_id}
      class={@container_class}
      data-checked={@option_checked && "true" || "false"}
      data-disabled={@option_disabled && "true" || "false"}
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
        aria-describedby={"#{@radio_id}-content"}
        class={@radio_class}
      />
      <div class="flex-1 min-w-0" id={"#{@radio_id}-content"}>
        <%= render_slot(@option) %>
      </div>
    </label>
    """
  end

  # Base styles for radio group container with CSS variables
  @spec base_container_classes() :: String.t()
  defp base_container_classes do
    """
    [--radio-color:theme(colors.primary)] [--radio-color-foreground:theme(colors.primary-foreground)]
    [--radio-border:theme(colors.border)] [--radio-background:theme(colors.background)]
    dark:[--radio-color:theme(colors.dark-primary)] dark:[--radio-color-foreground:theme(colors.dark-primary-foreground)]
    dark:[--radio-border:theme(colors.dark-border)] dark:[--radio-background:theme(colors.dark-background)]
    data-[color=neutral]:[--radio-color:theme(colors.neutral)] data-[color=neutral]:[--radio-color-foreground:theme(colors.neutral-foreground)]
    data-[color=secondary]:[--radio-color:theme(colors.secondary)] data-[color=secondary]:[--radio-color-foreground:theme(colors.secondary-foreground)]
    data-[color=success]:[--radio-color:theme(colors.success)] data-[color=success]:[--radio-color-foreground:theme(colors.success-foreground)]
    data-[color=danger]:[--radio-color:theme(colors.danger)] data-[color=danger]:[--radio-color-foreground:theme(colors.danger-foreground)]
    data-[color=warning]:[--radio-color:theme(colors.warning)] data-[color=warning]:[--radio-color-foreground:theme(colors.warning-foreground)]
    data-[color=info]:[--radio-color:theme(colors.info)] data-[color=info]:[--radio-color-foreground:theme(colors.info-foreground)]
    dark:data-[color=neutral]:[--radio-color:theme(colors.dark-neutral)] dark:data-[color=neutral]:[--radio-color-foreground:theme(colors.dark-neutral-foreground)]
    dark:data-[color=secondary]:[--radio-color:theme(colors.dark-secondary)] dark:data-[color=secondary]:[--radio-color-foreground:theme(colors.dark-secondary-foreground)]
    dark:data-[color=success]:[--radio-color:theme(colors.dark-success)] dark:data-[color=success]:[--radio-color-foreground:theme(colors.dark-success-foreground)]
    dark:data-[color=danger]:[--radio-color:theme(colors.dark-danger)] dark:data-[color=danger]:[--radio-color-foreground:theme(colors.dark-danger-foreground)]
    dark:data-[color=warning]:[--radio-color:theme(colors.dark-warning)] dark:data-[color=warning]:[--radio-color-foreground:theme(colors.dark-warning-foreground)]
    dark:data-[color=info]:[--radio-color:theme(colors.dark-info)] dark:data-[color=info]:[--radio-color-foreground:theme(colors.dark-info-foreground)]
    """
  end

  # Layout-specific classes (independent of card)
  @spec layout_classes(String.t(), String.t()) :: String.t()
  defp layout_classes("flex", "horizontal"), do: "flex flex-row flex-wrap gap-6"
  defp layout_classes("flex", "vertical"), do: "flex flex-col gap-4"
  defp layout_classes("grid", _orientation), do: "grid gap-4"

  # Grid-specific column classes
  @spec layout_grid_classes(String.t(), integer()) :: String.t()
  defp layout_grid_classes("grid", 1), do: "grid-cols-1"
  defp layout_grid_classes("grid", 2), do: "grid-cols-1 sm:grid-cols-2"
  defp layout_grid_classes("grid", 3), do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
  defp layout_grid_classes("grid", 4), do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"

  defp layout_grid_classes("grid", 5),
    do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5"

  defp layout_grid_classes("grid", 6),
    do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"

  defp layout_grid_classes("grid", columns) when columns > 6,
    do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"

  defp layout_grid_classes(_layout, _columns), do: ""

  # Size classes for cards (only applied when card=true)
  @spec card_size_classes(boolean(), String.t()) :: String.t()
  defp card_size_classes(false, _size), do: ""

  defp card_size_classes(true, "xs"),
    do:
      "[--radio-card-padding:theme(spacing.2)] [--radio-card-gap:theme(spacing.2)] [--radio-card-text:theme(fontSize.xs)]"

  defp card_size_classes(true, "sm"),
    do:
      "[--radio-card-padding:theme(spacing.3)] [--radio-card-gap:theme(spacing.2)] [--radio-card-text:theme(fontSize.sm)]"

  defp card_size_classes(true, "md"),
    do:
      "[--radio-card-padding:theme(spacing.4)] [--radio-card-gap:theme(spacing.3)] [--radio-card-text:theme(fontSize.base)]"

  defp card_size_classes(true, "lg"),
    do:
      "[--radio-card-padding:theme(spacing.5)] [--radio-card-gap:theme(spacing.4)] [--radio-card-text:theme(fontSize.lg)]"

  defp card_size_classes(true, "xl"),
    do:
      "[--radio-card-padding:theme(spacing.6)] [--radio-card-gap:theme(spacing.5)] [--radio-card-text:theme(fontSize.xl)]"

  # Base classes for radio option container
  @spec radio_option_base_classes() :: String.t()
  defp radio_option_base_classes do
    """
    relative flex items-start gap-3
    """
  end

  # Base classes for radio input
  @spec radio_input_base_classes() :: String.t()
  defp radio_input_base_classes do
    """
    appearance-none relative cursor-pointer transition-all duration-200 ease-in-out
    w-5 h-5 rounded-full border-2 border-[--radio-border]
    bg-[--radio-background] 
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[--radio-color]
    disabled:cursor-not-allowed disabled:opacity-50
    checked:border-[--radio-color] checked:bg-[--radio-color]
    before:content-[''] before:absolute before:inset-1 before:rounded-full 
    before:bg-[--radio-color-foreground] before:transition-all before:duration-200 
    before:scale-0 before:opacity-0
    checked:before:scale-100 checked:before:opacity-100
    [[data-radio-group][data-size=xs]_&]:w-3 [[data-radio-group][data-size=xs]_&]:h-3 [[data-radio-group][data-size=xs]_&]:before:inset-0.5
    [[data-radio-group][data-size=sm]_&]:w-4 [[data-radio-group][data-size=sm]_&]:h-4 [[data-radio-group][data-size=sm]_&]:before:inset-0.5
    [[data-radio-group][data-size=lg]_&]:w-6 [[data-radio-group][data-size=lg]_&]:h-6 [[data-radio-group][data-size=lg]_&]:before:inset-1.5
    [[data-radio-group][data-size=xl]_&]:w-7 [[data-radio-group][data-size=xl]_&]:h-7 [[data-radio-group][data-size=xl]_&]:before:inset-1.5
    hover:border-[--radio-color]/70 hover:shadow-sm
    """
  end

  # Classes for radio labels (standard non-card)
  @spec radio_label_classes() :: String.t()
  defp radio_label_classes do
    """
    cursor-pointer select-none transition-all duration-200 flex-1 min-w-0
    focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-[--radio-color]
    """
  end

  # Card base styles (matching checkbox pattern)
  @spec card_base_classes() :: String.t()
  defp card_base_classes do
    """
    relative flex items-start gap-3 p-[--radio-card-padding] rounded-lg border-2 
    cursor-pointer transition-all duration-200 ease-in-out text-[--radio-card-text]
    focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-[--radio-color]
    """
  end

  # Card variant styles
  @spec card_variant_classes(String.t(), String.t()) :: String.t()
  defp card_variant_classes("solid", _color) do
    """
    border-transparent bg-[--radio-background]
    hover:bg-[--radio-color]/10
    data-[checked=true]:bg-[--radio-color]/20
    """
  end

  defp card_variant_classes("outline", _color) do
    """
    border-[--radio-border] bg-[--radio-background]
    hover:border-[--radio-color]/50 hover:bg-[--radio-color]/5
    data-[checked=true]:border-[--radio-color] data-[checked=true]:bg-[--radio-color]/10
    """
  end

  defp card_variant_classes("ghost", _color) do
    """
    border-transparent bg-transparent
    hover:bg-[--radio-color]/10
    data-[checked=true]:bg-[--radio-color]/15
    """
  end

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
    classes = []
    classes = if disabled, do: ["opacity-50 cursor-not-allowed" | classes], else: classes
    classes = if invalid, do: ["border-danger ring-danger" | classes], else: classes
    Enum.join(classes, " ")
  end

  # Helper for error detection - checks if a Phoenix form field has validation errors
  @spec has_field_errors(map()) :: boolean()
  defp has_field_errors(%{field: %FormField{errors: errors}}) when is_list(errors) do
    not Enum.empty?(errors)
  end

  defp has_field_errors(_assigns), do: false
end
