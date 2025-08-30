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
  def input(assigns) do
    class =
      merge([
        "flex group",
        "data-[variant=outline]:border-2",
        "focus-within:ring-2 focus-within:ring-ring dark:focus-within:ring-dark-ring",
        "rounded-lg overflow-hidden",
        "data-[color=primary]:border-primary/80 data-[color=info]:border-info/80",
        "data-[color=secondary]:border-secondary/80 data-[color=success]:border-success/80",
        "data-[color=danger]:border-danger/80 data-[color=warning]:border-warning/80",
        "data-[color=neutral]:border-muted/80 dark:data-[color=neutral]:border-dark-muted/80",
        "data-[color=primary]:text-primary data-[color=info]:text-info",
        "data-[color=secondary]:text-secondary data-[color=success]:text-success",
        "data-[color=danger]:text-danger data-[color=warning]:text-warning",
        "data-[color=neutral]:text-muted dark:data-[color=neutral]:text-dark-muted",
        "data-[variant=solid]:data-[color=neutral]:bg-muted/30",
        "data-[variant=solid]:data-[color=primary]:bg-primary/30",
        "data-[variant=solid]:data-[color=secondary]:bg-secondary/30",
        "data-[variant=solid]:data-[color=info]:bg-info/30",
        "data-[variant=solid]:data-[color=warning]:bg-warning/30",
        "data-[variant=solid]:data-[color=danger]:bg-danger/30",
        "data-[variant=solid]:data-[color=success]:bg-success/30",
        "data-[variant=solid]:text-foreground",
        assigns.disabled && "cursor-not-allowed opacity-50",
        assigns.readonly && "cursor-default",
        get_size_classes(assigns.size),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:has_start_decorator, assigns.start_decorator != [])
      |> assign(:has_end_decorator, assigns.end_decorator != [])

    ~H"""
    <div
      class={@class}
      data-variant={@variant}
      data-size={@size}
      data-color={@color}
      data-has-start-decorator={@has_start_decorator}
      data-has-end-decorator={@has_end_decorator}
    >
      <.start_decorator :if={@start_decorator != []}>
        {render_slot(@start_decorator)}
      </.start_decorator>

      <StellarInput.input
        class={[
          "w-full outline-0 group-data-[size=sm]:py-1",
          "py-2 group-data-[size=xs]:py-1 group-data-[size=md]:py-1.5",
          "group-data-[size=xs]:px-2",
          "group-data-[size=sm]:px-2",
          "group-data-[size=md]:px-3",
          "group-data-[size=lg]:px-4",
          "group-data-[size=xl]:px-4",
          "group-data-[variant=ghost]:pl-0",
          "group-data-[variant=ghost]:pr-2",
          "group-focus-within:group-data-[variant=ghost]:group-data-[size=xs]:px-2",
          "group-focus-within:group-data-[variant=ghost]:group-data-[size=sm]:px-2",
          "group-focus-within:group-data-[variant=ghost]:group-data-[size=md]:px-3",
          "group-focus-within:group-data-[variant=ghost]:group-data-[size=lg]:px-4",
          "group-focus-within:group-data-[variant=ghost]:group-data-[size=xl]:px-4",
          "transition-all duration-200 ease-in-out"
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

      <.end_decorator :if={@end_decorator != []}>
        {render_slot(@end_decorator)}
      </.end_decorator>
    </div>
    """
  end

  attr :class, :any, default: ""
  slot :inner_block, required: true, doc: "Content to render inside the decorator"

  defp start_decorator(assigns) do
    class = [
      "px-4 py-2 flex items-center justify-center",
      "group-data-[color=primary]:bg-primary/30 group-data-[color=info]:bg-info/30",
      "group-data-[color=secondary]:bg-secondary/30 group-data-[color=success]:bg-success/30",
      "group-data-[color=danger]:bg-danger/30 group-data-[color=warning]:bg-warning/30",
      "group-data-[color=neutral]:bg-muted/30 dark:group-data-[color=neutral]:bg-dark-muted/30",
      "group-data-[variant=solid]:bg-transparent",
      "group-data-[variant=ghost]:bg-transparent",
      "group-data-[color=primary]:border-r group-data-[color=primary]:border-primary/80",
      "group-data-[color=secondary]:border-r group-data-[color=primary]:border-secondary/80",
      "group-data-[color=info]:border-r group-data-[color=primary]:border-info/80",
      "group-data-[color=success]:border-r group-data-[color=success]:border-success/80",
      "group-data-[color=warning]:border-r group-data-[color=warning]:border-warning/80",
      "group-data-[color=danger]:border-r group-data-[color=danger]:border-danger/80",
      "group-data-[color=neutral]:border-r group-data-[color=neutral]:border-muted/80",
      "group-data-[variant=ghost]:border-0",
      "group-data-[variant=ghost]:group-focus-within:pl-4",
      "group-data-[variant=ghost]:pl-0 group-data-[variant=ghost]:pr-2",
      "group-data-[variant=ghost]:transition-all duration-200 ease-in-out"
    ]

    assigns = assign(assigns, :class, merge([class, assigns.class]))

    ~H"""
    <div class={@class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: ""
  slot :inner_block, required: true, doc: "Content to render inside the decorator"

  defp end_decorator(assigns) do
    class = [
      "px-4 py-2 flex items-center justify-center",
      "group-data-[color=primary]:bg-primary/30 group-data-[color=info]:bg-info/30",
      "group-data-[color=secondary]:bg-secondary/30 group-data-[color=success]:bg-success/30",
      "group-data-[color=danger]:bg-danger/30 group-data-[color=warning]:bg-warning/30",
      "group-data-[color=neutral]:bg-muted/30 dark:group-data-[color=neutral]:bg-dark-muted/30",
      "group-data-[variant=solid]:bg-transparent",
      "group-data-[variant=ghost]:bg-transparent",
      "group-data-[color=primary]:border-l group-data-[color=primary]:border-primary/80",
      "group-data-[color=secondary]:border-l group-data-[color=primary]:border-secondary/80",
      "group-data-[color=info]:border-l group-data-[color=primary]:border-info/80",
      "group-data-[color=success]:border-l group-data-[color=success]:border-success/80",
      "group-data-[color=warning]:border-l group-data-[color=warning]:border-warning/80",
      "group-data-[color=danger]:border-l group-data-[color=danger]:border-danger/80",
      "group-data-[color=neutral]:border-l group-data-[color=neutral]:border-muted/80",
      "group-data-[variant=ghost]:border-0",
      "group-data-[variant=ghost]:group-focus-within:pl-4",
      "group-data-[variant=ghost]:pl-0 group-data-[variant=ghost]:pr-1",
      "group-data-[variant=ghost]:transition-all duration-200 ease-in-out"
    ]

    assigns = assign(assigns, :class, merge([class, assigns.class]))

    ~H"""
    <div class={@class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Helper functions for building size and variant-aware classes
  defp get_size_classes("xs"), do: "h-6 text-xs rounded-md"
  defp get_size_classes("sm"), do: "h-8 text-sm rounded-md"
  defp get_size_classes("md"), do: "h-10 rounded-lg"
  defp get_size_classes("lg"), do: "h-12 text-lg rounded-lg"
  defp get_size_classes("xl"), do: "h-14 text-xl rounded-lg"
end
