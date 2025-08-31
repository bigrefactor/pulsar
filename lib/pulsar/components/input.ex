defmodule Pulsar.Components.Input do
  @moduledoc """
  Styled input component built on Stellar.Components.Input with decorator support.

  Provides beautiful, accessible input fields with optional start and end decorators 
  for icons, text, or interactive elements. All styling is applied via Tailwind CSS 
  utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible input component
  - **Decorator System**: Start/end decorators for icons, text, or interactive elements
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button component sizes
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar input props are supported

  ## Examples

      # Basic input
      <.input field={@form[:email]} />

      # With decorators and color
      <.input field={@form[:amount]} variant="outline" color="success">
        <:start_decorator>$</:start_decorator>
        <:end_decorator>USD</:end_decorator>
      </.input>

      # URL input with protocol decorator
      <.input field={@form[:website]} type="url" color="primary">
        <:start_decorator>https://</:start_decorator>
      </.input>

      # Search input with solid variant
      <.input field={@form[:search]} variant="solid" color="secondary">
        <:start_decorator>
          <.icon name="hero-magnifying-glass" />
        </:start_decorator>
        <:end_decorator>
          <.button variant="ghost" size="sm">Search</.button>
        </:end_decorator>
      </.input>

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback across all inputs.

  ## Stellar Integration

  This component wraps Stellar.Components.Input and passes through all its props:
  - All HTML5 input types (text, email, password, number, etc.)
  - Phoenix form integration with automatic error detection
  - Accessibility features and ARIA attributes
  - Validation error handling with `aria-describedby` 
  - Mobile keyboard optimization
  - All standard HTML attributes

  ## Decorator Slots

  - `:start_decorator` - Leading decorator (icons, text, buttons)
  - `:end_decorator` - Trailing decorator (icons, text, buttons)

  Decorators are visually integrated with the input field, sharing borders
  and backgrounds based on the selected variant.
  """

  use Phoenix.Component
  alias Stellar.Components.Input, as: StellarInput

  import TailwindMerge, only: [merge: 1]

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "outline",
    values: ~w(outline ghost solid),
    doc: "Visual style variant of the input"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the input (overridden by error state)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the input"

  # Stellar input attributes - copied from Stellar.Components.Input
  attr :type, :string,
    values:
      ~w(text email password number tel url search date time datetime-local month week color range file hidden),
    default: "text",
    doc: "Input type"

  attr :field, Phoenix.HTML.FormField, default: nil, doc: "Phoenix form field"

  # Core attributes
  attr :id, :string,
    default: nil,
    doc: "Input ID (auto-generated if not provided)"

  attr :name, :string,
    default: nil,
    doc: "Input name (from field if not provided)"

  attr :value, :any,
    default: nil,
    doc: "Input value (from field if not provided)"

  # State attributes
  attr :required, :boolean,
    default: false,
    doc: "Mark input as required"

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the input"

  attr :readonly, :boolean,
    default: false,
    doc: "Make input read-only"

  # Styling
  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  # Global attributes (allows all Phoenix and HTML attributes)
  attr :rest, :global, doc: "Additional HTML attributes including placeholder"

  # Decorator slots
  slot :start_decorator,
    doc: "Leading decorator content (icons, text, buttons)"

  slot :end_decorator,
    doc: "Trailing decorator content (icons, text, buttons)"

  @doc """
  Renders a styled input component with optional decorators.

  This function wraps Stellar.Components.Input with Pulsar's styling system
  and adds support for start/end decorators. All Stellar props are passed 
  through, with styling automatically determined by variant and error state.

  Error states automatically apply danger styling when using Phoenix forms.
  """
  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <StellarInput.input
      type="hidden"
      field={@field}
      id={@id}
      name={@name}
      value={@value}
      required={@required}
      disabled={@disabled}
      readonly={@readonly}
      class={@class}
      {@rest}
    />
    """
  end

  def input(assigns) do
    # Detect errors and compute automatic color
    has_errors =
      case assigns[:field] do
        %Phoenix.HTML.FormField{errors: errs} when errs != [] -> true
        _ -> false
      end

    effective_color = if has_errors, do: "danger", else: assigns.color

    class = merge([
      get_classes(assigns.variant, effective_color, assigns.size),
      get_state_classes(assigns.disabled, assigns.readonly),
      assigns.class
    ])

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:has_start_decorator, assigns.start_decorator != [])
      |> assign(:has_end_decorator, assigns.end_decorator != [])
      |> assign(:decorator_variant, assigns.variant)
      |> assign(:decorator_color, effective_color)
      |> assign(:invalid, has_errors)
      |> assign(:required_attr, assigns.required)

    ~H"""
    <div
      class={@class}
      data-variant={@variant}
      data-size={@size}
      data-color={@decorator_color}
      data-has-start-decorator={@has_start_decorator}
      data-has-end-decorator={@has_end_decorator}
      data-invalid={@invalid}
      data-required={@required_attr}
    >
      <.start_decorator :if={@start_decorator != []} decorator_variant={@decorator_variant} decorator_color={@decorator_color} decorator_size={@size}>
        {render_slot(@start_decorator)}
      </.start_decorator>

      <StellarInput.input
        class={
          [
            "w-full outline-0 transition-all duration-200 ease-in-out",
            "group-data-[size=xs]:px-2 group-data-[size=xs]:py-1",
            "group-data-[size=sm]:px-2 group-data-[size=sm]:py-1",
            "group-data-[size=md]:px-3 group-data-[size=md]:py-1.5",
            "group-data-[size=lg]:px-4 group-data-[size=lg]:py-2",
            "group-data-[size=xl]:px-4 group-data-[size=xl]:py-2",
            "group-data-[variant=ghost]:group-data-[has-start-decorator=true]:pl-0",
            "group-data-[variant=ghost]:group-data-[has-end-decorator=true]:pr-0",
            (@disabled && "cursor-not-allowed") || (@readonly && "cursor-default") || nil
          ]
          |> Enum.filter(&(&1))
        }
        type={@type}
        field={@field}
        id={@id}
        name={@name}
        value={@value}
        required={@required}
        disabled={@disabled}
        readonly={@readonly}
        {@rest}
      />

      <.end_decorator :if={@end_decorator != []} decorator_variant={@decorator_variant} decorator_color={@decorator_color} decorator_size={@size}>
        {render_slot(@end_decorator)}
      </.end_decorator>
    </div>
    """
  end

  attr :class, :any, default: ""
  attr :decorator_variant, :string, required: true
  attr :decorator_color, :string, required: true
  attr :decorator_size, :string, required: true
  slot :inner_block, required: true, doc: "Content to render inside the decorator"

  defp start_decorator(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)
    class = merge([
      get_decorator_classes("start", assigns.decorator_variant, assigns.decorator_color, assigns.decorator_size),
      assigns.class
    ])
    assigns = assign(assigns, :class, class)

    ~H"""
    <div class={@class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp end_decorator(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)
    class = merge([
      get_decorator_classes("end", assigns.decorator_variant, assigns.decorator_color, assigns.decorator_size),
      assigns.class
    ])
    assigns = assign(assigns, :class, class)

    ~H"""
    <div class={@class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Modular styling system supporting all variants and colors
  defp get_classes(variant, color, size) do
    merge([
      base_input_classes(),
      variant_classes(variant),
      color_classes(variant, color),
      get_size_classes(size)
    ])
  end

  # Base styles shared by all input variants
  defp base_input_classes do
    "flex group overflow-hidden transition-all duration-200 ease-in-out focus-within:ring-2 focus-within:ring-offset-2"
  end

  # Variant-specific layout and structure
  defp variant_classes("outline"), do: "border-2 rounded-lg"
  defp variant_classes("ghost"), do: "rounded-lg"
  defp variant_classes("solid"), do: "rounded-lg"

  # Color classes by variant
  defp color_classes("outline", "neutral"), do: "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:border-primary-300 dark:hover:border-primary-600"
  defp color_classes("outline", "primary"), do: "border-primary-400 dark:border-primary-800 bg-background dark:bg-dark-background text-primary-700 dark:text-primary-300 placeholder:text-primary-700 dark:placeholder:text-primary-300 focus-within:ring-primary-500/60 hover:border-primary-500 dark:hover:border-primary-700"
  defp color_classes("outline", "secondary"), do: "border-secondary-400 dark:border-secondary-800 bg-background dark:bg-dark-background text-secondary-700 dark:text-secondary-300 placeholder:text-secondary-700 dark:placeholder:text-secondary-300 focus-within:ring-secondary-500/60 hover:border-secondary-500 dark:hover:border-secondary-700"
  defp color_classes("outline", "success"), do: "border-success-400 dark:border-success-800 bg-background dark:bg-dark-background text-success-700 dark:text-success-300 placeholder:text-success-700 dark:placeholder:text-success-300 focus-within:ring-success-500/60 hover:border-success-500 dark:hover:border-success-700"
  defp color_classes("outline", "danger"), do: "border-danger-400 dark:border-danger-800 bg-background dark:bg-dark-background text-danger-700 dark:text-danger-300 placeholder:text-danger-700 dark:placeholder:text-danger-300 focus-within:ring-danger-500/60 hover:border-danger-500 dark:hover:border-danger-700"
  defp color_classes("outline", "warning"), do: "border-warning-400 dark:border-warning-800 bg-background dark:bg-dark-background text-warning-700 dark:text-warning-300 placeholder:text-warning-700 dark:placeholder:text-warning-300 focus-within:ring-warning-500/60 hover:border-warning-500 dark:hover:border-warning-700"
  defp color_classes("outline", "info"), do: "border-info-400 dark:border-info-800 bg-background dark:bg-dark-background text-info-700 dark:text-info-300 placeholder:text-info-700 dark:placeholder:text-info-300 focus-within:ring-info-500/60 hover:border-info-500 dark:hover:border-info-700"

  defp color_classes("ghost", "neutral"), do: "bg-transparent text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary"
  defp color_classes("ghost", "primary"), do: "bg-transparent text-primary-700 dark:text-primary-300 placeholder:text-primary-700 dark:placeholder:text-primary-300 focus-within:ring-primary-500/60 hover:bg-primary-50 dark:hover:bg-primary-900/20"
  defp color_classes("ghost", "secondary"), do: "bg-transparent text-secondary-700 dark:text-secondary-300 placeholder:text-secondary-700 dark:placeholder:text-secondary-300 focus-within:ring-secondary-500/60 hover:bg-secondary-50 dark:hover:bg-secondary-900/20"
  defp color_classes("ghost", "success"), do: "bg-transparent text-success-700 dark:text-success-300 placeholder:text-success-700 dark:placeholder:text-success-300 focus-within:ring-success-500/60 hover:bg-success-50 dark:hover:bg-success-900/20"
  defp color_classes("ghost", "danger"), do: "bg-transparent text-danger-700 dark:text-danger-300 placeholder:text-danger-700 dark:placeholder:text-danger-300 focus-within:ring-danger-500/60 hover:bg-danger-50 dark:hover:bg-danger-900/20"
  defp color_classes("ghost", "warning"), do: "bg-transparent text-warning-700 dark:text-warning-300 placeholder:text-warning-700 dark:placeholder:text-warning-300 focus-within:ring-warning-500/60 hover:bg-warning-50 dark:hover:bg-warning-900/20"
  defp color_classes("ghost", "info"), do: "bg-transparent text-info-700 dark:text-info-300 placeholder:text-info-700 dark:placeholder:text-info-300 focus-within:ring-info-500/60 hover:bg-info-50 dark:hover:bg-info-900/20"

  defp color_classes("solid", "neutral"), do: "bg-neutral-100 dark:bg-neutral-800 text-neutral-900 dark:text-neutral-100 placeholder:text-neutral-900 dark:placeholder:text-neutral-100 focus-within:ring-neutral-500/60 hover:bg-neutral-200 dark:hover:bg-neutral-700"
  defp color_classes("solid", "primary"), do: "bg-primary-100 dark:bg-primary-800 text-primary-900 dark:text-primary-100 placeholder:text-primary-900 dark:placeholder:text-primary-100 focus-within:ring-primary-500/60 hover:bg-primary-200 dark:hover:bg-primary-700"
  defp color_classes("solid", "secondary"), do: "bg-secondary-100 dark:bg-secondary-800 text-secondary-900 dark:text-secondary-100 placeholder:text-secondary-900 dark:placeholder:text-secondary-100 focus-within:ring-secondary-500/60 hover:bg-secondary-200 dark:hover:bg-secondary-700"
  defp color_classes("solid", "success"), do: "bg-success-100 dark:bg-success-800 text-success-900 dark:text-success-100 placeholder:text-success-900 dark:placeholder:text-success-100 focus-within:ring-success-500/60 hover:bg-success-200 dark:hover:bg-success-700"
  defp color_classes("solid", "danger"), do: "bg-danger-100 dark:bg-danger-800 text-danger-900 dark:text-danger-100 placeholder:text-danger-900 dark:placeholder:text-danger-100 focus-within:ring-danger-500/60"
  defp color_classes("solid", "warning"), do: "bg-warning-100 dark:bg-warning-800 text-warning-900 dark:text-warning-100 placeholder:text-warning-900 dark:placeholder:text-warning-100 focus-within:ring-warning-500/60 hover:bg-warning-200 dark:hover:bg-warning-700"
  defp color_classes("solid", "info"), do: "bg-info-100 dark:bg-info-800 text-info-900 dark:text-info-100 placeholder:text-info-900 dark:placeholder:text-info-100 focus-within:ring-info-500/60 hover:bg-info-200 dark:hover:bg-info-700"

  # Helper functions for reusable parts
  defp get_size_classes("xs"), do: "min-h-6 text-xs"
  defp get_size_classes("sm"), do: "min-h-8 text-sm"
  defp get_size_classes("md"), do: "min-h-10"
  defp get_size_classes("lg"), do: "min-h-12 text-lg"
  defp get_size_classes("xl"), do: "min-h-14 text-xl"

  defp get_decorator_padding("xs"), do: "px-2 py-1"
  defp get_decorator_padding("sm"), do: "px-2 py-1"
  defp get_decorator_padding("md"), do: "px-3 py-1.5"
  defp get_decorator_padding("lg"), do: "px-4 py-2"
  defp get_decorator_padding("xl"), do: "px-4 py-2"

  defp get_decorator_font_size("xs"), do: "text-xs"
  defp get_decorator_font_size("sm"), do: "text-sm"
  defp get_decorator_font_size("md"), do: ""
  defp get_decorator_font_size("lg"), do: "text-lg"
  defp get_decorator_font_size("xl"), do: "text-xl"

  defp get_state_classes(disabled, readonly) do
    [
      disabled && "cursor-not-allowed opacity-50 pointer-events-none",
      readonly && "cursor-default"
    ]
    |> Enum.filter(&(&1))
    |> Enum.join(" ")
  end

  # Decorator functions supporting all variants and colors
  defp get_decorator_classes(position, variant, color, size) do
    merge([
      base_decorator_classes(size),
      decorator_position_classes(position, variant),
      decorator_color_classes(variant, color)
    ])
  end

  defp base_decorator_classes(size) do
    "#{get_decorator_padding(size)} flex items-center justify-center #{get_decorator_font_size(size)}"
  end

  defp decorator_position_classes("start", "outline"), do: "border-r"
  defp decorator_position_classes("end", "outline"), do: "border-l"
  defp decorator_position_classes("start", "solid"), do: "border-r"
  defp decorator_position_classes("end", "solid"), do: "border-l"
  defp decorator_position_classes(_, "ghost"), do: ""

  defp decorator_color_classes("outline", "neutral"), do: "bg-border dark:bg-dark-border text-neutral-700 dark:text-neutral-300 border-border dark:border-dark-border"
  defp decorator_color_classes("outline", "primary"), do: "bg-primary-400 dark:bg-primary-800 text-primary-900 dark:text-primary-300 border-primary-400 dark:border-primary-800"
  defp decorator_color_classes("outline", "secondary"), do: "bg-secondary-400 dark:bg-secondary-800 text-secondary-900 dark:text-secondary-300 border-secondary-400 dark:border-secondary-800"
  defp decorator_color_classes("outline", "success"), do: "bg-success-400 dark:bg-success-800 text-success-900 dark:text-success-300 border-success-400 dark:border-success-800"
  defp decorator_color_classes("outline", "danger"), do: "bg-danger-400 dark:bg-danger-800 text-danger-900 dark:text-danger-300 border-danger-400 dark:border-danger-800"
  defp decorator_color_classes("outline", "warning"), do: "bg-warning-400 dark:bg-warning-800 text-warning-900 dark:text-warning-300 border-warning-400 dark:border-warning-800"
  defp decorator_color_classes("outline", "info"), do: "bg-info-400 dark:bg-info-800 text-info-900 dark:text-info-300 border-info-400 dark:border-info-800"

  defp decorator_color_classes("solid", "neutral"), do: "bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 border-neutral-200 dark:border-neutral-700"
  defp decorator_color_classes("solid", "primary"), do: "bg-primary-100 dark:bg-primary-800 text-primary-700 dark:text-primary-300 border-primary-200 dark:border-primary-700"
  defp decorator_color_classes("solid", "secondary"), do: "bg-secondary-100 dark:bg-secondary-800 text-secondary-700 dark:text-secondary-300 border-secondary-200 dark:border-secondary-700"
  defp decorator_color_classes("solid", "success"), do: "bg-success-100 dark:bg-success-800 text-success-700 dark:text-success-300 border-success-200 dark:border-success-700"
  defp decorator_color_classes("solid", "danger"), do: "bg-danger-100 dark:bg-danger-800 text-danger-700 dark:text-danger-300 border-danger-200 dark:border-danger-700"
  defp decorator_color_classes("solid", "warning"), do: "bg-warning-100 dark:bg-warning-800 text-warning-700 dark:text-warning-300 border-warning-200 dark:border-warning-700"
  defp decorator_color_classes("solid", "info"), do: "bg-info-100 dark:bg-info-800 text-info-700 dark:text-info-300 border-info-200 dark:border-info-700"

  defp decorator_color_classes("ghost", _color), do: "text-muted dark:text-dark-muted"
end