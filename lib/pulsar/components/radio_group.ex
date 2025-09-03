defmodule Pulsar.Components.RadioGroup do
  @moduledoc """
  Styled radio group component built on Stellar.Components.RadioGroup.

  Provides beautiful, accessible radio button groups with custom design and card-style
  layouts. All styling is applied via Tailwind CSS utilities with semantic color tokens
  that support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible radio group component with roving tabindex
  - **Custom Radio Design**: Styled radio buttons with smooth animations
  - **Card-style Layout**: Rich card layouts with descriptions and custom content
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
        <.radio_option value="basic">Basic Plan</.radio_option>
        <.radio_option value="pro">Pro Plan</.radio_option>
        <.radio_option value="enterprise">Enterprise Plan</.radio_option>
      </.radio_group>

      # With size and color variants
      <.radio_group field={@form[:size]} color="primary" size="lg" orientation="horizontal">
        <.radio_option value="sm">Small</.radio_option>
        <.radio_option value="md">Medium</.radio_option>
        <.radio_option value="lg">Large</.radio_option>
      </.radio_group>

      # Card-style layout with descriptions
      <.radio_group field={@form[:plan]} layout="cards" variant="outline" color="primary">
        <.radio_option value="basic">
          <div class="font-medium">Basic Plan</div>
          <div class="text-sm text-muted-foreground mt-1">Perfect for individuals</div>
          <div class="text-sm font-semibold mt-2">$10/month</div>
        </.radio_option>
        <.radio_option value="pro">
          <div class="font-medium">Pro Plan</div>
          <div class="text-sm text-muted-foreground mt-1">Great for teams</div>
          <div class="text-sm font-semibold mt-2">$25/month</div>
        </.radio_option>
      </.radio_group>

      # Grid layout for multiple options
      <.radio_group field={@form[:theme]} layout="grid" columns={3}>
        <.radio_option value="light">Light</.radio_option>
        <.radio_option value="dark">Dark</.radio_option>
        <.radio_option value="auto">Auto</.radio_option>
        <.radio_option value="blue">Blue</.radio_option>
        <.radio_option value="green">Green</.radio_option>
        <.radio_option value="purple">Purple</.radio_option>
      </.radio_group>

      # Card-only selection (hidden radio inputs)
      <.radio_group field={@form[:plan]} layout="cards" hide_radios variant="outline">
        <.radio_option value="starter">
          <div class="text-center">
            <div class="text-2xl mb-2">🚀</div>
            <div class="font-medium">Starter</div>
            <div class="text-sm text-muted-foreground">Get started quickly</div>
          </div>
        </.radio_option>
        <.radio_option value="professional">
          <div class="text-center">
            <div class="text-2xl mb-2">💼</div>
            <div class="font-medium">Professional</div>
            <div class="text-sm text-muted-foreground">For growing teams</div>
          </div>
        </.radio_option>
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

  # Pulsar-specific styling attributes
  attr(:layout, :string,
    default: "default",
    values: ~w(default cards grid flex),
    doc: "Layout style for the radio group"
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant (applies to cards layout)"
  )

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

  attr(:columns, :integer,
    default: 2,
    doc: "Number of columns for grid layout"
  )

  attr(:hide_radios, :boolean,
    default: false,
    doc: "Hide the radio inputs (useful for card-only selection)"
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

  # Error handling
  attr(:error_message, :string, default: nil, doc: "Error message for invalid state")

  # Styling
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes like aria-label, aria-labelledby")

  # Slots for content
  slot(:inner_block, required: true, doc: "Radio options go here")

  @doc """
  Renders a styled radio group component.

  This function wraps Stellar.Components.RadioGroup with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via CSS classes
  that respond to the radio group's layout and state.

  ## Layout Options

  - **default**: Standard radio buttons with labels
  - **cards**: Rich card layouts with custom content slots
  - **grid**: Grid layout for multiple options
  - **flex**: Flexible layout with custom spacing

  ## Examples

      # Standard radio group
      <.radio_group field={@form[:plan]} color="primary" size="lg">
        <.radio_option value="basic">Basic Plan</.radio_option>
        <.radio_option value="pro">Pro Plan</.radio_option>
      </.radio_group>

      # Card layout with descriptions
      <.radio_group field={@form[:plan]} layout="cards" variant="outline">
        <.radio_option value="basic">
          <div class="font-medium">Basic Plan</div>
          <div class="text-sm text-muted-foreground">Perfect for individuals</div>
        </.radio_option>
      </.radio_group>
  """
  @spec radio_group(map()) :: Rendered.t()
  def radio_group(assigns) do
    # Detect errors and compute automatic color
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Build class string for radio group container
    container_class =
      merge([
        base_container_classes(),
        layout_classes(assigns.layout, assigns.orientation),
        layout_grid_classes(assigns.layout, assigns.columns),
        layout_size_classes(assigns.layout, assigns.size),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)

    ~H"""
    <StellarRadioGroup.radio_group
      field={@field}
      id={@id}
      name={@name}
      value={@value}
      orientation={@orientation}
      disabled={@disabled}
      invalid={@invalid}
      required={@required}
      error_message={@error_message}
      class={@container_class}
      data-layout={@layout}
      data-variant={@variant}
      data-color={@effective_color}
      data-size={@size}
      data-columns={@columns}
      data-hide-radios={if @hide_radios, do: "true", else: "false"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </StellarRadioGroup.radio_group>
    """
  end

  @doc """
  Renders a styled radio option within a radio group.

  This component should be used as a child of `radio_group/1` to create
  individual radio options with consistent styling.
  """
  attr(:value, :any, required: true, doc: "Value for this radio option")
  attr(:disabled, :boolean, default: false, doc: "Disable this specific option")
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  # Global attributes
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Content for the radio option")

  def radio_option(assigns) do
    # Generate unique ID for this radio option
    radio_id = "radio-#{:erlang.phash2(assigns.value)}"

    assigns = assign(assigns, :radio_id, radio_id)

    ~H"""
    <div class={
      merge([
        radio_option_base_classes(),
        @class
      ])
    }>
      <input
        type="radio"
        id={@radio_id}
        value={@value}
        disabled={@disabled}
        class={
          merge([
            radio_input_base_classes()
          ])
        }
        {@rest}
      />
      <label for={@radio_id} class={radio_label_classes()}>
        {render_slot(@inner_block)}
      </label>
    </div>
    """
  end

  # Base styles for radio group container
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

  # Layout-specific classes
  @spec layout_classes(String.t(), String.t()) :: String.t()
  defp layout_classes("default", "horizontal"), do: "flex flex-row gap-6"
  defp layout_classes("default", "vertical"), do: "flex flex-col gap-4"
  defp layout_classes("cards", "horizontal"), do: "flex flex-row gap-4"
  defp layout_classes("cards", "vertical"), do: "flex flex-col gap-4"
  defp layout_classes("flex", "horizontal"), do: "flex flex-row flex-wrap gap-4"
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

  # Size classes based on layout
  @spec layout_size_classes(String.t(), String.t()) :: String.t()
  defp layout_size_classes("cards", "xs"),
    do:
      "[--radio-card-padding:theme(spacing.2)] [--radio-card-gap:theme(spacing.2)] [--radio-card-text:theme(fontSize.xs)]"

  defp layout_size_classes("cards", "sm"),
    do:
      "[--radio-card-padding:theme(spacing.3)] [--radio-card-gap:theme(spacing.2)] [--radio-card-text:theme(fontSize.sm)]"

  defp layout_size_classes("cards", "md"),
    do:
      "[--radio-card-padding:theme(spacing.4)] [--radio-card-gap:theme(spacing.3)] [--radio-card-text:theme(fontSize.base)]"

  defp layout_size_classes("cards", "lg"),
    do:
      "[--radio-card-padding:theme(spacing.5)] [--radio-card-gap:theme(spacing.4)] [--radio-card-text:theme(fontSize.lg)]"

  defp layout_size_classes("cards", "xl"),
    do:
      "[--radio-card-padding:theme(spacing.6)] [--radio-card-gap:theme(spacing.5)] [--radio-card-text:theme(fontSize.xl)]"

  defp layout_size_classes(_layout, _size), do: ""

  # Base classes for radio option container
  @spec radio_option_base_classes() :: String.t()
  defp radio_option_base_classes do
    """
    relative
    [&:has([data-layout=cards])]:block
    [&:has([data-hide-radios=true])_.radio-input]:sr-only
    """
  end

  # Base classes for radio input
  @spec radio_input_base_classes() :: String.t()
  defp radio_input_base_classes do
    """
    radio-input appearance-none relative cursor-pointer transition-all duration-200 ease-in-out
    w-5 h-5 rounded-full border-2 border-[--radio-border]
    bg-[--radio-background] 
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[--radio-color]
    disabled:cursor-not-allowed disabled:opacity-50
    checked:border-[--radio-color] checked:bg-[--radio-color]
    before:content-[''] before:absolute before:inset-1 before:rounded-full 
    before:bg-[--radio-color-foreground] before:transition-all before:duration-200 
    before:scale-0 before:opacity-0
    checked:before:scale-100 checked:before:opacity-100
    [.radio-group[data-size=xs]_&]:w-3 [.radio-group[data-size=xs]_&]:h-3 [.radio-group[data-size=xs]_&]:before:inset-0.5
    [.radio-group[data-size=sm]_&]:w-4 [.radio-group[data-size=sm]_&]:h-4 [.radio-group[data-size=sm]_&]:before:inset-0.5
    [.radio-group[data-size=lg]_&]:w-6 [.radio-group[data-size=lg]_&]:h-6 [.radio-group[data-size=lg]_&]:before:inset-1.5
    [.radio-group[data-size=xl]_&]:w-7 [.radio-group[data-size=xl]_&]:h-7 [.radio-group[data-size=xl]_&]:before:inset-1.5
    hover:border-[--radio-color]/70 hover:shadow-sm
    """
  end

  # Classes for radio labels
  @spec radio_label_classes() :: String.t()
  defp radio_label_classes do
    """
    cursor-pointer select-none transition-all duration-200
    [.radio-group[data-layout=default]_&]:ml-3 [.radio-group[data-layout=default]_&]:flex [.radio-group[data-layout=default]_&]:items-center
    [.radio-group[data-layout=cards]_&]:block [.radio-group[data-layout=cards]_&]:p-[--radio-card-padding] 
    [.radio-group[data-layout=cards]_&]:rounded-lg [.radio-group[data-layout=cards]_&]:border-2 [.radio-group[data-layout=cards]_&]:transition-all 
    [.radio-group[data-layout=cards]_&]:cursor-pointer [.radio-group[data-layout=cards]_&]:text-[--radio-card-text]
    [.radio-group[data-layout=cards][data-variant=solid]_&]:border-transparent [.radio-group[data-layout=cards][data-variant=solid]_&]:bg-[--radio-background]
    [.radio-group[data-layout=cards][data-variant=solid]_&]:hover:bg-[--radio-color]/10
    [.radio-group[data-layout=cards][data-variant=solid]_&]:has-[:checked]:bg-[--radio-color]/20
    [.radio-group[data-layout=cards][data-variant=outline]_&]:border-[--radio-border] [.radio-group[data-layout=cards][data-variant=outline]_&]:bg-[--radio-background]
    [.radio-group[data-layout=cards][data-variant=outline]_&]:hover:border-[--radio-color]/50 [.radio-group[data-layout=cards][data-variant=outline]_&]:hover:bg-[--radio-color]/5
    [.radio-group[data-layout=cards][data-variant=outline]_&]:has-[:checked]:border-[--radio-color] [.radio-group[data-layout=cards][data-variant=outline]_&]:has-[:checked]:bg-[--radio-color]/10
    [.radio-group[data-layout=cards][data-variant=ghost]_&]:border-transparent [.radio-group[data-layout=cards][data-variant=ghost]_&]:bg-transparent
    [.radio-group[data-layout=cards][data-variant=ghost]_&]:hover:bg-[--radio-color]/10
    [.radio-group[data-layout=cards][data-variant=ghost]_&]:has-[:checked]:bg-[--radio-color]/15
    [.radio-group[data-layout=grid]_&]:block [.radio-group[data-layout=grid]_&]:p-3 [.radio-group[data-layout=grid]_&]:text-center
    [.radio-group[data-layout=grid]_&]:rounded-lg [.radio-group[data-layout=grid]_&]:border-2 [.radio-group[data-layout=grid]_&]:border-[--radio-border]
    [.radio-group[data-layout=grid]_&]:bg-[--radio-background] [.radio-group[data-layout=grid]_&]:transition-all [.radio-group[data-layout=grid]_&]:cursor-pointer
    [.radio-group[data-layout=grid]_&]:hover:border-[--radio-color]/50 [.radio-group[data-layout=grid]_&]:hover:bg-[--radio-color]/5
    [.radio-group[data-layout=grid]_&]:has-[:checked]:border-[--radio-color] [.radio-group[data-layout=grid]_&]:has-[:checked]:bg-[--radio-color]/10
    [.radio-group[data-layout=flex]_&]:block [.radio-group[data-layout=flex]_&]:px-4 [.radio-group[data-layout=flex]_&]:py-2
    [.radio-group[data-layout=flex]_&]:rounded-md [.radio-group[data-layout=flex]_&]:border [.radio-group[data-layout=flex]_&]:border-[--radio-border]
    [.radio-group[data-layout=flex]_&]:bg-[--radio-background] [.radio-group[data-layout=flex]_&]:transition-all [.radio-group[data-layout=flex]_&]:cursor-pointer
    [.radio-group[data-layout=flex]_&]:hover:border-[--radio-color]/50 [.radio-group[data-layout=flex]_&]:hover:bg-[--radio-color]/5
    [.radio-group[data-layout=flex]_&]:has-[:checked]:border-[--radio-color] [.radio-group[data-layout=flex]_&]:has-[:checked]:bg-[--radio-color]/10
    focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-[--radio-color]
    """
  end

  # Helper for error detection - checks if a Phoenix form field has validation errors
  @spec has_field_errors(map()) :: boolean()
  defp has_field_errors(%{field: %FormField{errors: errors}}) when is_list(errors) do
    not Enum.empty?(errors)
  end

  defp has_field_errors(_assigns), do: false
end
