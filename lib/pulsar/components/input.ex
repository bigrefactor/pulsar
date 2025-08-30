defmodule Pulsar.Components.Input do
  @moduledoc """
  Styled input component built on Stellar.Components.Input with decorator support.

  Provides beautiful, accessible input fields with optional start and end decorators 
  for icons, text, or interactive elements. All styling is applied via Tailwind CSS 
  utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible input component
  - **Decorator System**: Start/end decorators for icons, text, or interactive elements
  - **Simplified Variants**: Only outline and ghost variants for predictable UX
  - **Automatic Colors**: Neutral by default, danger for errors - no manual color prop
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button component sizes
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar input props are supported

  ## Examples

      # Basic input
      <.input field={@form[:email]} />

      # With decorators
      <.input field={@form[:amount]} variant="outline">
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
    values: ~w(outline ghost),
    doc: "Visual style variant of the input"

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

    effective_color = if has_errors, do: "danger", else: "neutral"

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

  # Simplified styling for only outline/ghost variants with automatic colors

  # Outline variant - default neutral styling
  defp get_classes("outline", "neutral", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-border dark:border-dark-border",
      "bg-background dark:bg-dark-background",
      "text-foreground dark:text-dark-foreground",
      "focus-within:ring-2 focus-within:ring-primary-500/60 focus-within:ring-offset-2",
      "hover:border-primary-300 dark:hover:border-primary-600",
      get_size_classes(size)
    ] |> Enum.join(" ")
  end

  # Outline variant - danger styling for errors  
  defp get_classes("outline", "danger", size) do
    [
      "flex group overflow-hidden border-2 rounded-lg",
      "border-danger-500 dark:border-danger-400",
      "bg-background dark:bg-dark-background", 
      "text-danger-700 dark:text-danger-300",
      "focus-within:ring-2 focus-within:ring-danger-500/60 focus-within:ring-offset-2",
      get_size_classes(size)
    ] |> Enum.join(" ")
  end

  # Ghost variant - minimal neutral styling
  defp get_classes("ghost", "neutral", size) do
    [
      "flex group overflow-hidden rounded-lg",
      "bg-transparent",
      "text-foreground dark:text-dark-foreground",
      "focus-within:ring-2 focus-within:ring-primary-500/60 focus-within:ring-offset-2",
      "hover:bg-surface-secondary dark:hover:bg-dark-surface-secondary",
      get_size_classes(size)
    ] |> Enum.join(" ")
  end

  # Ghost variant - danger styling for errors
  defp get_classes("ghost", "danger", size) do
    [
      "flex group overflow-hidden rounded-lg", 
      "bg-transparent",
      "text-danger-700 dark:text-danger-300",
      "focus-within:ring-2 focus-within:ring-danger-500/60 focus-within:ring-offset-2",
      "hover:bg-danger-50 dark:hover:bg-danger-900/20",
      get_size_classes(size)
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

  # Simplified decorator functions for outline/ghost variants only

  # Start decorators - outline variant (neutral/danger only)
  defp get_decorator_classes("start", "outline", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-surface-secondary dark:bg-dark-surface-secondary",
      "text-muted dark:text-dark-muted",
      "border-r border-border dark:border-dark-border",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end

  defp get_decorator_classes("start", "outline", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-danger-50 dark:bg-danger-900/20",
      "text-danger-700 dark:text-danger-300",
      "border-r border-danger-500 dark:border-danger-400",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end

  # End decorators - outline variant (neutral/danger only)  
  defp get_decorator_classes("end", "outline", "neutral", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-surface-secondary dark:bg-dark-surface-secondary",
      "text-muted dark:text-dark-muted",
      "border-l border-border dark:border-dark-border",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "outline", "danger", size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "bg-danger-50 dark:bg-danger-900/20",
      "text-danger-700 dark:text-danger-300",
      "border-l border-danger-500 dark:border-danger-400",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end

  # Ghost decorators - minimal styling
  defp get_decorator_classes("start", "ghost", _color, size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "text-muted dark:text-dark-muted",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end

  defp get_decorator_classes("end", "ghost", _color, size) do
    [
      "#{get_decorator_padding(size)} flex items-center justify-center",
      "text-muted dark:text-dark-muted",
      get_decorator_font_size(size)
    ] |> Enum.filter(&(&1 != "")) |> Enum.join(" ")
  end
end