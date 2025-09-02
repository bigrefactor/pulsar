defmodule Pulsar.Components.Select do
  @moduledoc """
  Styled select component built on Stellar.Components.Select with consistent theming.

  Provides beautiful, accessible select fields with optional multi-select badge display.
  All styling is applied via Tailwind CSS utilities with semantic color tokens 
  supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible select component
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button and input components
  - **Multi-Select Badges**: Display selected options as removable badges
  - **Custom Arrow**: Styled dropdown arrow matching theme colors
  - **Option Groups**: Consistent styling for grouped options
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar select props are supported

  ## Examples

      # Basic select
      <.select field={@form[:country]} options={@countries} />

      # With variant and color
      <.select field={@form[:priority]} options={@priorities} variant="outline" color="primary" />

      # Multi-select with badges
      <.select field={@form[:skills]} options={@skills} multiple />

      # Select with option groups
      <.select
        field={@form[:location]}
        options={[
          "North America": [{"United States", "US"}, {"Canada", "CA"}],
          "Europe": [{"United Kingdom", "UK"}, {"Germany", "DE"}]
        ]}
      />

      # Different sizes
      <.select field={@form[:size]} options={@sizes} size="lg" />

      # Without Phoenix form
      <.select name="category" options={["Tech", "Design", "Marketing"]} value="Tech" />

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback across all selects.

  ## Stellar Integration

  This component wraps Stellar.Components.Select and passes through all its props:
  - Native HTML select element for optimal accessibility and mobile support
  - Single and multi-select modes
  - Phoenix options integration with all standard formats
  - Phoenix form integration with automatic error detection
  - ARIA support and validation state management
  - All standard HTML attributes

  ## Multi-Select Badges

  When using multi-select mode, selected options are displayed as badges above
  the select element with individual remove buttons for better UX.
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered
  alias Stellar.Components.Select, as: StellarSelect

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(outline ghost solid),
    doc: "Visual style variant of the select"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the select (overridden by error state)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the select"

  # Stellar select attributes - copied from Stellar.Components.Select
  attr :field, FormField, default: nil, doc: "Phoenix form field"

  # Core attributes
  attr :name, :string,
    default: nil,
    doc: "Select name (from field if not provided)"

  attr :value, :any,
    default: nil,
    doc: "Selected value(s) (from field if not provided)"

  attr :options, :list, required: true, doc: "List of options in Phoenix format"

  # Select-specific attributes
  attr :multiple, :boolean, default: false, doc: "Enable multi-select mode"
  attr :prompt, :string, default: nil, doc: "Prompt option text"
  attr :auto_name_array, :boolean, default: true, doc: "Auto-append [] to name for multi-select"

  # State attributes
  attr :required, :boolean,
    default: false,
    doc: "Mark select as required"

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the select"

  # State override (optional)
  attr :invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"

  # Styling
  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  # Global attributes (allows all Phoenix and HTML attributes)
  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders a styled select component with optional multi-select badges.

  This function wraps Stellar.Components.Select with Pulsar's styling system.
  All Stellar props are passed through, with styling automatically determined 
  by variant and error state.

  Error states automatically apply danger styling when using Phoenix forms.
  Multi-select mode displays selected options as removable badges.
  """
  @spec select(map()) :: Rendered.t()
  def select(assigns) do
    # Validate required attributes
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError, "Select component requires :name when :field is not provided"
    end

    # Detect errors and compute automatic color
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # For multi-select, extract selected values for badge display
    selected_options =
      if assigns.multiple do
        extract_selected_options(assigns.value, assigns.options)
      else
        []
      end

    class =
      merge([
        get_select_classes(assigns.variant, effective_color, assigns.size),
        get_state_classes(assigns.disabled),
        assigns.class
      ])

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)
      |> assign(:selected_options, selected_options)
      |> assign(:show_badges, assigns.multiple and not Enum.empty?(selected_options))

    ~H"""
    <div class="space-y-2">
      <!-- Multi-select badges -->
      <div :if={@show_badges} class="flex flex-wrap gap-2">
        <.badge
          :for={option <- @selected_options}
          variant="solid"
          color={@effective_color}
          size={get_badge_size(@size)}
          removable
          phx-click={@rest[:"phx-click-badge"] || "remove_selection"}
          phx-value-option={option.value}
        >
          {option.label}
        </.badge>
      </div>
      
    <!-- Select wrapper with custom arrow -->
      <div class="relative">
        <StellarSelect.select
          class={
            [
              @class,
              # Custom arrow positioning
              "pr-10"
            ]
          }
          field={@field}
          name={@name}
          value={@value}
          options={@options}
          multiple={@multiple}
          prompt={@prompt}
          auto_name_array={@auto_name_array}
          required={@required}
          disabled={@disabled}
          aria-invalid={if @invalid, do: "true", else: "false"}
          {@rest}
        />
        
    <!-- Custom arrow icon -->
        <div class={[
          "absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none",
          get_arrow_classes(@variant, @effective_color),
          @disabled && "opacity-50"
        ]}>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </div>
    </div>
    """
  end

  # Badge component for multi-select display
  attr :variant, :string, default: "solid"
  attr :color, :string, default: "neutral"
  attr :size, :string, default: "sm"
  attr :removable, :boolean, default: false
  attr :class, :string, default: ""
  attr :rest, :global
  slot :inner_block, required: true

  defp badge(assigns) do
    class =
      merge([
        get_badge_classes(assigns.variant, assigns.color, assigns.size),
        assigns.class
      ])

    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class} {@rest}>
      {render_slot(@inner_block)}
      <button
        :if={@removable}
        type="button"
        class="ml-1.5 -mr-1 hover:bg-black hover:bg-opacity-10 rounded-full p-0.5 focus:outline-none focus:ring-1 focus:ring-current"
        aria-label="Remove"
      >
        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        </svg>
      </button>
    </span>
    """
  end

  # Modular styling system supporting all variants and colors
  defp get_select_classes(variant, color, size) do
    merge([
      base_select_classes(),
      variant_classes(variant),
      color_classes(variant, color),
      get_size_classes(size)
    ])
  end

  # Base styles shared by all select variants
  defp base_select_classes do
    "block w-full appearance-none transition-all duration-200 ease-in-out focus:ring-2 focus:ring-offset-2 focus:outline-none"
  end

  # Variant-specific layout and structure
  defp variant_classes("outline"), do: "border-2 rounded-lg"
  defp variant_classes("ghost"), do: "rounded-lg border-0"
  defp variant_classes("solid"), do: "rounded-lg border-0"

  # Color classes by variant - matching Input component patterns
  defp color_classes("outline", "neutral"),
    do:
      "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:border-primary/50 dark:hover:border-dark-primary/50"

  defp color_classes("outline", "primary"),
    do:
      "border-primary/60 dark:border-dark-primary/60 bg-background dark:bg-dark-background text-primary dark:text-dark-primary focus:ring-primary/60 hover:border-primary dark:hover:border-dark-primary"

  defp color_classes("outline", "secondary"),
    do:
      "border-secondary/60 dark:border-dark-secondary/60 bg-background dark:bg-dark-background text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:border-secondary dark:hover:border-dark-secondary"

  defp color_classes("outline", "success"),
    do:
      "border-success/60 dark:border-dark-success/60 bg-background dark:bg-dark-background text-success dark:text-dark-success focus:ring-success/60 hover:border-success dark:hover:border-dark-success"

  defp color_classes("outline", "danger"),
    do:
      "border-danger/60 dark:border-dark-danger/60 bg-background dark:bg-dark-background text-danger dark:text-dark-danger focus:ring-danger/60 hover:border-danger dark:hover:border-dark-danger"

  defp color_classes("outline", "warning"),
    do:
      "border-warning/60 dark:border-dark-warning/60 bg-background dark:bg-dark-background text-warning dark:text-dark-warning focus:ring-warning/60 hover:border-warning dark:hover:border-dark-warning"

  defp color_classes("outline", "info"),
    do:
      "border-info/60 dark:border-dark-info/60 bg-background dark:bg-dark-background text-info dark:text-dark-info focus:ring-info/60 hover:border-info dark:hover:border-dark-info"

  defp color_classes("ghost", "neutral"),
    do:
      "bg-transparent text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover"

  defp color_classes("ghost", "primary"),
    do:
      "bg-transparent text-primary dark:text-dark-primary focus:ring-primary/60 hover:bg-primary/5 dark:hover:bg-dark-primary/10"

  defp color_classes("ghost", "secondary"),
    do:
      "bg-transparent text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:bg-secondary/5 dark:hover:bg-dark-secondary/10"

  defp color_classes("ghost", "success"),
    do:
      "bg-transparent text-success dark:text-dark-success focus:ring-success/60 hover:bg-success/5 dark:hover:bg-dark-success/10"

  defp color_classes("ghost", "danger"),
    do:
      "bg-transparent text-danger dark:text-dark-danger focus:ring-danger/60 hover:bg-danger/5 dark:hover:bg-dark-danger/10"

  defp color_classes("ghost", "warning"),
    do:
      "bg-transparent text-warning dark:text-dark-warning focus:ring-warning/60 hover:bg-warning/5 dark:hover:bg-dark-warning/10"

  defp color_classes("ghost", "info"),
    do: "bg-transparent text-info dark:text-dark-info focus:ring-info/60 hover:bg-info/5 dark:hover:bg-dark-info/10"

  defp color_classes("solid", "neutral"),
    do:
      "bg-neutral/10 dark:bg-dark-neutral/20 text-neutral dark:text-dark-neutral focus:ring-neutral/60 hover:bg-neutral/20 dark:hover:bg-dark-neutral/30"

  defp color_classes("solid", "primary"),
    do:
      "bg-primary/10 dark:bg-dark-primary/20 text-primary dark:text-dark-primary focus:ring-primary/60 hover:bg-primary/20 dark:hover:bg-dark-primary/30"

  defp color_classes("solid", "secondary"),
    do:
      "bg-secondary/10 dark:bg-dark-secondary/20 text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:bg-secondary/20 dark:hover:bg-dark-secondary/30"

  defp color_classes("solid", "success"),
    do:
      "bg-success/10 dark:bg-dark-success/20 text-success dark:text-dark-success focus:ring-success/60 hover:bg-success/20 dark:hover:bg-dark-success/30"

  defp color_classes("solid", "danger"),
    do:
      "bg-danger/10 dark:bg-dark-danger/20 text-danger dark:text-dark-danger focus:ring-danger/60 hover:bg-danger/20 dark:hover:bg-dark-danger/30"

  defp color_classes("solid", "warning"),
    do:
      "bg-warning/10 dark:bg-dark-warning/20 text-warning dark:text-dark-warning focus:ring-warning/60 hover:bg-warning/20 dark:hover:bg-dark-warning/30"

  defp color_classes("solid", "info"),
    do:
      "bg-info/10 dark:bg-dark-info/20 text-info dark:text-dark-info focus:ring-info/60 hover:bg-info/20 dark:hover:bg-dark-info/30"

  # Helper functions for reusable parts
  defp get_size_classes("xs"), do: "min-h-6 text-xs px-2 py-1"
  defp get_size_classes("sm"), do: "min-h-8 text-sm px-2 py-1"
  defp get_size_classes("md"), do: "min-h-10 px-3 py-1.5"
  defp get_size_classes("lg"), do: "min-h-12 text-lg px-4 py-2"
  defp get_size_classes("xl"), do: "min-h-14 text-xl px-4 py-2"

  defp get_state_classes(disabled) do
    [
      disabled && "cursor-not-allowed opacity-50 pointer-events-none"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Custom arrow styling
  defp get_arrow_classes("outline", color), do: get_arrow_color_classes(color)
  defp get_arrow_classes("ghost", color), do: get_arrow_color_classes(color)
  defp get_arrow_classes("solid", color), do: get_arrow_color_classes(color)

  defp get_arrow_color_classes("neutral"), do: "text-neutral dark:text-dark-neutral"
  defp get_arrow_color_classes("primary"), do: "text-primary dark:text-dark-primary"
  defp get_arrow_color_classes("secondary"), do: "text-secondary dark:text-dark-secondary"
  defp get_arrow_color_classes("success"), do: "text-success dark:text-dark-success"
  defp get_arrow_color_classes("danger"), do: "text-danger dark:text-dark-danger"
  defp get_arrow_color_classes("warning"), do: "text-warning dark:text-dark-warning"
  defp get_arrow_color_classes("info"), do: "text-info dark:text-dark-info"

  # Badge styling
  defp get_badge_classes(variant, color, size) do
    merge([
      base_badge_classes(size),
      badge_variant_classes(variant),
      badge_color_classes(variant, color)
    ])
  end

  defp base_badge_classes("xs"), do: "inline-flex items-center text-xs font-medium rounded-md"
  defp base_badge_classes("sm"), do: "inline-flex items-center text-sm font-medium rounded-md"
  defp base_badge_classes("md"), do: "inline-flex items-center text-sm font-medium rounded-lg"
  defp base_badge_classes("lg"), do: "inline-flex items-center text-base font-medium rounded-lg"
  defp base_badge_classes("xl"), do: "inline-flex items-center text-lg font-medium rounded-lg"

  defp badge_variant_classes("solid"), do: "px-2.5 py-0.5"
  defp badge_variant_classes("outline"), do: "px-2.5 py-0.5 border"
  defp badge_variant_classes("ghost"), do: "px-2.5 py-0.5"

  defp badge_color_classes("solid", "neutral"),
    do: "bg-neutral text-neutral-foreground dark:bg-dark-neutral dark:text-dark-neutral-foreground"

  defp badge_color_classes("solid", "primary"),
    do: "bg-primary text-primary-foreground dark:bg-dark-primary dark:text-dark-primary-foreground"

  defp badge_color_classes("solid", "secondary"),
    do: "bg-secondary text-secondary-foreground dark:bg-dark-secondary dark:text-dark-secondary-foreground"

  defp badge_color_classes("solid", "success"),
    do: "bg-success text-success-foreground dark:bg-dark-success dark:text-dark-success-foreground"

  defp badge_color_classes("solid", "danger"),
    do: "bg-danger text-danger-foreground dark:bg-dark-danger dark:text-dark-danger-foreground"

  defp badge_color_classes("solid", "warning"),
    do: "bg-warning text-warning-foreground dark:bg-dark-warning dark:text-dark-warning-foreground"

  defp badge_color_classes("solid", "info"),
    do: "bg-info text-info-foreground dark:bg-dark-info dark:text-dark-info-foreground"

  defp badge_color_classes(_, color), do: badge_color_classes("solid", color)

  defp get_badge_size("xs"), do: "xs"
  defp get_badge_size("sm"), do: "xs"
  defp get_badge_size("md"), do: "sm"
  defp get_badge_size("lg"), do: "sm"
  defp get_badge_size("xl"), do: "md"

  # Helper for extracting selected options for multi-select badges
  defp extract_selected_options(nil, _options), do: []
  defp extract_selected_options([], _options), do: []

  defp extract_selected_options(selected_values, options) when is_list(selected_values) do
    option_map = build_option_map(options)

    selected_values
    |> Enum.map(fn value ->
      case Map.get(option_map, to_string(value)) do
        nil -> %{label: to_string(value), value: value}
        label -> %{label: label, value: value}
      end
    end)
  end

  defp extract_selected_options(selected_value, options) do
    extract_selected_options([selected_value], options)
  end

  # Build a flat map of value -> label from Phoenix options format
  defp build_option_map(options) when is_list(options) do
    options
    |> Enum.reduce(%{}, fn
      {label, value}, acc when not is_list(value) ->
        Map.put(acc, to_string(value), label)

      {_group_label, group_options}, acc when is_list(group_options) ->
        group_map = build_option_map(group_options)
        Map.merge(acc, group_map)

      value, acc when is_binary(value) or is_atom(value) ->
        Map.put(acc, to_string(value), to_string(value))

      _, acc ->
        acc
    end)
  end

  # Keep local and private - helper for error detection
  defp has_field_errors(%{field: %FormField{errors: errs}}) when is_list(errs) and errs != [], do: true
  defp has_field_errors(_), do: false
end
