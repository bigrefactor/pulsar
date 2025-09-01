defmodule Pulsar.Components.Textarea do
  @moduledoc """
  Styled textarea component built on Stellar.Components.Textarea with auto-resize and character counting.

  Provides beautiful, accessible textarea fields with automatic height adjustment and character count display.
  All styling is applied via Tailwind CSS utilities with semantic color tokens supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible textarea component
  - **Auto-resize**: Optional automatic height adjustment as content grows
  - **Character Counting**: Visual character count with theme-colored display
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl with appropriate min/max heights
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar textarea props are supported

  ## Examples

      # Basic textarea
      <.textarea field={@form[:description]} />

      # With auto-resize and character counting
      <.textarea 
        field={@form[:comment]} 
        auto_resize 
        character_count 
        max_length={500}
        placeholder="Share your thoughts..."
      />

      # Large textarea with custom styling
      <.textarea 
        field={@form[:bio]} 
        variant="outline" 
        color="primary" 
        size="lg"
        auto_resize
        character_count
        max_length={1000}
      />

      # Solid variant with custom constraints
      <.textarea
        field={@form[:review]}
        variant="solid"
        color="success"
        size="md"
        min_height="120px"
        max_height="300px"
        auto_resize
        character_count
        max_length={800}
      />

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback across all textareas.

  ## Stellar Integration

  This component wraps Stellar.Components.Textarea and passes through all its props:
  - Multi-line text input with rows/cols configuration
  - Phoenix form integration with automatic error detection
  - Character counting with data attributes
  - Auto-resize functionality
  - Accessibility features and ARIA attributes
  - Validation error handling with `aria-describedby`
  - All standard HTML attributes

  ## Character Count Display

  When `character_count` is enabled, a visual character counter appears below the textarea
  with theme-appropriate colors:
  - Normal state: muted text color
  - Near limit (≤10%): warning color
  - At/over limit: danger color

  ## Auto-resize Behavior

  When `auto_resize` is enabled, the textarea automatically adjusts its height based on content:
  - Smooth CSS transitions for height changes
  - Configurable min/max height constraints
  - Starts from the specified `rows` value
  - Grows and shrinks as content changes
  """

  use Phoenix.Component
  alias Stellar.Components.Textarea, as: StellarTextarea

  import TailwindMerge, only: [merge: 1]

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(outline ghost solid),
    doc: "Visual style variant of the textarea"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the textarea (overridden by error state)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the textarea"

  # Height constraints for auto-resize
  attr :min_height, :string,
    default: nil,
    doc: "Minimum height (CSS value like '80px' or '5rem')"

  attr :max_height, :string,
    default: nil,
    doc: "Maximum height (CSS value like '300px' or '20rem')"

  # Stellar textarea attributes - copied from Stellar.Components.Textarea
  attr :field, Phoenix.HTML.FormField, default: nil, doc: "Phoenix form field"

  # Core attributes
  attr :id, :string, doc: "Textarea ID (auto-generated if not provided)"

  attr :name, :string, doc: "Textarea name (from field if not provided)"

  attr :value, :any, doc: "Textarea value (from field if not provided)"

  # Textarea-specific attributes
  attr :rows, :integer, default: 4, doc: "Number of visible text lines"
  attr :cols, :integer, default: nil, doc: "Visible width in characters"
  attr :wrap, :string, default: nil, doc: "Text wrapping behavior"
  attr :placeholder, :string, default: nil, doc: "Placeholder text"

  # Length constraints
  attr :maxlength, :integer, default: nil, doc: "Maximum number of characters allowed"
  attr :minlength, :integer, default: nil, doc: "Minimum number of characters required"

  # State attributes
  attr :required, :boolean,
    default: false,
    doc: "Mark textarea as required"

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the textarea"

  attr :readonly, :boolean,
    default: false,
    doc: "Make textarea read-only"

  attr :invalid, :boolean,
    default: false,
    doc: "Mark textarea as invalid (overridden by form field errors)"

  # Feature flags
  attr :auto_resize, :boolean, default: false, doc: "Enable automatic height adjustment"
  attr :character_count, :boolean, default: false, doc: "Enable character counting"

  attr :max_length, :integer,
    default: nil,
    doc: "Maximum characters for display counting (different from maxlength)"

  # Styling
  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  # Global attributes (allows all Phoenix and HTML attributes)
  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders a styled textarea component with optional auto-resize and character counting.

  This function wraps Stellar.Components.Textarea with Pulsar's styling system
  and adds visual character counting display. All Stellar props are passed 
  through, with styling automatically determined by variant and error state.

  Error states automatically apply danger styling when using Phoenix forms.
  """
  def textarea(assigns) do
    # Validate required attributes
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Textarea component requires either :field or :name attribute"
    end

    # Detect errors and compute automatic color
    has_errors =
      case assigns[:field] do
        %Phoenix.HTML.FormField{errors: errs} when errs != [] -> true
        _ -> false
      end

    # Use explicit invalid prop if provided, otherwise use has_errors
    is_invalid = assigns[:invalid] || has_errors

    effective_color = if is_invalid, do: "danger", else: assigns.color

    class =
      merge([
        get_classes(assigns.variant, effective_color, assigns.size),
        get_state_classes(assigns.disabled, assigns.readonly),
        get_height_constraints(assigns.size, assigns.min_height, assigns.max_height),
        assigns.class
      ])

    assigns =
      assigns
      |> normalize_field_attributes()
      |> assign(:class, class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, is_invalid)
      |> assign(:required_attr, assigns.required)
      |> assign_character_counts()

    ~H"""
    <div class="space-y-2">
      <StellarTextarea.textarea
        class={@class}
        field={@field}
        id={@id}
        name={@name}
        value={@value}
        rows={@rows}
        cols={@cols}
        wrap={@wrap}
        placeholder={@placeholder}
        maxlength={@maxlength}
        minlength={@minlength}
        required={@required}
        disabled={@disabled}
        readonly={@readonly}
        auto_resize={@auto_resize}
        character_count={@data_character_count}
        max_length={@data_max_length}
        style={build_custom_height_styles(@min_height, @max_height)}
        data-variant={@variant}
        data-size={@size}
        data-color={@effective_color}
        data-invalid={@invalid}
        data-required={@required_attr}
        aria-invalid={@invalid}
        {@rest}
      />

      <.character_count_display
        :if={@character_count and @data_character_count != nil}
        color={@effective_color}
        character_count={@data_character_count}
        max_length={@data_max_length}
        chars_remaining={@data_chars_remaining}
        over_limit={@data_over_limit}
      />
    </div>
    """
  end

  # Character count display component
  attr :color, :string, required: true
  attr :character_count, :integer, required: true
  attr :max_length, :integer, default: nil
  attr :chars_remaining, :integer, default: nil
  attr :over_limit, :boolean, default: false

  defp character_count_display(assigns) do
    count_color_class =
      get_character_count_color_class(assigns.chars_remaining, assigns.over_limit, assigns.color)

    assigns = assign(assigns, :count_color_class, count_color_class)

    ~H"""
    <div class="flex justify-between items-center text-sm" aria-hidden="true">
      <div class={@count_color_class}>
        {@character_count}{if @max_length != nil, do: "/#{@max_length}"}
        <span :if={@over_limit and @chars_remaining != nil}>
          ({abs(@chars_remaining)} over)
        </span>
      </div>
      <div :if={@max_length != nil and @chars_remaining != nil and @chars_remaining <= (@max_length * 0.1) and @chars_remaining > 0} class="text-warning dark:text-dark-warning">
        {@chars_remaining} remaining
      </div>
    </div>
    """
  end

  # Get character count display color based on state
  defp get_character_count_color_class(remaining, over_limit, _color) do
    cond do
      over_limit -> "text-danger dark:text-dark-danger font-medium"
      remaining && remaining == 0 -> "text-danger dark:text-dark-danger font-medium"
      remaining && remaining <= 10 -> "text-warning dark:text-dark-warning font-medium"
      true -> "text-muted-foreground dark:text-dark-muted-foreground"
    end
  end

  # Normalize field attributes to ensure id, name, value are always present
  defp normalize_field_attributes(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
  end

  defp normalize_field_attributes(assigns) do
    assigns
    |> assign_new(:id, fn -> assigns[:id] || assigns[:name] end)
    |> assign_new(:name, fn -> assigns[:name] end)
    |> assign_new(:value, fn -> assigns[:value] end)
  end

  # Build custom height styles for min/max constraints
  defp build_custom_height_styles(min_height, max_height) do
    styles = []
    styles = if min_height, do: ["min-height: #{min_height}" | styles], else: styles
    styles = if max_height, do: ["max-height: #{max_height}" | styles], else: styles

    case styles do
      [] -> nil
      styles -> Enum.join(styles, "; ") <> ";"
    end
  end

  # Modular styling system supporting all variants and colors
  defp get_classes(variant, color, size) do
    merge([
      base_textarea_classes(),
      variant_classes(variant),
      color_classes(variant, color),
      get_size_classes(size)
    ])
  end

  # Base styles shared by all textarea variants
  defp base_textarea_classes do
    "w-full transition-all duration-200 ease-in-out focus:ring-2 focus:ring-offset-2 resize-none"
  end

  # Variant-specific layout and structure
  defp variant_classes("outline"), do: "border-2 rounded-lg"
  defp variant_classes("ghost"), do: "rounded-lg border-transparent"
  defp variant_classes("solid"), do: "rounded-lg border-transparent"

  # Color classes by variant - consistent with Input component
  defp color_classes("outline", "neutral"),
    do:
      "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:border-primary/50 dark:hover:border-dark-primary/50"

  defp color_classes("outline", "primary"),
    do:
      "border-primary/60 dark:border-dark-primary/60 bg-background dark:bg-dark-background text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus:ring-primary/60 hover:border-primary dark:hover:border-dark-primary"

  defp color_classes("outline", "secondary"),
    do:
      "border-secondary/60 dark:border-dark-secondary/60 bg-background dark:bg-dark-background text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus:ring-secondary/60 hover:border-secondary dark:hover:border-dark-secondary"

  defp color_classes("outline", "success"),
    do:
      "border-success/60 dark:border-dark-success/60 bg-background dark:bg-dark-background text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus:ring-success/60 hover:border-success dark:hover:border-dark-success"

  defp color_classes("outline", "danger"),
    do:
      "border-danger/60 dark:border-dark-danger/60 bg-background dark:bg-dark-background text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus:ring-danger/60 hover:border-danger dark:hover:border-dark-danger"

  defp color_classes("outline", "warning"),
    do:
      "border-warning/60 dark:border-dark-warning/60 bg-background dark:bg-dark-background text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus:ring-warning/60 hover:border-warning dark:hover:border-dark-warning"

  defp color_classes("outline", "info"),
    do:
      "border-info/60 dark:border-dark-info/60 bg-background dark:bg-dark-background text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus:ring-info/60 hover:border-info dark:hover:border-dark-info"

  defp color_classes("ghost", "neutral"),
    do:
      "bg-transparent text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover"

  defp color_classes("ghost", "primary"),
    do:
      "bg-transparent text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus:ring-primary/60 hover:bg-primary/5 dark:hover:bg-dark-primary/10"

  defp color_classes("ghost", "secondary"),
    do:
      "bg-transparent text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus:ring-secondary/60 hover:bg-secondary/5 dark:hover:bg-dark-secondary/10"

  defp color_classes("ghost", "success"),
    do:
      "bg-transparent text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus:ring-success/60 hover:bg-success/5 dark:hover:bg-dark-success/10"

  defp color_classes("ghost", "danger"),
    do:
      "bg-transparent text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus:ring-danger/60 hover:bg-danger/5 dark:hover:bg-dark-danger/10"

  defp color_classes("ghost", "warning"),
    do:
      "bg-transparent text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus:ring-warning/60 hover:bg-warning/5 dark:hover:bg-dark-warning/10"

  defp color_classes("ghost", "info"),
    do:
      "bg-transparent text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus:ring-info/60 hover:bg-info/5 dark:hover:bg-dark-info/10"

  defp color_classes("solid", "neutral"),
    do:
      "bg-neutral/10 dark:bg-dark-neutral/20 text-neutral dark:text-dark-neutral placeholder:text-neutral/70 dark:placeholder:text-dark-neutral/70 focus:ring-neutral/60 hover:bg-neutral/20 dark:hover:bg-dark-neutral/30"

  defp color_classes("solid", "primary"),
    do:
      "bg-primary/10 dark:bg-dark-primary/20 text-primary dark:text-dark-primary placeholder:text-primary/70 dark:placeholder:text-dark-primary/70 focus:ring-primary/60 hover:bg-primary/20 dark:hover:bg-dark-primary/30"

  defp color_classes("solid", "secondary"),
    do:
      "bg-secondary/10 dark:bg-dark-secondary/20 text-secondary dark:text-dark-secondary placeholder:text-secondary/70 dark:placeholder:text-dark-secondary/70 focus:ring-secondary/60 hover:bg-secondary/20 dark:hover:bg-dark-secondary/30"

  defp color_classes("solid", "success"),
    do:
      "bg-success/10 dark:bg-dark-success/20 text-success dark:text-dark-success placeholder:text-success/70 dark:placeholder:text-dark-success/70 focus:ring-success/60 hover:bg-success/20 dark:hover:bg-dark-success/30"

  defp color_classes("solid", "danger"),
    do:
      "bg-danger/10 dark:bg-dark-danger/20 text-danger dark:text-dark-danger placeholder:text-danger/70 dark:placeholder:text-dark-danger/70 focus:ring-danger/60 hover:bg-danger/20 dark:hover:bg-dark-danger/30"

  defp color_classes("solid", "warning"),
    do:
      "bg-warning/10 dark:bg-dark-warning/20 text-warning dark:text-dark-warning placeholder:text-warning/70 dark:placeholder:text-dark-warning/70 focus:ring-warning/60 hover:bg-warning/20 dark:hover:bg-dark-warning/30"

  defp color_classes("solid", "info"),
    do:
      "bg-info/10 dark:bg-dark-info/20 text-info dark:text-dark-info placeholder:text-info/70 dark:placeholder:text-dark-info/70 focus:ring-info/60 hover:bg-info/20 dark:hover:bg-dark-info/30"

  # Size-specific classes with appropriate min heights for textarea
  defp get_size_classes("xs"), do: "min-h-16 text-xs px-2 py-1"
  defp get_size_classes("sm"), do: "min-h-20 text-sm px-2 py-1"
  defp get_size_classes("md"), do: "min-h-24 px-3 py-1.5"
  defp get_size_classes("lg"), do: "min-h-32 text-lg px-4 py-2"
  defp get_size_classes("xl"), do: "min-h-40 text-xl px-4 py-2"

  # Height constraints based on size defaults
  defp get_height_constraints(size, custom_min, custom_max) do
    # Only add default constraints if no custom ones provided
    default_constraints =
      case size do
        "xs" -> "max-h-32"
        "sm" -> "max-h-40"
        "md" -> "max-h-64"
        "lg" -> "max-h-80"
        "xl" -> "max-h-96"
      end

    if custom_min || custom_max do
      # Let CSS style handle custom constraints
      ""
    else
      default_constraints
    end
  end

  defp get_state_classes(disabled, readonly) do
    [
      disabled && "cursor-not-allowed opacity-50 pointer-events-none",
      readonly && "cursor-default"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  defp assign_character_counts(assigns) do
    if assigns.character_count do
      # Get the current value from field or direct value
      current_value =
        case assigns[:field] do
          %Phoenix.HTML.FormField{value: value} -> to_string(value || "")
          _ -> to_string(assigns[:value] || "")
        end

      count = current_value |> String.graphemes() |> length()
      max = assigns.max_length

      # Only calculate remaining and over_limit if we have max_length
      if max do
        remaining = max - count
        over_limit = count > max

        assigns
        |> assign(:data_character_count, count)
        |> assign(:data_max_length, max)
        |> assign(:data_chars_remaining, remaining)
        |> assign(:data_over_limit, over_limit)
      else
        assigns
        |> assign(:data_character_count, count)
        |> assign(:data_max_length, nil)
        |> assign(:data_chars_remaining, nil)
        |> assign(:data_over_limit, false)
      end
    else
      assigns
      |> assign(:data_character_count, nil)
      |> assign(:data_max_length, nil)
      |> assign(:data_chars_remaining, nil)
      |> assign(:data_over_limit, false)
    end
  end
end
