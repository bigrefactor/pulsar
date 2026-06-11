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

  - **Accessible by Default**: Proper select semantics with full keyboard and screen reader support
  - **Multiple Variants**: outline, ghost, and solid for different use cases
  - **Full Color Palette**: All semantic colors with automatic error override
  - **Multiple Sizes**: xs, sm, md, lg, xl matching button and input components
  - **Multi-Select Badges**: Display selected options as removable badges using Badge component
  - **Custom Arrow**: Styled dropdown arrow matching theme colors
  - **Option Groups**: Consistent styling for grouped options
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Phoenix-native API**: Aligns with Pulsar components and Phoenix forms

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

  ## Integration

  This component provides full Phoenix form integration:
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
  import Twm, only: [merge: 1]

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
  @base_select_classes "block w-full appearance-none transition-[color,background-color,border-color,box-shadow] duration-fast ease-standard focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none"

  # Variant-specific layout classes
  @variant_config %{
    "ghost" => "rounded-box border-0",
    "outline" => "border-2 rounded-box",
    "solid" => "rounded-box border-0"
  }

  # Color configuration for different variants
  @color_config %{
    # Outline variant colors
    "outline" => %{
      "danger" => "border-danger bg-background text-danger focus-visible:ring-ring hover:border-danger",
      "info" => "border-info bg-background text-info focus-visible:ring-ring hover:border-info",
      "neutral" =>
        "border-border-strong bg-background text-foreground focus-visible:ring-ring hover:border-border-strong/80",
      "primary" => "border-primary bg-background text-primary focus-visible:ring-ring hover:border-primary",
      "secondary" => "border-secondary bg-background text-secondary focus-visible:ring-ring hover:border-secondary",
      "success" => "border-success bg-background text-success focus-visible:ring-ring hover:border-success",
      "warning" => "border-warning bg-background text-warning focus-visible:ring-ring hover:border-warning"
    },
    # Ghost variant colors
    "ghost" => %{
      "danger" => "bg-transparent text-danger focus-visible:ring-ring hover:bg-danger/5",
      "info" => "bg-transparent text-info focus-visible:ring-ring hover:bg-info/5",
      "neutral" => "bg-transparent text-foreground focus-visible:ring-ring hover:bg-surface-1-hover",
      "primary" => "bg-transparent text-primary focus-visible:ring-ring hover:bg-primary/5",
      "secondary" => "bg-transparent text-secondary focus-visible:ring-ring hover:bg-secondary/5",
      "success" => "bg-transparent text-success focus-visible:ring-ring hover:bg-success/5",
      "warning" => "bg-transparent text-warning focus-visible:ring-ring hover:bg-warning/5"
    },
    # Solid variant colors
    "solid" => %{
      "danger" => "bg-danger/10 text-danger focus-visible:ring-ring hover:bg-danger/20",
      "info" => "bg-info/10 text-info focus-visible:ring-ring hover:bg-info/20",
      "neutral" => "bg-neutral/10 text-foreground focus-visible:ring-ring hover:bg-neutral/20",
      "primary" => "bg-primary/10 text-primary focus-visible:ring-ring hover:bg-primary/20",
      "secondary" => "bg-secondary/10 text-secondary focus-visible:ring-ring hover:bg-secondary/20",
      "success" => "bg-success/10 text-success focus-visible:ring-ring hover:bg-success/20",
      "warning" => "bg-warning/10 text-warning focus-visible:ring-ring hover:bg-warning/20"
    }
  }

  # Arrow color configuration
  @arrow_colors %{
    "danger" => "text-danger",
    "info" => "text-info",
    "neutral" => "text-neutral",
    "primary" => "text-primary",
    "secondary" => "text-secondary",
    "success" => "text-success",
    "warning" => "text-warning"
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
  attr(:on_remove_badge, JS,
    default: %JS{},
    doc: "JS commands to run when a badge is removed in multi-select mode"
  )

  attr(:remove_label, :string,
    default: "Remove",
    doc: ~s{Accessible label prefix for the badge remove button. Use with i18n: gettext("Remove")}
  )

  # Styling
  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  # Accessibility
  attr(:"aria-describedby", :string, default: nil, doc: "Id(s) of elements that describe the select")

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a styled select component with optional multi-select badges.

  This function renders a native HTML select with Pulsar's styling system.
  Styling is automatically determined by variant and error state.

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
        if(assigns.multiple, do: "", else: "pr-10"),
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
      phx-hook=".PulsarSelect"
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
              phx-click={remove_badge_js(@on_remove_badge, @id, option.value)}
              phx-value-option={option.value}
              class="ml-1 cursor-pointer hover:bg-foreground/10 rounded-full p-0.5 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-current transition-colors duration-fast ease-standard"
              aria-label={"#{@remove_label} #{option.label}"}
            >
              <.icon name="hero-x-mark-micro" size="xs" color="current" aria-hidden="true" />
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
          aria-describedby={assigns[:"aria-describedby"]}
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
        
    <!-- Custom arrow icon (single-select only; native multi-select listboxes have no dropdown affordance) -->
        <div
          :if={!@multiple}
          class={[
            "absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none",
            get_arrow_classes(@variant, @effective_color),
            @disabled && "opacity-disabled"
          ]}
        >
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
      disabled && "cursor-not-allowed opacity-disabled pointer-events-none"
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
    # Compute data_has_value considering arrays and empty values
    data_has_value =
      case assigns.value do
        nil -> "false"
        "" -> "false"
        [] -> "false"
        _ -> "true"
      end

    assigns
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

  # Badge removal JS command. Runs the caller's on_remove_badge commands (the
  # empty %JS{} default is a no-op), then dispatches the internal event the hook
  # listens for to drop the badge.
  defp remove_badge_js(handler, wrapper_id, option_value) do
    JS.dispatch(handler, "pulsar:remove-selection",
      to: "##{wrapper_id}-wrapper",
      detail: %{option: option_value}
    )
  end
end
