defmodule Pulsar.Components.RadioGroup do
  @moduledoc """
  Styled radio group component built on Stellar.Components.RadioGroup.

  Provides beautiful, accessible radio button groups with custom design and card-style
  layouts. All styling is applied via Tailwind CSS utilities with semantic color tokens
  that support both light and dark modes.

  ## Features

  - **Accessible by Default**: Proper radiogroup semantics with keyboard support and roving tabindex
  - **Custom Radio Design**: Styled radio buttons with smooth animations
  - **Card-style Options**: Rich card layouts with descriptions and custom content
    - **Flexible Layouts**: Use the `class` attribute for any layout (flex, grid, etc.)
  - **Size Variants**: xs, sm, md, lg, xl for complete range
  - **Color Variants**: neutral, primary, secondary, success, danger, warning, info for consistent theming
  - **Hover and Focus States**: Smooth interactive feedback
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Phoenix Integration**: Works seamlessly with Phoenix forms and LiveView assigns

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

  ## Phoenix Form Integration

  This component integrates seamlessly with Phoenix forms:
  - `:field` - Phoenix form field integration with automatic validation
  - `:name`, `:value` - Form control attributes
  - `:orientation` - Keyboard navigation direction
  - `:disabled`, `:required`, `:invalid` - Form states
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

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
        id: assigns[:id] || field.id || generate_id("radio-group"),
        name: assigns[:name] || field.name,
        value: assigns[:value] || field.value
      }
    else
      %{
        errors: [],
        id: assigns[:id] || generate_id("radio-group"),
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

  # Size configuration for both radio input and card variants
  @size_config %{
    "lg" => %{
      card_padding: "p-5 gap-4",
      card_text: "text-lg",
      label_text: "text-lg",
      radio: "w-6 h-6",
      radio_before: "before:inset-1.5"
    },
    "md" => %{
      card_padding: "p-4 gap-3",
      card_text: "text-base",
      label_text: "text-base",
      radio: "w-5 h-5",
      radio_before: "before:inset-1"
    },
    "sm" => %{
      card_padding: "p-3 gap-2",
      card_text: "text-sm",
      label_text: "text-sm",
      radio: "w-4 h-4",
      radio_before: "before:inset-0.5"
    },
    "xl" => %{
      card_padding: "p-6 gap-5",
      card_text: "text-xl",
      label_text: "text-xl",
      radio: "w-7 h-7",
      radio_before: "before:inset-1.5"
    },
    "xs" => %{
      card_padding: "p-2 gap-2",
      card_text: "text-xs",
      label_text: "text-xs",
      radio: "w-3 h-3",
      radio_before: "before:inset-0.5"
    }
  }

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

  Renders a native radiogroup with Pulsar's styling system. Styling is controlled
  via CSS classes that respond to the radio group's card and layout state.

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
    # Normalize field properties
    normalized = normalize_field_props(assigns)

    # Detect errors and compute automatic color
    has_errors = not Enum.empty?(normalized.errors)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Build class string for radio group container with incremental approach
    container_class =
      [
        container_base_classes(),
        assigns.class
      ]
      |> Enum.filter(&(&1 != ""))
      |> merge()

    # Create a mock group object with the required properties
    group = %{
      disabled: assigns.disabled,
      id: normalized.id,
      invalid: invalid,
      name: normalized.name,
      required: assigns.required,
      value: normalized.value
    }

    assigns =
      assigns
      |> assign_computed_attributes(normalized)
      |> assign(:container_class, container_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)
      |> assign(:group, group)

    ~H"""
    <div
      role="radiogroup"
      id={@id}
      class={@container_class}
      aria-invalid={@invalid && "true"}
      aria-required={@required && "true"}
      data-name={@name}
      data-invalid={if @invalid, do: "true", else: "false"}
      data-orientation={@orientation}
      data-disabled={if @disabled, do: "true", else: "false"}
      data-required={if @required, do: "true", else: "false"}
      {if !@card, do: @rest, else: []}
    >
      <%= for {option, index} <- Enum.with_index(@option) do %>
        {render_radio_option(assigns, option, @group, index)}
      <% end %>
    </div>
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
      class={@container_class}
      data-checked={(@option_checked && "true") || "false"}
      data-disabled={(@option_disabled && "true") || "false"}
      data-state={if @option_checked, do: "checked", else: "unchecked"}
      {@rest}
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

  # ============================================================================
  # RADIO COLOR CONFIGURATION
  # ============================================================================
  #
  # Map-based color system for radio buttons. Each color defines its border,
  # background, focus ring, and foreground (inner dot) classes.
  # This approach maintains PurgeCSS compatibility while reducing repetition.
  # ============================================================================

  @radio_color_config %{
    "danger" => %{
      background: "bg-background dark:bg-dark-background checked:bg-danger dark:checked:bg-dark-danger",
      border: "border-border dark:border-dark-border checked:border-danger dark:checked:border-dark-danger",
      foreground: "before:bg-danger-foreground dark:before:bg-dark-danger-foreground",
      hover: "hover:border-danger/70 dark:hover:border-dark-danger/70 hover:shadow-sm",
      ring: "focus-visible:ring-danger dark:focus-visible:ring-dark-danger"
    },
    "info" => %{
      background: "bg-background dark:bg-dark-background checked:bg-info dark:checked:bg-dark-info",
      border: "border-border dark:border-dark-border checked:border-info dark:checked:border-dark-info",
      foreground: "before:bg-info-foreground dark:before:bg-dark-info-foreground",
      hover: "hover:border-info/70 dark:hover:border-dark-info/70 hover:shadow-sm",
      ring: "focus-visible:ring-info dark:focus-visible:ring-dark-info"
    },
    "neutral" => %{
      background: "bg-background dark:bg-dark-background checked:bg-neutral dark:checked:bg-dark-neutral",
      border: "border-border dark:border-dark-border checked:border-neutral dark:checked:border-dark-neutral",
      foreground: "before:bg-neutral-foreground dark:before:bg-dark-neutral-foreground",
      hover: "hover:border-neutral/70 dark:hover:border-dark-neutral/70 hover:shadow-sm",
      ring: "focus-visible:ring-neutral dark:focus-visible:ring-dark-neutral"
    },
    "primary" => %{
      background: "bg-background dark:bg-dark-background checked:bg-primary dark:checked:bg-dark-primary",
      border: "border-border dark:border-dark-border checked:border-primary dark:checked:border-dark-primary",
      foreground: "before:bg-primary-foreground dark:before:bg-dark-primary-foreground",
      hover: "hover:border-primary/70 dark:hover:border-dark-primary/70 hover:shadow-sm",
      ring: "focus-visible:ring-primary dark:focus-visible:ring-dark-primary"
    },
    "secondary" => %{
      background: "bg-background dark:bg-dark-background checked:bg-secondary dark:checked:bg-dark-secondary",
      border: "border-border dark:border-dark-border checked:border-secondary dark:checked:border-dark-secondary",
      foreground: "before:bg-secondary-foreground dark:before:bg-dark-secondary-foreground",
      hover: "hover:border-secondary/70 dark:hover:border-dark-secondary/70 hover:shadow-sm",
      ring: "focus-visible:ring-secondary dark:focus-visible:ring-dark-secondary"
    },
    "success" => %{
      background: "bg-background dark:bg-dark-background checked:bg-success dark:checked:bg-dark-success",
      border: "border-border dark:border-dark-border checked:border-success dark:checked:border-dark-success",
      foreground: "before:bg-success-foreground dark:before:bg-dark-success-foreground",
      hover: "hover:border-success/70 dark:hover:border-dark-success/70 hover:shadow-sm",
      ring: "focus-visible:ring-success dark:focus-visible:ring-dark-success"
    },
    "warning" => %{
      background: "bg-background dark:bg-dark-background checked:bg-warning dark:checked:bg-dark-warning",
      border: "border-border dark:border-dark-border checked:border-warning dark:checked:border-dark-warning",
      foreground: "before:bg-warning-foreground dark:before:bg-dark-warning-foreground",
      hover: "hover:border-warning/70 dark:hover:border-dark-warning/70 hover:shadow-sm",
      ring: "focus-visible:ring-warning dark:focus-visible:ring-dark-warning"
    }
  }

  @radio_label_color_config %{
    "danger" => "text-danger dark:text-dark-danger",
    "info" => "text-info dark:text-dark-info",
    "neutral" => "text-foreground dark:text-dark-foreground",
    "primary" => "text-primary dark:text-dark-primary",
    "secondary" => "text-secondary dark:text-dark-secondary",
    "success" => "text-success dark:text-dark-success",
    "warning" => "text-warning dark:text-dark-warning"
  }

  # Radio color classes - uses map lookup instead of pattern matching
  @spec radio_color_classes(String.t()) :: String.t()
  defp radio_color_classes(color) do
    config = @radio_color_config[color]

    [
      config.border,
      config.background,
      config.ring,
      config.foreground,
      config.hover
    ]
    |> merge()
  end

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
      @size_config[size][:radio],
      @size_config[size][:radio_before],
      radio_color_classes(color)
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

  # Classes for radio labels (standard non-card)
  @spec radio_label_classes(String.t(), String.t(), String.t()) :: String.t()
  defp radio_label_classes(size, color, label_color) do
    base_classes = "cursor-pointer select-none transition-all duration-200 flex-1 min-w-0"
    effective_label_color = if label_color == "inherit", do: color, else: "neutral"

    [
      base_classes,
      @size_config[size][:label_text],
      radio_label_color_classes(effective_label_color)
    ]
    |> merge()
  end

  # Color classes for radio labels - uses map lookup
  @spec radio_label_color_classes(String.t()) :: String.t()
  defp radio_label_color_classes(color) do
    @radio_label_color_config[color] || @radio_label_color_config["neutral"]
  end

  # Card base styles (without CSS variables)
  @spec card_base_classes(String.t(), String.t()) :: String.t()
  defp card_base_classes(color, size) do
    [
      "relative flex items-start rounded-lg border-2",
      "cursor-pointer transition-all duration-200 ease-in-out",
      "focus-within:ring-2 focus-within:ring-offset-2",
      @size_config[size][:card_padding],
      @size_config[size][:card_text],
      card_focus_ring_classes(color)
    ]
    |> merge()
  end

  # ============================================================================
  # CARD COLOR CONFIGURATION
  # ============================================================================
  #
  # Map-based color system for card variants. Each color defines focus ring
  # and variant-specific styling classes.
  # ============================================================================

  @card_color_config %{
    "danger" => %{
      focus_ring: "focus-within:ring-danger dark:focus-within:ring-dark-danger"
    },
    "info" => %{
      focus_ring: "focus-within:ring-info dark:focus-within:ring-dark-info"
    },
    "neutral" => %{
      focus_ring: "focus-within:ring-neutral dark:focus-within:ring-dark-neutral"
    },
    "primary" => %{
      focus_ring: "focus-within:ring-primary dark:focus-within:ring-dark-primary"
    },
    "secondary" => %{
      focus_ring: "focus-within:ring-secondary dark:focus-within:ring-dark-secondary"
    },
    "success" => %{
      focus_ring: "focus-within:ring-success dark:focus-within:ring-dark-success"
    },
    "warning" => %{
      focus_ring: "focus-within:ring-warning dark:focus-within:ring-dark-warning"
    }
  }

  # Card focus ring classes by color - uses map lookup
  @spec card_focus_ring_classes(String.t()) :: String.t()
  defp card_focus_ring_classes(color) do
    @card_color_config[color][:focus_ring] || @card_color_config["neutral"][:focus_ring]
  end

  # ============================================================================
  # CARD VARIANT CONFIGURATION
  # ============================================================================
  #
  # Map-based card variant system. Each variant/color combination defines
  # background, border, hover, and checked state classes.
  # ============================================================================

  @card_variant_config %{
    "ghost" => %{
      "danger" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-danger/15 dark:has-[:checked]:bg-dark-danger/15",
        hover: "hover:bg-danger/10 dark:hover:bg-dark-danger/10"
      },
      "info" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-info/15 dark:has-[:checked]:bg-dark-info/15",
        hover: "hover:bg-info/10 dark:hover:bg-dark-info/10"
      },
      "neutral" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-neutral/15 dark:has-[:checked]:bg-dark-neutral/15",
        hover: "hover:bg-neutral/10 dark:hover:bg-dark-neutral/10"
      },
      "primary" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-primary/15 dark:has-[:checked]:bg-dark-primary/15",
        hover: "hover:bg-primary/10 dark:hover:bg-dark-primary/10"
      },
      "secondary" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-secondary/15 dark:has-[:checked]:bg-dark-secondary/15",
        hover: "hover:bg-secondary/10 dark:hover:bg-dark-secondary/10"
      },
      "success" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-success/15 dark:has-[:checked]:bg-dark-success/15",
        hover: "hover:bg-success/10 dark:hover:bg-dark-success/10"
      },
      "warning" => %{
        base: "border-transparent bg-transparent",
        checked: "has-[:checked]:bg-warning/15 dark:has-[:checked]:bg-dark-warning/15",
        hover: "hover:bg-warning/10 dark:hover:bg-dark-warning/10"
      }
    },
    "outline" => %{
      "danger" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-danger dark:has-[:checked]:border-dark-danger has-[:checked]:bg-danger/10 dark:has-[:checked]:bg-dark-danger/10",
        hover: "hover:border-danger/50 dark:hover:border-dark-danger/50 hover:bg-danger/5 dark:hover:bg-dark-danger/5"
      },
      "info" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-info dark:has-[:checked]:border-dark-info has-[:checked]:bg-info/10 dark:has-[:checked]:bg-dark-info/10",
        hover: "hover:border-info/50 dark:hover:border-dark-info/50 hover:bg-info/5 dark:hover:bg-dark-info/5"
      },
      "neutral" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-neutral dark:has-[:checked]:border-dark-neutral has-[:checked]:bg-neutral/10 dark:has-[:checked]:bg-dark-neutral/10",
        hover:
          "hover:border-neutral/50 dark:hover:border-dark-neutral/50 hover:bg-neutral/5 dark:hover:bg-dark-neutral/5"
      },
      "primary" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-primary dark:has-[:checked]:border-dark-primary has-[:checked]:bg-primary/10 dark:has-[:checked]:bg-dark-primary/10",
        hover:
          "hover:border-primary/50 dark:hover:border-dark-primary/50 hover:bg-primary/5 dark:hover:bg-dark-primary/5"
      },
      "secondary" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-secondary dark:has-[:checked]:border-dark-secondary has-[:checked]:bg-secondary/10 dark:has-[:checked]:bg-dark-secondary/10",
        hover:
          "hover:border-secondary/50 dark:hover:border-dark-secondary/50 hover:bg-secondary/5 dark:hover:bg-dark-secondary/5"
      },
      "success" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-success dark:has-[:checked]:border-dark-success has-[:checked]:bg-success/10 dark:has-[:checked]:bg-dark-success/10",
        hover:
          "hover:border-success/50 dark:hover:border-dark-success/50 hover:bg-success/5 dark:hover:bg-dark-success/5"
      },
      "warning" => %{
        background: "bg-background dark:bg-dark-background",
        base: "",
        border: "border-border dark:border-dark-border",
        checked:
          "has-[:checked]:border-warning dark:has-[:checked]:border-dark-warning has-[:checked]:bg-warning/10 dark:has-[:checked]:bg-dark-warning/10",
        hover:
          "hover:border-warning/50 dark:hover:border-dark-warning/50 hover:bg-warning/5 dark:hover:bg-dark-warning/5"
      }
    },
    "solid" => %{
      "danger" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-danger/20 dark:has-[:checked]:bg-dark-danger/20",
        hover: "hover:bg-danger/10 dark:hover:bg-dark-danger/10"
      },
      "info" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-info/20 dark:has-[:checked]:bg-dark-info/20",
        hover: "hover:bg-info/10 dark:hover:bg-dark-info/10"
      },
      "neutral" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-neutral/20 dark:has-[:checked]:bg-dark-neutral/20",
        hover: "hover:bg-neutral/10 dark:hover:bg-dark-neutral/10"
      },
      "primary" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-primary/20 dark:has-[:checked]:bg-dark-primary/20",
        hover: "hover:bg-primary/10 dark:hover:bg-dark-primary/10"
      },
      "secondary" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-secondary/20 dark:has-[:checked]:bg-dark-secondary/20",
        hover: "hover:bg-secondary/10 dark:hover:bg-dark-secondary/10"
      },
      "success" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-success/20 dark:has-[:checked]:bg-dark-success/20",
        hover: "hover:bg-success/10 dark:hover:bg-dark-success/10"
      },
      "warning" => %{
        background: "bg-background dark:bg-dark-background",
        base: "border-transparent",
        checked: "has-[:checked]:bg-warning/20 dark:has-[:checked]:bg-dark-warning/20",
        hover: "hover:bg-warning/10 dark:hover:bg-dark-warning/10"
      }
    }
  }

  # Card variant classes using map lookup
  @spec card_variant_classes(String.t(), String.t()) :: String.t()
  defp card_variant_classes(variant, color) do
    config = @card_variant_config[variant][color]

    if config do
      [
        config[:base],
        config[:background],
        config[:border],
        config[:hover],
        config[:checked]
      ]
      |> merge()
    else
      ""
    end
  end

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
end
