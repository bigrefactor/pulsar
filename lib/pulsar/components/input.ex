defmodule Pulsar.Components.Input do
  @moduledoc """
  Styled input component built on Stellar.Components.Input with decorator support.

  Provides beautiful, accessible input fields with optional start and end decorators 
  for icons, text, or interactive elements. All styling is applied via Tailwind CSS 
  utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible input component
  - **Decorator System**: Start/end decorators for icons, text, or interactive elements
  - **Variants**: solid, outline, ghost with semantic styling matching button component
  - **Colors**: neutral, primary, secondary, success, danger, warning for consistent theming
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button component sizes
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar input props are supported

  ## Examples

      # Basic input
      <.input field={@form[:email]} />

      # With decorators
      <.input field={@form[:amount]} variant="outline" color="primary">
        <:start_decorator>$</:start_decorator>
        <:end_decorator>USD</:end_decorator>
      </.input>

      # URL input with protocol decorator
      <.input field={@form[:website]} type="url">
        <:start_decorator>https://</:start_decorator>
      </.input>

      # Search input with icon and button
      <.input field={@form[:search]} variant="ghost">
        <:start_decorator>
          <.icon name="hero-magnifying-glass" />
        </:start_decorator>
        <:end_decorator>
          <.button variant="ghost" size="sm">Search</.button>
        </:end_decorator>
      </.input>

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override the color prop
  to show danger (red) styling. This provides consistent error feedback across all inputs.
  If you need custom error styling, use the input without Phoenix form fields.

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
  and backgrounds based on the selected variant and color scheme.
  """

  use Phoenix.Component
  alias Stellar.Components.Input, as: StellarInput

  import TailwindMerge, only: [merge: 1]

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "outline",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the input"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the input (overridden by error state when using Phoenix forms)"

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
  through, with additional styling applied based on variant, size, and color.

  Error states automatically override the color prop when using Phoenix forms.
  """
  # Optimize hidden inputs: render Stellar input directly without container/decorators
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
    # Detect errors and compute effective color
    has_errors =
      case assigns[:field] do
        %Phoenix.HTML.FormField{errors: errs} when errs != [] -> true
        _ -> false
      end

    effective_color = if has_errors, do: "danger", else: assigns.color

    class = merge([
      get_classes(assigns.variant, effective_color, assigns.size),
      get_state_classes(assigns.disabled, assigns.readonly),
      get_required_classes(),
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
        class={[
          "w-full outline-0 transition-all duration-200 ease-in-out",
          "group-data-[size=xs]:px-2 group-data-[size=xs]:py-1",
          "group-data-[size=sm]:px-2 group-data-[size=sm]:py-1",
          "group-data-[size=md]:px-3 group-data-[size=md]:py-1.5",
          "group-data-[size=lg]:px-4 group-data-[size=lg]:py-2",
          "group-data-[size=xl]:px-4 group-data-[size=xl]:py-2",
          "group-data-[variant=ghost]:data-[has-start-decorator=true]:pl-0",
          "group-data-[variant=ghost]:data-[has-end-decorator=true]:pr-0"
        ]}
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

  attr :class, :any, default: ""
  attr :decorator_variant, :string, required: true
  attr :decorator_color, :string, required: true
  attr :decorator_size, :string, required: true
  slot :inner_block, required: true, doc: "Content to render inside the decorator"

  defp end_decorator(assigns) do
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

  # Single pattern-matched function for all variant/color/size combinations
  
  # Solid variant styles with improved contrast
  defp get_classes("solid", "primary", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-primary-50 dark:bg-primary-900/30",
      "text-primary-800 dark:text-primary-200",
      "focus-within:ring-2 focus-within:ring-primary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "secondary", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-secondary-50 dark:bg-secondary-900/30",
      "text-secondary-800 dark:text-secondary-200",
      "focus-within:ring-2 focus-within:ring-secondary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "info", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-info-50 dark:bg-info-900/30",
      "text-info-800 dark:text-info-200",
      "focus-within:ring-2 focus-within:ring-info-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "success", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-success-50 dark:bg-success-900/30",
      "text-success-800 dark:text-success-200",
      "focus-within:ring-2 focus-within:ring-success-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "danger", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-danger-50 dark:bg-danger-900/30",
      "text-danger-800 dark:text-danger-200",
      "focus-within:ring-2 focus-within:ring-danger-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "warning", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-warning-50 dark:bg-warning-900/30",
      "text-warning-800 dark:text-warning-200",
      "focus-within:ring-2 focus-within:ring-warning-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("solid", "neutral", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-gray-50 dark:bg-gray-800",
      "text-gray-800 dark:text-gray-200",
      "focus-within:ring-2 focus-within:ring-gray-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  # Outline variant styles with improved contrast
  defp get_classes("outline", "primary", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-primary-300 dark:border-primary-600",
      "text-primary-800 dark:text-primary-200",
      "focus-within:ring-2 focus-within:ring-primary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "secondary", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-secondary-300 dark:border-secondary-600",
      "text-secondary-800 dark:text-secondary-200",
      "focus-within:ring-2 focus-within:ring-secondary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "info", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-info-300 dark:border-info-600",
      "text-info-800 dark:text-info-200",
      "focus-within:ring-2 focus-within:ring-info-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "success", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-success-300 dark:border-success-600",
      "text-success-800 dark:text-success-200",
      "focus-within:ring-2 focus-within:ring-success-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "danger", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-danger-300 dark:border-danger-600",
      "text-danger-800 dark:text-danger-200",
      "focus-within:ring-2 focus-within:ring-danger-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "warning", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-warning-300 dark:border-warning-600",
      "text-warning-800 dark:text-warning-200",
      "focus-within:ring-2 focus-within:ring-warning-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("outline", "neutral", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-gray-300 dark:border-gray-600",
      "text-gray-800 dark:text-gray-200",
      "focus-within:ring-2 focus-within:ring-gray-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  # Ghost variant styles with improved contrast
  defp get_classes("ghost", "primary", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-primary-800 dark:text-primary-200",
      "focus-within:ring-2 focus-within:ring-primary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "secondary", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-secondary-800 dark:text-secondary-200",
      "focus-within:ring-2 focus-within:ring-secondary-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "info", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-info-800 dark:text-info-200",
      "focus-within:ring-2 focus-within:ring-info-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "success", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-success-800 dark:text-success-200",
      "focus-within:ring-2 focus-within:ring-success-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "danger", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-danger-800 dark:text-danger-200",
      "focus-within:ring-2 focus-within:ring-danger-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "warning", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-warning-800 dark:text-warning-200",
      "focus-within:ring-2 focus-within:ring-warning-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

  defp get_classes("ghost", "neutral", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "text-gray-800 dark:text-gray-200",
      "focus-within:ring-2 focus-within:ring-gray-500/50",
      get_size_classes(size),
      get_error_classes()
    ] |> Enum.join(" ")
  end

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

  defp get_error_classes do
    [
      "data-[invalid=true]:border-danger-500 data-[invalid=true]:text-danger-700",
      "dark:data-[invalid=true]:text-danger-300",
      "data-[invalid=true]:focus-within:ring-danger-500/50"
    ] |> Enum.join(" ")
  end

  defp get_required_classes do
    [
      # Subtle visual styling for required fields
      "data-[required=true]:shadow-sm",
      # More prominent focus ring for required fields
      "data-[required=true]:focus-within:ring-opacity-80"
    ] |> Enum.join(" ")
  end

  defp get_state_classes(disabled, readonly) do
    [
      disabled && "cursor-not-allowed opacity-50",
      readonly && "cursor-default"
    ]
    |> Enum.filter(&(&1))
    |> Enum.join(" ")
  end

  # Single pattern-matched function for all decorator combinations
  
  # Start decorators - solid variants
  defp get_decorator_classes("start", "solid", "primary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=primary]:border-r group-data-[color=primary]:border-primary-300 dark:group-data-[color=primary]:border-primary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "secondary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=secondary]:border-r group-data-[color=secondary]:border-secondary-300 dark:group-data-[color=secondary]:border-secondary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "info", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=info]:border-r group-data-[color=info]:border-info-300 dark:group-data-[color=info]:border-info-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "success", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=success]:border-r group-data-[color=success]:border-success-300 dark:group-data-[color=success]:border-success-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=danger]:border-r group-data-[color=danger]:border-danger-300 dark:group-data-[color=danger]:border-danger-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "warning", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=warning]:border-r group-data-[color=warning]:border-warning-300 dark:group-data-[color=warning]:border-warning-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "solid", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=neutral]:border-r group-data-[color=neutral]:border-gray-300 dark:group-data-[color=neutral]:border-gray-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  # Start decorators - outline variants with improved contrast
  defp get_decorator_classes("start", "outline", "primary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-primary-100 dark:bg-primary-900/40 text-primary-800 dark:text-primary-200",
      "group-data-[color=primary]:border-r group-data-[color=primary]:border-primary-300 dark:group-data-[color=primary]:border-primary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "secondary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-secondary-100 dark:bg-secondary-900/40 text-secondary-800 dark:text-secondary-200",
      "group-data-[color=secondary]:border-r group-data-[color=secondary]:border-secondary-300 dark:group-data-[color=secondary]:border-secondary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "info", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-info-100 dark:bg-info-900/40 text-info-800 dark:text-info-200",
      "group-data-[color=info]:border-r group-data-[color=info]:border-info-300 dark:group-data-[color=info]:border-info-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "success", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-success-100 dark:bg-success-900/40 text-success-800 dark:text-success-200",
      "group-data-[color=success]:border-r group-data-[color=success]:border-success-300 dark:group-data-[color=success]:border-success-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-danger-100 dark:bg-danger-900/40 text-danger-800 dark:text-danger-200",
      "group-data-[color=danger]:border-r group-data-[color=danger]:border-danger-300 dark:group-data-[color=danger]:border-danger-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "warning", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-warning-100 dark:bg-warning-900/40 text-warning-800 dark:text-warning-200",
      "group-data-[color=warning]:border-r group-data-[color=warning]:border-warning-300 dark:group-data-[color=warning]:border-warning-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200",
      "group-data-[color=neutral]:border-r group-data-[color=neutral]:border-gray-300 dark:group-data-[color=neutral]:border-gray-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  # Start decorators - ghost variants
  defp get_decorator_classes("start", "ghost", _color, size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[variant=ghost]:border-0",
      "group-data-[variant=ghost]:group-focus-within:pl-4",
      "group-data-[variant=ghost]:pl-0 group-data-[variant=ghost]:pr-2",
      "group-data-[variant=ghost]:transition-all duration-200 ease-in-out",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  # End decorators - solid variants
  defp get_decorator_classes("end", "solid", "primary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=primary]:border-l group-data-[color=primary]:border-primary-300 dark:group-data-[color=primary]:border-primary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "secondary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=secondary]:border-l group-data-[color=secondary]:border-secondary-300 dark:group-data-[color=secondary]:border-secondary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "info", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=info]:border-l group-data-[color=info]:border-info-300 dark:group-data-[color=info]:border-info-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "success", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=success]:border-l group-data-[color=success]:border-success-300 dark:group-data-[color=success]:border-success-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=danger]:border-l group-data-[color=danger]:border-danger-300 dark:group-data-[color=danger]:border-danger-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "warning", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=warning]:border-l group-data-[color=warning]:border-warning-300 dark:group-data-[color=warning]:border-warning-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "solid", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[color=neutral]:border-l group-data-[color=neutral]:border-gray-300 dark:group-data-[color=neutral]:border-gray-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  # End decorators - outline variants with improved contrast
  defp get_decorator_classes("end", "outline", "primary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-primary-100 dark:bg-primary-900/40 text-primary-800 dark:text-primary-200",
      "group-data-[color=primary]:border-l group-data-[color=primary]:border-primary-300 dark:group-data-[color=primary]:border-primary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "secondary", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-secondary-100 dark:bg-secondary-900/40 text-secondary-800 dark:text-secondary-200",
      "group-data-[color=secondary]:border-l group-data-[color=secondary]:border-secondary-300 dark:group-data-[color=secondary]:border-secondary-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "info", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-info-100 dark:bg-info-900/40 text-info-800 dark:text-info-200",
      "group-data-[color=info]:border-l group-data-[color=info]:border-info-300 dark:group-data-[color=info]:border-info-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "success", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-success-100 dark:bg-success-900/40 text-success-800 dark:text-success-200",
      "group-data-[color=success]:border-l group-data-[color=success]:border-success-300 dark:group-data-[color=success]:border-success-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-danger-100 dark:bg-danger-900/40 text-danger-800 dark:text-danger-200",
      "group-data-[color=danger]:border-l group-data-[color=danger]:border-danger-300 dark:group-data-[color=danger]:border-danger-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "warning", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-warning-100 dark:bg-warning-900/40 text-warning-800 dark:text-warning-200",
      "group-data-[color=warning]:border-l group-data-[color=warning]:border-warning-300 dark:group-data-[color=warning]:border-warning-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200",
      "group-data-[color=neutral]:border-l group-data-[color=neutral]:border-gray-300 dark:group-data-[color=neutral]:border-gray-600",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end

  # End decorators - ghost variants
  defp get_decorator_classes("end", "ghost", _color, size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center bg-transparent",
      "group-data-[variant=ghost]:border-0",
      "group-data-[variant=ghost]:group-focus-within:pr-4",
      "group-data-[variant=ghost]:pl-2 group-data-[variant=ghost]:pr-0",
      "group-data-[variant=ghost]:transition-all duration-200 ease-in-out",
      "group-data-[invalid=true]:bg-danger-50 dark:group-data-[invalid=true]:bg-danger-500/20",
      "group-data-[invalid=true]:text-danger-700 dark:group-data-[invalid=true]:text-danger-300",
      "group-data-[invalid=true]:border-danger-300 dark:group-data-[invalid=true]:border-danger-600"
    ] |> Enum.join(" ")
  end
end
