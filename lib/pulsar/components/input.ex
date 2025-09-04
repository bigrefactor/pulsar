defmodule Pulsar.Components.Input do
  @moduledoc """
  Self-contained styled input component with decorator support.

  Provides beautiful, accessible input fields with optional start and end decorators 
  for icons, text, or interactive elements. All styling is applied via Tailwind CSS 
  utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Self-Contained**: No external dependencies beyond TailwindMerge
  - **Decorator System**: Start/end decorators for icons, text, or interactive elements
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button component sizes
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Accessibility Built-in**: ARIA attributes and keyboard navigation included

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

  ## Phoenix Integration

  This component provides seamless Phoenix form integration:
  - All HTML5 input types (text, email, password, number, etc.)
  - Phoenix form integration with automatic error detection
  - ARIA support: Built-in `aria-invalid` attribute management
  - Validation error signaling with automatic danger styling
  - Mobile keyboard optimization
  - All standard HTML attributes supported via `:rest`

  ## Decorator Slots

  - `:start_decorator` - Leading decorator (icons, text, buttons)
  - `:end_decorator` - Trailing decorator (icons, text, buttons)

  Decorators are visually integrated with the input field, sharing borders
  and backgrounds based on the selected variant.
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for input and decorators
  @size_config %{
    "lg" => %{
      container: "min-h-12 text-lg",
      decorator_padding: "px-4 py-2",
      decorator_text: "text-lg",
      input_padding: "px-4 py-2"
    },
    "md" => %{
      container: "min-h-10",
      decorator_padding: "px-3 py-1.5",
      decorator_text: "",
      input_padding: "px-3 py-1.5"
    },
    "sm" => %{
      container: "min-h-8 text-sm",
      decorator_padding: "px-2 py-1",
      decorator_text: "text-sm",
      input_padding: "px-2 py-1"
    },
    "xl" => %{
      container: "min-h-14 text-xl",
      decorator_padding: "px-4 py-2",
      decorator_text: "text-xl",
      input_padding: "px-4 py-2"
    },
    "xs" => %{
      container: "min-h-6 text-xs",
      decorator_padding: "px-2 py-1",
      decorator_text: "text-xs",
      input_padding: "px-2 py-1"
    }
  }

  # Base input container classes
  @base_input_classes [
    "flex group overflow-hidden transition-all duration-200 ease-in-out",
    "focus-within:ring-2 focus-within:ring-offset-2"
  ]

  # Variant base configuration
  @variant_config %{
    "ghost" => "rounded-lg",
    "outline" => "border-2 rounded-lg",
    "solid" => "rounded-lg"
  }

  # Color configuration organized by variant and color
  # Structure: variant -> color -> classes
  @color_config %{
    "ghost" => %{
      "danger" =>
        "bg-transparent text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:bg-danger/5 dark:hover:bg-dark-danger/10",
      "info" =>
        "bg-transparent text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:bg-info/5 dark:hover:bg-dark-info/10",
      "neutral" =>
        "bg-transparent text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover",
      "primary" =>
        "bg-transparent text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:bg-primary/5 dark:hover:bg-dark-primary/10",
      "secondary" =>
        "bg-transparent text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/5 dark:hover:bg-dark-secondary/10",
      "success" =>
        "bg-transparent text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:bg-success/5 dark:hover:bg-dark-success/10",
      "warning" =>
        "bg-transparent text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:bg-warning/5 dark:hover:bg-dark-warning/10"
    },
    "outline" => %{
      "danger" =>
        "border-danger/60 dark:border-dark-danger/60 bg-background dark:bg-dark-background text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:border-danger dark:hover:border-dark-danger",
      "info" =>
        "border-info/60 dark:border-dark-info/60 bg-background dark:bg-dark-background text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:border-info dark:hover:border-dark-info",
      "neutral" =>
        "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus-within:ring-ring dark:focus-within:ring-dark-ring hover:border-primary/50 dark:hover:border-dark-primary/50",
      "primary" =>
        "border-primary/60 dark:border-dark-primary/60 bg-background dark:bg-dark-background text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:border-primary dark:hover:border-dark-primary",
      "secondary" =>
        "border-secondary/60 dark:border-dark-secondary/60 bg-background dark:bg-dark-background text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:border-secondary dark:hover:border-dark-secondary",
      "success" =>
        "border-success/60 dark:border-dark-success/60 bg-background dark:bg-dark-background text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:border-success dark:hover:border-dark-success",
      "warning" =>
        "border-warning/60 dark:border-dark-warning/60 bg-background dark:bg-dark-background text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:border-warning dark:hover:border-dark-warning"
    },
    "solid" => %{
      "danger" =>
        "bg-danger/10 dark:bg-dark-danger/20 text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus-within:ring-danger/60 hover:bg-danger/20 dark:hover:bg-dark-danger/30",
      "info" =>
        "bg-info/10 dark:bg-dark-info/20 text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus-within:ring-info/60 hover:bg-info/20 dark:hover:bg-dark-info/30",
      "neutral" =>
        "bg-neutral/10 dark:bg-dark-neutral/20 text-neutral dark:text-dark-neutral placeholder:text-neutral/70 dark:placeholder:text-dark-neutral/70 focus-within:ring-neutral/60 hover:bg-neutral/20 dark:hover:bg-dark-neutral/30",
      "primary" =>
        "bg-primary/10 dark:bg-dark-primary/20 text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus-within:ring-primary/60 hover:bg-primary/20 dark:hover:bg-dark-primary/30",
      "secondary" =>
        "bg-secondary/10 dark:bg-dark-secondary/20 text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/20 dark:hover:bg-dark-secondary/30",
      "success" =>
        "bg-success/10 dark:bg-dark-success/20 text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus-within:ring-success/60 hover:bg-success/20 dark:hover:bg-dark-success/30",
      "warning" =>
        "bg-warning/10 dark:bg-dark-warning/20 text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus-within:ring-warning/60 hover:bg-warning/20 dark:hover:bg-dark-warning/30"
    }
  }

  # Decorator color configuration
  @decorator_config %{
    "outline" => %{
      "danger" =>
        "bg-danger/60 dark:bg-dark-danger/60 text-danger-foreground dark:text-dark-danger-foreground border-danger/60 dark:border-dark-danger/60",
      "info" =>
        "bg-info/60 dark:bg-dark-info/60 text-info-foreground dark:text-dark-info-foreground border-info/60 dark:border-dark-info/60",
      "neutral" =>
        "bg-border dark:bg-dark-border text-neutral-700 dark:text-neutral-300 border-border dark:border-dark-border",
      "primary" =>
        "bg-primary/60 dark:bg-dark-primary/60 text-primary-foreground dark:text-dark-primary-foreground border-primary/60 dark:border-dark-primary/60",
      "secondary" =>
        "bg-secondary/60 dark:bg-dark-secondary/60 text-secondary-foreground dark:text-dark-secondary-foreground border-secondary/60 dark:border-dark-secondary/60",
      "success" =>
        "bg-success/60 dark:bg-dark-success/60 text-success-foreground dark:text-dark-success-foreground border-success/60 dark:border-dark-success/60",
      "warning" =>
        "bg-warning/60 dark:bg-dark-warning/60 text-warning-foreground dark:text-dark-warning-foreground border-warning/60 dark:border-dark-warning/60"
    },
    "solid" => %{
      "danger" =>
        "bg-danger/20 dark:bg-dark-danger/30 text-danger dark:text-dark-danger border-danger/30 dark:border-dark-danger/40",
      "info" => "bg-info/20 dark:bg-dark-info/30 text-info dark:text-dark-info border-info/30 dark:border-dark-info/40",
      "neutral" =>
        "bg-neutral/20 dark:bg-dark-neutral/30 text-neutral dark:text-dark-neutral border-neutral/30 dark:border-dark-neutral/40",
      "primary" =>
        "bg-primary/20 dark:bg-dark-primary/30 text-primary dark:text-dark-primary border-primary/30 dark:border-dark-primary/40",
      "secondary" =>
        "bg-secondary/20 dark:bg-dark-secondary/30 text-secondary dark:text-dark-secondary border-secondary/30 dark:border-dark-secondary/40",
      "success" =>
        "bg-success/20 dark:bg-dark-success/30 text-success dark:text-dark-success border-success/30 dark:border-dark-success/40",
      "warning" =>
        "bg-warning/20 dark:bg-dark-warning/30 text-warning dark:text-dark-warning border-warning/30 dark:border-dark-warning/40"
    },
    "ghost" => %{
      # Ghost decorators are minimal and don't vary by color
      "all" => "text-muted-foreground dark:text-dark-muted-foreground"
    }
  }

  # Inline ID generator (replacing Stellar.Helpers.IdGenerator)
  defp generate_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Essential Stellar helpers copied locally for normalization
  defp normalize_field_props(assigns) do
    field = assigns[:field]

    if field do
      %{
        errors: field.errors || [],
        id: assigns[:id] || field.id || generate_id("input"),
        name: assigns[:name] || field.name,
        value: assigns[:value] || field.value
      }
    else
      %{
        errors: [],
        id: assigns[:id] || generate_id("input"),
        name: assigns[:name],
        value: assigns[:value]
      }
    end
  end

  defp assign_computed_attributes(assigns, normalized) do
    assigns
    |> assign(:id, normalized.id)
    |> assign(:name, normalized.name)
    |> assign(:value, normalized.value)
    |> assign(:field_errors, normalized.errors)
  end

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(outline ghost solid),
    doc: "Visual style variant of the input"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the input (overridden by error state)"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the input"
  )

  # Stellar input attributes - copied from Stellar.Components.Input
  attr(:type, :string,
    values:
      ~w(text email password number tel url search date time datetime-local month week color range file hidden checkbox radio button submit reset image),
    default: "text",
    doc: "Input type"
  )

  attr(:field, FormField, default: nil, doc: "Phoenix form field")

  # Core attributes
  attr(:id, :string,
    default: nil,
    doc: "Input ID (auto-generated if not provided)"
  )

  attr(:name, :string,
    default: nil,
    doc: "Input name (from field if not provided)"
  )

  attr(:value, :any,
    default: nil,
    doc: "Input value (from field if not provided)"
  )

  # State attributes
  attr(:required, :boolean,
    default: false,
    doc: "Mark input as required"
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Disable the input"
  )

  attr(:readonly, :boolean,
    default: false,
    doc: "Make input read-only"
  )

  # State override (optional)
  attr(:invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"
  )

  # Styling
  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes including placeholder")

  # Decorator slots
  slot(:start_decorator,
    doc: "Leading decorator content (icons, text, buttons)"
  )

  slot(:end_decorator,
    doc: "Trailing decorator content (icons, text, buttons)"
  )

  @doc """
  Renders a styled input component with optional decorators.

  This self-contained component provides comprehensive styling and accessibility
  features with support for start/end decorators. All HTML5 input attributes
  are supported, with styling automatically determined by variant and error state.

  Error states automatically apply danger styling when using Phoenix forms.
  """
  @spec input(map()) :: Rendered.t()
  def input(assigns) do
    # Validate required attributes
    validate_required_attributes(assigns)

    # Normalize field properties
    normalized = normalize_field_props(assigns)
    assigns = assign_computed_attributes(assigns, normalized)

    # Handle hidden inputs with simpler rendering
    if assigns.type == "hidden" do
      render_hidden_input(assigns)
    else
      render_styled_input(assigns, normalized)
    end
  end

  # Render a simple hidden input without decorators
  defp render_hidden_input(assigns) do
    ~H"""
    <input
      type="hidden"
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

  # Render a styled input with decorators and full styling
  defp render_styled_input(assigns, normalized) do
    # Detect errors and compute automatic color
    has_errors = not Enum.empty?(normalized.errors)
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
      data-required={if @required_attr, do: "true", else: "false"}
    >
      <.start_decorator
        :if={@has_start_decorator}
        decorator_variant={@decorator_variant}
        decorator_color={@decorator_color}
        decorator_size={@size}
      >
        {render_slot(@start_decorator)}
      </.start_decorator>

      <input
        class={
          [
            "w-full outline-0 transition-all duration-200 ease-in-out",
            get_input_padding_classes(@size),
            "group-data-[variant=ghost]:group-data-[has-start-decorator=true]:pl-0",
            "group-data-[variant=ghost]:group-data-[has-end-decorator=true]:pr-0",
            (@disabled && "cursor-not-allowed") || (@readonly && "cursor-default") || nil
          ]
          |> Enum.filter(& &1)
        }
        type={@type}
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
        :if={@has_end_decorator}
        decorator_variant={@decorator_variant}
        decorator_color={@decorator_color}
        decorator_size={@size}
      >
        {render_slot(@end_decorator)}
      </.end_decorator>
    </div>
    """
  end

  # Validate that required attributes are present
  defp validate_required_attributes(assigns) do
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Input component requires :name when :field is not provided"
    end
  end

  attr(:class, :any, default: "")
  attr(:decorator_variant, :string, required: true)
  attr(:decorator_color, :string, required: true)
  attr(:decorator_size, :string, required: true)
  slot(:inner_block, required: true, doc: "Content to render inside the decorator")

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
      Enum.join(@base_input_classes, " "),
      @variant_config[variant],
      get_color_classes(variant, color),
      @size_config[size][:container]
    ])
  end

  # Get color classes from configuration
  defp get_color_classes(variant, color) do
    @color_config[variant][color] || ""
  end

  defp get_state_classes(disabled, readonly) do
    [
      disabled && "cursor-not-allowed opacity-50 pointer-events-none",
      readonly && "cursor-default"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Get input element padding classes based on size
  defp get_input_padding_classes(size) do
    case size do
      "xs" -> ["group-data-[size=xs]:px-2", "group-data-[size=xs]:py-1"]
      "sm" -> ["group-data-[size=sm]:px-2", "group-data-[size=sm]:py-1"]
      "md" -> ["group-data-[size=md]:px-3", "group-data-[size=md]:py-1.5"]
      "lg" -> ["group-data-[size=lg]:px-4", "group-data-[size=lg]:py-2"]
      "xl" -> ["group-data-[size=xl]:px-4", "group-data-[size=xl]:py-2"]
      _ -> ["group-data-[size=md]:px-3", "group-data-[size=md]:py-1.5"]
    end
  end

  # Decorator functions supporting all variants and colors
  defp get_decorator_classes(_position, variant, color, size) do
    size_config = @size_config[size]
    base_classes = "#{size_config[:decorator_padding]} flex items-center justify-center #{size_config[:decorator_text]}"

    color_classes = get_decorator_color_classes(variant, color)

    merge([base_classes, color_classes])
  end

  defp get_decorator_color_classes("ghost", _color) do
    @decorator_config["ghost"]["all"]
  end

  defp get_decorator_color_classes(variant, color) do
    @decorator_config[variant][color] || ""
  end
end
