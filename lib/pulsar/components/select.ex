defmodule Pulsar.Components.Select do
  @moduledoc """
  Styled select component built on Stellar.Components.Select with consistent theming.

  Provides beautiful, accessible select fields with optional multi-select badge display.
  All styling is applied via Tailwind CSS utilities with semantic color tokens 
  supporting both light and dark modes.

  ## Dependencies

  This component requires:
  - `Pulsar.Components.Badge` - for multi-select badge display
  - `Pulsar.Components.Icon` - for dropdown arrow display

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible select component
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button and input components
  - **Multi-Select Badges**: Display selected options as removable badges using Badge component
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

      # Multi-select with badges (requires Badge component)
      <.select field={@form[:skills]} options={@skills} multiple />

      # Custom badge removal handler
      <.select 
        field={@form[:tags]} 
        options={@tags} 
        multiple 
        on_remove_badge={JS.push("remove_tag")}
      />

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

  import Pulsar.Components.Icon, only: [icon: 1]
  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Badge

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for select elements
  @size_config %{
    "lg" => "min-h-12 text-lg px-4 py-2",
    "md" => "min-h-10 px-3 py-1.5",
    "sm" => "min-h-8 text-sm px-2 py-1",
    "xl" => "min-h-14 text-xl px-4 py-2",
    "xs" => "min-h-6 text-xs px-2 py-1"
  }

  # Badge size mapping for multi-select display
  @badge_sizes %{
    "lg" => "sm",
    "md" => "sm",
    "sm" => "xs",
    "xl" => "md",
    "xs" => "xs"
  }

  # Base select styling classes
  @base_select_classes "block w-full appearance-none transition-all duration-200 ease-in-out focus:ring-2 focus:ring-offset-2 focus:outline-none"

  # Variant-specific layout classes
  @variant_config %{
    "ghost" => "rounded-lg border-0",
    "outline" => "border-2 rounded-lg",
    "solid" => "rounded-lg border-0"
  }

  # Color configuration for different variants
  @color_config %{
    # Outline variant colors
    "outline" => %{
      "danger" =>
        "border-danger/60 dark:border-dark-danger/60 bg-background dark:bg-dark-background text-danger dark:text-dark-danger focus:ring-danger/60 hover:border-danger dark:hover:border-dark-danger",
      "info" =>
        "border-info/60 dark:border-dark-info/60 bg-background dark:bg-dark-background text-info dark:text-dark-info focus:ring-info/60 hover:border-info dark:hover:border-dark-info",
      "neutral" =>
        "border-border dark:border-dark-border bg-background dark:bg-dark-background text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:border-border/80 dark:hover:border-dark-border/80",
      "primary" =>
        "border-primary/60 dark:border-dark-primary/60 bg-background dark:bg-dark-background text-primary dark:text-dark-primary focus:ring-primary/60 hover:border-primary dark:hover:border-dark-primary",
      "secondary" =>
        "border-secondary/60 dark:border-dark-secondary/60 bg-background dark:bg-dark-background text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:border-secondary dark:hover:border-dark-secondary",
      "success" =>
        "border-success/60 dark:border-dark-success/60 bg-background dark:bg-dark-background text-success dark:text-dark-success focus:ring-success/60 hover:border-success dark:hover:border-dark-success",
      "warning" =>
        "border-warning/60 dark:border-dark-warning/60 bg-background dark:bg-dark-background text-warning dark:text-dark-warning focus:ring-warning/60 hover:border-warning dark:hover:border-dark-warning"
    },
    # Ghost variant colors
    "ghost" => %{
      "danger" =>
        "bg-transparent text-danger dark:text-dark-danger focus:ring-danger/60 hover:bg-danger/5 dark:hover:bg-dark-danger/10",
      "info" =>
        "bg-transparent text-info dark:text-dark-info focus:ring-info/60 hover:bg-info/5 dark:hover:bg-dark-info/10",
      "neutral" =>
        "bg-transparent text-foreground dark:text-dark-foreground focus:ring-ring dark:focus:ring-dark-ring hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover",
      "primary" =>
        "bg-transparent text-primary dark:text-dark-primary focus:ring-primary/60 hover:bg-primary/5 dark:hover:bg-dark-primary/10",
      "secondary" =>
        "bg-transparent text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:bg-secondary/5 dark:hover:bg-dark-secondary/10",
      "success" =>
        "bg-transparent text-success dark:text-dark-success focus:ring-success/60 hover:bg-success/5 dark:hover:bg-dark-success/10",
      "warning" =>
        "bg-transparent text-warning dark:text-dark-warning focus:ring-warning/60 hover:bg-warning/5 dark:hover:bg-dark-warning/10"
    },
    # Solid variant colors  
    "solid" => %{
      "danger" =>
        "bg-danger/10 dark:bg-dark-danger/20 text-danger dark:text-dark-danger focus:ring-danger/60 hover:bg-danger/20 dark:hover:bg-dark-danger/30",
      "info" =>
        "bg-info/10 dark:bg-dark-info/20 text-info dark:text-dark-info focus:ring-info/60 hover:bg-info/20 dark:hover:bg-dark-info/30",
      "neutral" =>
        "bg-neutral/10 dark:bg-dark-neutral/20 text-neutral dark:text-dark-neutral focus:ring-neutral/60 hover:bg-neutral/20 dark:hover:bg-dark-neutral/30",
      "primary" =>
        "bg-primary/10 dark:bg-dark-primary/20 text-primary dark:text-dark-primary focus:ring-primary/60 hover:bg-primary/20 dark:hover:bg-dark-primary/30",
      "secondary" =>
        "bg-secondary/10 dark:bg-dark-secondary/20 text-secondary dark:text-dark-secondary focus:ring-secondary/60 hover:bg-secondary/20 dark:hover:bg-dark-secondary/30",
      "success" =>
        "bg-success/10 dark:bg-dark-success/20 text-success dark:text-dark-success focus:ring-success/60 hover:bg-success/20 dark:hover:bg-dark-success/30",
      "warning" =>
        "bg-warning/10 dark:bg-dark-warning/20 text-warning dark:text-dark-warning focus:ring-warning/60 hover:bg-warning/20 dark:hover:bg-dark-warning/30"
    }
  }

  # Arrow color configuration  
  @arrow_colors %{
    "danger" => "text-danger dark:text-dark-danger",
    "info" => "text-info dark:text-dark-info",
    "neutral" => "text-neutral dark:text-dark-neutral",
    "primary" => "text-primary dark:text-dark-primary",
    "secondary" => "text-secondary dark:text-dark-secondary",
    "success" => "text-success dark:text-dark-success",
    "warning" => "text-warning dark:text-dark-warning"
  }

  # Inline ID generator (replacing Stellar.Helpers.IdGenerator)
  defp generate_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(outline ghost solid),
    doc: "Visual style variant of the select"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the select (overridden by error state)"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the select"
  )

  # Stellar select attributes - copied from Stellar.Components.Select
  attr(:field, FormField, default: nil, doc: "Phoenix form field")

  # Core attributes
  attr(:name, :string,
    default: nil,
    doc: "Select name (from field if not provided)"
  )

  attr(:value, :any,
    default: nil,
    doc: "Selected value(s) (from field if not provided)"
  )

  attr(:options, :list, required: true, doc: "List of options in Phoenix format")

  # Select-specific attributes
  attr(:multiple, :boolean, default: false, doc: "Enable multi-select mode")
  attr(:prompt, :string, default: nil, doc: "Prompt option text")
  attr(:auto_name_array, :boolean, default: true, doc: "Auto-append [] to name for multi-select")

  # State attributes
  attr(:required, :boolean,
    default: false,
    doc: "Mark select as required"
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Disable the select"
  )

  # State override (optional)
  attr(:invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"
  )

  # Multi-select badge removal
  attr(:on_remove_badge, :any,
    default: nil,
    doc: "Event handler for removing badges in multi-select mode (Phoenix.LiveView.JS command or event name string)"
  )

  # Styling
  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes")

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
    # Apply Stellar field normalization and computed attributes
    assigns =
      assigns
      |> normalize_field_props()
      |> assign_computed_attributes()
      |> assign_final_name()

    # Compute error state and effective styling
    has_errors = has_field_errors(assigns)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Resolve and normalize value for consistent handling
    current_value = value_or_field(assigns.value, assigns.field)
    normalized_value = if assigns.multiple, do: List.wrap(current_value), else: current_value

    # For multi-select, extract selected options for badge display
    selected_options = if assigns.multiple, do: extract_selected_options(normalized_value, assigns.options), else: []

    # Build final styling
    class =
      merge([
        get_select_classes(assigns.variant, effective_color, assigns.size),
        get_state_classes(assigns.disabled),
        "pr-10",
        assigns.class
      ])

    # Consolidate all final assigns
    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)
      |> assign(:value, normalized_value)
      |> assign(:selected_options, selected_options)
      |> assign(:show_badges, assigns.multiple and not Enum.empty?(selected_options))
      |> assign(:option_html, generate_options_html(%{options: assigns.options, value: normalized_value}))

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class="space-y-2"
      phx-hook={@multiple && ".PulsarSelect"}
      data-variant={@variant}
      data-color={@effective_color}
      data-size={@size}
      data-invalid={@invalid}
      data-required={@required}
      data-multiple={@multiple}
      data-has-badges={@show_badges}
    >
      <!-- Multi-select badges -->
      <div :if={@show_badges} class="flex flex-wrap gap-2">
        <Badge.badge
          :for={option <- @selected_options}
          variant={@variant}
          color={@effective_color}
          size={get_badge_size(@size)}
        >
          {option.label}
          <:end_addon>
            <button
              type="button"
              phx-click={remove_badge_js(@on_remove_badge, @id)}
              phx-value-option={option.value}
              class="ml-1 hover:bg-black/10 dark:hover:bg-white/10 rounded-full p-0.5 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-current transition-colors"
              aria-label={"Remove #{option.label}"}
            >
              <.icon name="hero-x-mark" variant="micro" size="xs" color="current" aria-hidden="true" />
            </button>
          </:end_addon>
        </Badge.badge>
      </div>
      
    <!-- Select wrapper with custom arrow -->
      <div class="relative">
        <select
          id={@id}
          name={@name}
          multiple={@multiple}
          required={@required}
          disabled={@disabled}
          class={@class}
          aria-describedby={@computed_aria_describedby}
          aria-invalid={@invalid && "true"}
          data-disabled={@data_disabled}
          data-required={@data_required}
          data-multiple={@data_multiple}
          data-has-value={@data_has_value}
          data-state="closed"
          {@rest}
        >
          <option :if={@prompt && !@multiple} value="" disabled selected={@value in [nil, ""]}>
            {@prompt}
          </option>
          {Phoenix.HTML.raw(@option_html)}
        </select>
        
    <!-- Custom arrow icon -->
        <div class={[
          "absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none",
          get_arrow_classes(@variant, @effective_color),
          @disabled && "opacity-50"
        ]}>
          <.icon name="hero-chevron-down" size="sm" color="current" />
        </div>
      </div>
    </div>

    <!-- JavaScript hook for multi-select badge removal -->
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarSelect">
      export default {
        mounted() {
          // Find the select element within the wrapper
          this.selectEl = this.el.querySelector('select');
          if (!this.selectEl) return;
          
          this.handleRemoveSelection = (e) => {
            // Get value from detail or target attribute
            const optionValue = e.detail?.option || e.target?.getAttribute('phx-value-option');
            
            if (!this.selectEl.multiple || !optionValue) return;

            // Find and deselect the option (with CSS escaping for security)
            const option = this.selectEl.querySelector(`option[value="${CSS.escape(optionValue)}"]`);
            if (option) {
              option.selected = false;
              
              // Dispatch events on the select element
              this.selectEl.dispatchEvent(new Event('input', { bubbles: true }));
              this.selectEl.dispatchEvent(new Event('change', { bubbles: true }));
            }
          };

          // Listen on the wrapper element (this.el)
          this.el.addEventListener('pulsar:remove-selection', this.handleRemoveSelection);
        },

        destroyed() {
          if (this.handleRemoveSelection) {
            this.el.removeEventListener('pulsar:remove-selection', this.handleRemoveSelection);
          }
        }
      }
    </script>
    """
  end

  # ============================================================================
  # SELECT COMPONENT HELPERS
  # ============================================================================

  # Modular styling system supporting all variants and colors
  defp get_select_classes(variant, color, size) do
    merge([
      base_select_classes(),
      variant_classes(variant),
      color_classes(variant, color),
      size_classes(size)
    ])
  end

  # Base styles shared by all select variants
  defp base_select_classes do
    @base_select_classes
  end

  # Variant-specific layout and structure
  defp variant_classes(variant) do
    Map.get(@variant_config, variant, @variant_config["solid"])
  end

  # Color classes by variant using map lookup
  defp color_classes(variant, color) do
    @color_config
    |> Map.get(variant, %{})
    |> Map.get(color, @color_config[variant]["neutral"])
  end

  # Size classes using map lookup
  defp size_classes(size) do
    Map.get(@size_config, size, @size_config["md"])
  end

  defp get_state_classes(disabled) do
    [
      disabled && "cursor-not-allowed opacity-50 pointer-events-none"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Custom arrow styling using map lookup
  defp get_arrow_classes(_variant, color) do
    Map.get(@arrow_colors, color, @arrow_colors["neutral"])
  end

  # Badge size mapping using configuration
  defp get_badge_size(size) do
    Map.get(@badge_sizes, size, "sm")
  end

  # Helper for extracting selected options for multi-select badges
  defp extract_selected_options(values, options) do
    selected_values = List.wrap(values)

    case selected_values do
      [] ->
        []

      _ ->
        option_map = build_option_map(options)

        Enum.map(selected_values, fn value ->
          %{
            label: Map.get(option_map, to_string(value), to_string(value)),
            value: value
          }
        end)
    end
  end

  # Build a flat map of value -> label from Phoenix options format
  defp build_option_map(options) when is_list(options) do
    Enum.reduce(options, %{}, fn
      {label, value}, acc when not is_list(value) ->
        Map.put(acc, to_string(value), label)

      {_group_label, group_options}, acc when is_list(group_options) ->
        Map.merge(acc, build_option_map(group_options))

      value, acc when is_binary(value) or is_atom(value) or is_integer(value) ->
        Map.put(acc, to_string(value), to_string(value))

      _, acc ->
        acc
    end)
  end

  # Keep local and private - helper for error detection
  defp has_field_errors(%{field: %FormField{errors: errs}}) when is_list(errs) and errs != [], do: true

  defp has_field_errors(_), do: false

  # Resolve value precedence: explicit :value over Phoenix form field
  defp value_or_field(nil, %FormField{value: v}), do: v
  defp value_or_field(nil, _), do: nil
  defp value_or_field(v, _), do: v

  # === Stellar Helper Functions (Merged) ===

  # Normalize field props (from Stellar)
  defp normalize_field_props(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(:id, assigns[:id] || field.id || generate_id("select"))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign(:field_provided, true)
  end

  defp normalize_field_props(assigns) do
    assigns
    |> ensure_name!()
    |> assign(:id, assigns[:id] || assigns[:name] || generate_id("select"))
    |> assign_new(:value, fn -> nil end)
    |> assign(:field_provided, false)
  end

  defp ensure_name!(assigns) do
    if is_nil(assigns[:name]) do
      raise ArgumentError, "Select component requires :name when :field is not provided"
    end

    assigns
  end

  # Compute attributes (from Stellar)
  defp assign_computed_attributes(assigns) do
    # ARIA describedby merging
    caller_describedby = assigns[:aria_describedby]

    errors_id =
      if assigns.field_provided and has_field_errors(assigns),
        do: "#{assigns.id}-errors"

    computed_aria_describedby =
      case {caller_describedby, errors_id} do
        {nil, nil} -> nil
        {caller, nil} -> caller
        {nil, errors} -> errors
        {caller, errors} -> "#{caller} #{errors}"
      end

    # Compute data_has_value considering arrays and empty values
    data_has_value =
      case assigns.value do
        nil -> "false"
        "" -> "false"
        [] -> "false"
        _ -> "true"
      end

    assigns
    |> assign(:computed_aria_describedby, computed_aria_describedby)
    |> assign(:data_disabled, data_boolean(assigns.disabled))
    |> assign(:data_multiple, data_boolean(assigns.multiple))
    |> assign(:data_required, data_boolean(assigns.required))
    |> assign(:data_has_value, data_has_value)
  end

  # Options generation (from Stellar)
  defp generate_options_html(assigns) do
    Form.options_for_select(assigns.options, assigns.value)
    |> Phoenix.HTML.safe_to_string()
  end

  # Data attribute helper (from Stellar)
  defp data_boolean(val), do: if(val, do: "true", else: "false")

  # Handle array name for multi-select
  defp assign_final_name(assigns) do
    final_name =
      if assigns.multiple && assigns.auto_name_array && assigns.name && not String.ends_with?(assigns.name, "[]") do
        assigns.name <> "[]"
      else
        assigns.name
      end

    assign(assigns, :name, final_name)
  end

  # Badge removal JS command
  defp remove_badge_js(handler, wrapper_id) do
    case handler do
      %JS{} = custom_js ->
        custom_js |> JS.dispatch("pulsar:remove-selection", to: "##{wrapper_id}-wrapper")

      event when is_binary(event) ->
        JS.dispatch("pulsar:remove-selection", to: "##{wrapper_id}-wrapper") |> JS.push(event)

      _ ->
        JS.dispatch("pulsar:remove-selection", to: "##{wrapper_id}-wrapper")
    end
  end
end
