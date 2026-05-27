defmodule Pulsar.Components.Input do
  @moduledoc """
  Self-contained styled input component with decorator support.

  Provides beautiful, accessible input fields with optional start and end decorators
  for icons, text, or interactive elements. All styling is applied via Tailwind CSS
  utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Self-Contained**: No external dependencies beyond Twm
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

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Direct class maps for efficient lookup (no data-attributes needed)
  @input_padding_classes %{
    "lg" => ["px-4", "py-2"],
    "md" => ["px-3", "py-1.5"],
    "sm" => ["px-2", "py-1"],
    "xl" => ["px-4", "py-2"],
    "xs" => ["px-2", "py-1"]
  }

  @container_size_classes %{
    "lg" => ["min-h-12", "text-lg"],
    "md" => ["min-h-10"],
    "sm" => ["min-h-8", "text-sm"],
    "xl" => ["min-h-14", "text-xl"],
    "xs" => ["min-h-6", "text-xs"]
  }

  @decorator_padding_classes %{
    "lg" => ["px-4", "py-2"],
    "md" => ["px-3", "py-1.5"],
    "sm" => ["px-2", "py-1"],
    "xl" => ["px-4", "py-2"],
    "xs" => ["px-2", "py-1"]
  }

  @decorator_text_classes %{
    "lg" => "text-lg",
    "md" => "",
    "sm" => "text-sm",
    "xl" => "text-xl",
    "xs" => "text-xs"
  }

  # Ghost variant padding maps (pre-calculated for all decorator combinations)
  @ghost_padding_no_decorators %{
    "lg" => ["px-4", "py-2"],
    "md" => ["px-3", "py-1.5"],
    "sm" => ["px-2", "py-1"],
    "xl" => ["px-4", "py-2"],
    "xs" => ["px-2", "py-1"]
  }

  @ghost_padding_start_decorator %{
    "lg" => ["pl-0", "pr-4", "py-2"],
    "md" => ["pl-0", "pr-3", "py-1.5"],
    "sm" => ["pl-0", "pr-2", "py-1"],
    "xl" => ["pl-0", "pr-4", "py-2"],
    "xs" => ["pl-0", "pr-2", "py-1"]
  }

  @ghost_padding_end_decorator %{
    "lg" => ["pl-4", "pr-0", "py-2"],
    "md" => ["pl-3", "pr-0", "py-1.5"],
    "sm" => ["pl-2", "pr-0", "py-1"],
    "xl" => ["pl-4", "pr-0", "py-2"],
    "xs" => ["pl-2", "pr-0", "py-1"]
  }

  @ghost_padding_both_decorators %{
    "lg" => ["pl-0", "pr-0", "py-2"],
    "md" => ["pl-0", "pr-0", "py-1.5"],
    "sm" => ["pl-0", "pr-0", "py-1"],
    "xl" => ["pl-0", "pr-0", "py-2"],
    "xs" => ["pl-0", "pr-0", "py-1"]
  }

  # Base input container classes
  @base_input_classes [
    "flex group overflow-hidden transition-all duration-normal ease-standard",
    "focus-within:ring-2 focus-within:ring-offset-2"
  ]

  # Variant base configuration
  @variant_config %{
    "ghost" => "rounded-box",
    "outline" => "border-2 rounded-box",
    "solid" => "rounded-box"
  }

  # Color configuration organized by variant and color
  # Structure: variant -> color -> classes
  @color_config %{
    "ghost" => %{
      "danger" => "bg-transparent text-danger placeholder:text-danger/70 focus-within:ring-danger/60 hover:bg-danger/5",
      "info" => "bg-transparent text-info placeholder:text-info/70 focus-within:ring-info/60 hover:bg-info/5",
      "neutral" => "bg-transparent text-foreground focus-within:ring-ring hover:bg-surface-1-hover",
      "primary" =>
        "bg-transparent text-primary placeholder:text-primary/70 focus-within:ring-primary/60 hover:bg-primary/5",
      "secondary" =>
        "bg-transparent text-secondary placeholder:text-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/5",
      "success" =>
        "bg-transparent text-success placeholder:text-success/70 focus-within:ring-success/60 hover:bg-success/5",
      "warning" =>
        "bg-transparent text-warning placeholder:text-warning/70 focus-within:ring-warning/60 hover:bg-warning/5"
    },
    "outline" => %{
      "danger" =>
        "border-danger/60 bg-background text-danger placeholder:text-danger/70 focus-within:ring-danger/60 hover:border-danger",
      "info" =>
        "border-info/60 bg-background text-info placeholder:text-info/70 focus-within:ring-info/60 hover:border-info",
      "neutral" => "border-border-strong bg-background text-foreground focus-within:ring-ring hover:border-primary/50",
      "primary" =>
        "border-primary/60 bg-background text-primary placeholder:text-primary/70 focus-within:ring-primary/60 hover:border-primary",
      "secondary" =>
        "border-secondary/60 bg-background text-secondary placeholder:text-secondary/70 focus-within:ring-secondary/60 hover:border-secondary",
      "success" =>
        "border-success/60 bg-background text-success placeholder:text-success/70 focus-within:ring-success/60 hover:border-success",
      "warning" =>
        "border-warning/60 bg-background text-warning placeholder:text-warning/70 focus-within:ring-warning/60 hover:border-warning"
    },
    "solid" => %{
      "danger" => "bg-danger/10 text-danger placeholder:text-danger/70 focus-within:ring-danger/60 hover:bg-danger/20",
      "info" => "bg-info/10 text-info placeholder:text-info/70 focus-within:ring-info/60 hover:bg-info/20",
      "neutral" =>
        "bg-neutral/10 text-neutral placeholder:text-neutral/70 focus-within:ring-neutral/60 hover:bg-neutral/20",
      "primary" =>
        "bg-primary/10 text-primary placeholder:text-primary/70 focus-within:ring-primary/60 hover:bg-primary/20",
      "secondary" =>
        "bg-secondary/10 text-secondary placeholder:text-secondary/70 focus-within:ring-secondary/60 hover:bg-secondary/20",
      "success" =>
        "bg-success/10 text-success placeholder:text-success/70 focus-within:ring-success/60 hover:bg-success/20",
      "warning" =>
        "bg-warning/10 text-warning placeholder:text-warning/70 focus-within:ring-warning/60 hover:bg-warning/20"
    }
  }

  # Decorator color configuration
  @decorator_config %{
    "outline" => %{
      "danger" => "bg-danger/60 text-danger-foreground border-danger/60",
      "info" => "bg-info/60 text-info-foreground border-info/60",
      "neutral" => "bg-border text-neutral-700 border-border",
      "primary" => "bg-primary/60 text-primary-foreground border-primary/60",
      "secondary" => "bg-secondary/60 text-secondary-foreground border-secondary/60",
      "success" => "bg-success/60 text-success-foreground border-success/60",
      "warning" => "bg-warning/60 text-warning-foreground border-warning/60"
    },
    "solid" => %{
      "danger" => "bg-danger/20 text-danger border-danger/30",
      "info" => "bg-info/20 text-info border-info/30",
      "neutral" => "bg-neutral/20 text-neutral border-neutral/30",
      "primary" => "bg-primary/20 text-primary border-primary/30",
      "secondary" => "bg-secondary/20 text-secondary border-secondary/30",
      "success" => "bg-success/20 text-success border-success/30",
      "warning" => "bg-warning/20 text-warning border-warning/30"
    },
    "ghost" => %{
      # Ghost decorators are minimal and don't vary by color
      "all" => "text-muted-foreground"
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
    <div class={@class}>
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
            "w-full outline-0 transition-all duration-normal ease-standard",
            get_input_padding_classes(@size, @variant, @has_start_decorator, @has_end_decorator),
            (@disabled && "cursor-not-allowed") || (@readonly && "cursor-default") || nil
          ]
          |> Enum.filter(& &1)
          |> List.flatten()
        }
        type={@type}
        id={@id}
        name={@name}
        {if @type != "file", do: [value: @value], else: []}
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
      get_container_size_classes(size)
    ])
  end

  # Get color classes from configuration
  defp get_color_classes(variant, color) do
    @color_config[variant][color] || ""
  end

  # Get container size classes directly (direct map lookup)
  defp get_container_size_classes(size) do
    @container_size_classes[size] || @container_size_classes["md"]
  end

  defp get_state_classes(disabled, readonly) do
    [
      disabled && "cursor-not-allowed opacity-disabled pointer-events-none",
      readonly && "cursor-default"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Get input element padding classes (direct map lookups, no runtime filtering)
  defp get_input_padding_classes(size, variant, has_start_decorator, has_end_decorator) do
    if variant == "ghost" do
      get_ghost_padding_classes(size, has_start_decorator, has_end_decorator)
    else
      @input_padding_classes[size] || @input_padding_classes["md"]
    end
  end

  # Get ghost variant padding with direct map lookup based on decorator combination
  defp get_ghost_padding_classes(size, has_start_decorator, has_end_decorator) do
    map =
      case {has_start_decorator, has_end_decorator} do
        {false, false} -> @ghost_padding_no_decorators
        {true, false} -> @ghost_padding_start_decorator
        {false, true} -> @ghost_padding_end_decorator
        {true, true} -> @ghost_padding_both_decorators
      end

    map[size] || map["md"]
  end

  # Decorator functions supporting all variants and colors
  defp get_decorator_classes(_position, variant, color, size) do
    base_classes = [
      "flex",
      "items-center",
      "justify-center",
      get_decorator_padding_classes(size),
      get_decorator_text_classes(size)
    ]

    color_classes = get_decorator_color_classes(variant, color)

    merge([base_classes, color_classes])
  end

  # Get decorator padding classes based on size (direct map lookup)
  defp get_decorator_padding_classes(size) do
    @decorator_padding_classes[size] || @decorator_padding_classes["md"]
  end

  # Get decorator text size classes (direct map lookup)
  defp get_decorator_text_classes(size) do
    @decorator_text_classes[size] || @decorator_text_classes["md"]
  end

  defp get_decorator_color_classes("ghost", _color) do
    @decorator_config["ghost"]["all"]
  end

  defp get_decorator_color_classes(variant, color) do
    @decorator_config[variant][color] || ""
  end
end
