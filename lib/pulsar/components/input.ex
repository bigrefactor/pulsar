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
  - Accessibility features and ARIA attributes (including `aria-invalid`)
  - Validation error signaling via `aria-invalid`
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
    default: "solid",
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

  # State override (optional)
  attr :invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"

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
  @spec input(map()) :: Phoenix.LiveView.Rendered.t()
  def input(%{type: "hidden"} = assigns) do
    # Validate required attributes for hidden inputs too
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Input component requires :name when :field is not provided"
    end

    ~H"""
    <StellarInput.input
      type="hidden"
      field={@field}
      id={@id}
      name={@name}
      value={@value}
      disabled={@disabled}
      readonly={@readonly}
      class={@class}
      {@rest}
    />
    """
  end

  def input(assigns) do
    # Validate required attributes
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Input component requires :name when :field is not provided"
    end

    # Detect errors and compute automatic color
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    class =
      merge([
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
      |> assign(:invalid, invalid)
      |> assign(:required_attr, assigns.required)

    ~H"""
    <div
      class={@class}
      data-variant={@variant}
      data-size={@size}
      data-color={@decorator_color}
      data-has-start-decorator={@has_start_decorator}
      data-has-end-decorator={@has_end_decorator}
      data-invalid={if @invalid, do: "true", else: "false"}
      data-required={@required_attr}
    >
      <.start_decorator
        :if={@start_decorator != []}
        decorator_variant={@decorator_variant}
        decorator_color={@decorator_color}
        decorator_size={@size}
      >
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
          |> Enum.filter(& &1)
        }
        type={@type}
        field={@field}
        id={@id}
        name={@name}
        value={@value}
        required={@required}
        disabled={@disabled}
        readonly={@readonly}
        aria-invalid={if @invalid, do: "true", else: "false"}
        {@rest}
      />

      <.end_decorator
        :if={@end_decorator != []}
        decorator_variant={@decorator_variant}
        decorator_color={@decorator_color}
        decorator_size={@size}
      >
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

    class =
      merge([
        get_decorator_classes(
          "start",
          assigns.decorator_variant,
          assigns.decorator_color,
          assigns.decorator_size
        ),
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

    class =
      merge([
        get_decorator_classes(
          "end",
          assigns.decorator_variant,
          assigns.decorator_color,
          assigns.decorator_size
        ),
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
  defp color_classes("outline", "neutral"),
    do:
      "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:border-primary/50 dark:hover:border-dark-primary/50"

  defp color_classes("outline", "primary"),
    do:
      "border-primary/60 dark:border-dark-primary/60 bg-background dark:bg-dark-background text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:border-primary dark:hover:border-dark-primary"

  defp color_classes("outline", "secondary"),
    do:
      "border-secondary/60 dark:border-dark-secondary/60 bg-background dark:bg-dark-background text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:border-secondary dark:hover:border-dark-secondary"

  defp color_classes("outline", "success"),
    do:
      "border-success/60 dark:border-dark-success/60 bg-background dark:bg-dark-background text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:border-success dark:hover:border-dark-success"

  defp color_classes("outline", "danger"),
    do:
      "border-danger/60 dark:border-dark-danger/60 bg-background dark:bg-dark-background text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:border-danger dark:hover:border-dark-danger"

  defp color_classes("outline", "warning"),
    do:
      "border-warning/60 dark:border-dark-warning/60 bg-background dark:bg-dark-background text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:border-warning dark:hover:border-dark-warning"

  defp color_classes("outline", "info"),
    do:
      "border-info/60 dark:border-dark-info/60 bg-background dark:bg-dark-background text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:border-info dark:hover:border-dark-info"

  defp color_classes("ghost", "neutral"),
    do:
      "bg-transparent text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover"

  defp color_classes("ghost", "primary"),
    do:
      "bg-transparent text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:bg-primary/5 dark:hover:bg-dark-primary/10"

  defp color_classes("ghost", "secondary"),
    do:
      "bg-transparent text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/5 dark:hover:bg-dark-secondary/10"

  defp color_classes("ghost", "success"),
    do:
      "bg-transparent text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:bg-success/5 dark:hover:bg-dark-success/10"

  defp color_classes("ghost", "danger"),
    do:
      "bg-transparent text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:bg-danger/5 dark:hover:bg-dark-danger/10"

  defp color_classes("ghost", "warning"),
    do:
      "bg-transparent text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:bg-warning/5 dark:hover:bg-dark-warning/10"

  defp color_classes("ghost", "info"),
    do:
      "bg-transparent text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:bg-info/5 dark:hover:bg-dark-info/10"

  defp color_classes("solid", "neutral"),
    do:
      "bg-neutral/10 dark:bg-dark-neutral/20 text-neutral dark:text-dark-neutral placeholder:text-neutral/70 dark:placeholder:text-dark-neutral/70 focus-within:ring-neutral/60 hover:bg-neutral/20 dark:hover:bg-dark-neutral/30"

  defp color_classes("solid", "primary"),
    do:
      "bg-primary/10 dark:bg-dark-primary/20 text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:bg-primary/20 dark:hover:bg-dark-primary/30"

  defp color_classes("solid", "secondary"),
    do:
      "bg-secondary/10 dark:bg-dark-secondary/20 text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/20 dark:hover:bg-dark-secondary/30"

  defp color_classes("solid", "success"),
    do:
      "bg-success/10 dark:bg-dark-success/20 text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:bg-success/20 dark:hover:bg-dark-success/30"

  defp color_classes("solid", "danger"),
    do:
      "bg-danger/10 dark:bg-dark-danger/20 text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:bg-danger/20 dark:hover:bg-dark-danger/30"

  defp color_classes("solid", "warning"),
    do:
      "bg-warning/10 dark:bg-dark-warning/20 text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:bg-warning/20 dark:hover:bg-dark-warning/30"

  defp color_classes("solid", "info"),
    do:
      "bg-info/10 dark:bg-dark-info/20 text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:bg-info/20 dark:hover:bg-dark-info/30"

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
    |> Enum.filter(& &1)
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

  defp decorator_color_classes("outline", "neutral"),
    do:
      "bg-border dark:bg-dark-border text-neutral-700 dark:text-neutral-300 border-border dark:border-dark-border"

  defp decorator_color_classes("outline", "primary"),
    do:
      "bg-primary/60 dark:bg-dark-primary/60 text-primary-foreground dark:text-dark-primary-foreground border-primary/60 dark:border-dark-primary/60"

  defp decorator_color_classes("outline", "secondary"),
    do:
      "bg-secondary/60 dark:bg-dark-secondary/60 text-secondary-foreground dark:text-dark-secondary-foreground border-secondary/60 dark:border-dark-secondary/60"

  defp decorator_color_classes("outline", "success"),
    do:
      "bg-success/60 dark:bg-dark-success/60 text-success-foreground dark:text-dark-success-foreground border-success/60 dark:border-dark-success/60"

  defp decorator_color_classes("outline", "danger"),
    do:
      "bg-danger/60 dark:bg-dark-danger/60 text-danger-foreground dark:text-dark-danger-foreground border-danger/60 dark:border-dark-danger/60"

  defp decorator_color_classes("outline", "warning"),
    do:
      "bg-warning/60 dark:bg-dark-warning/60 text-warning-foreground dark:text-dark-warning-foreground border-warning/60 dark:border-dark-warning/60"

  defp decorator_color_classes("outline", "info"),
    do:
      "bg-info/60 dark:bg-dark-info/60 text-info-foreground dark:text-dark-info-foreground border-info/60 dark:border-dark-info/60"

  defp decorator_color_classes("solid", "neutral"),
    do:
      "bg-neutral/20 dark:bg-dark-neutral/30 text-neutral dark:text-dark-neutral border-neutral/30 dark:border-dark-neutral/40"

  defp decorator_color_classes("solid", "primary"),
    do:
      "bg-primary/20 dark:bg-dark-primary/30 text-primary dark:text-dark-primary border-primary/30 dark:border-dark-primary/40"

  defp decorator_color_classes("solid", "secondary"),
    do:
      "bg-secondary/20 dark:bg-dark-secondary/30 text-secondary dark:text-dark-secondary border-secondary/30 dark:border-dark-secondary/40"

  defp decorator_color_classes("solid", "success"),
    do:
      "bg-success/20 dark:bg-dark-success/30 text-success dark:text-dark-success border-success/30 dark:border-dark-success/40"

  defp decorator_color_classes("solid", "danger"),
    do:
      "bg-danger/20 dark:bg-dark-danger/30 text-danger dark:text-dark-danger border-danger/30 dark:border-dark-danger/40"

  defp decorator_color_classes("solid", "warning"),
    do:
      "bg-warning/20 dark:bg-dark-warning/30 text-warning dark:text-dark-warning border-warning/30 dark:border-dark-warning/40"

  defp decorator_color_classes("solid", "info"),
    do:
      "bg-info/20 dark:bg-dark-info/30 text-info dark:text-dark-info border-info/30 dark:border-dark-info/40"

  defp decorator_color_classes("ghost", _color),
    do: "text-muted-foreground dark:text-dark-muted-foreground"

  # Keep local and private - helper for error detection
  defp has_field_errors(%{field: %Phoenix.HTML.FormField{errors: errs}})
       when is_list(errs) and errs != [],
       do: true

  defp has_field_errors(_), do: false
end
