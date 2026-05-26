defmodule Pulsar.Components.Switch do
  @moduledoc """
  iOS-style toggle switch component for Phoenix LiveView forms.

  Provides beautiful, accessible switches with smooth animations, semantic variants,
  and consistent styling. All styling is applied via Tailwind CSS utilities with semantic
  color tokens that support both light and dark modes.

  ## Features

  - **Native Form Integration**: Uses checkbox input for proper form submission
  - **iOS-inspired Design**: Smooth animations with rounded track and sliding thumb
  - **Keyboard Accessible**: Space key toggles, Tab navigation, screen reader support
  - **Variants**: solid, outline, ghost with semantic styling
  - **Colors**: neutral, primary, secondary, success, danger, warning, info for consistent theming
  - **Multiple Sizes**: xs, sm, md, lg, xl for complete range
  - **Loading State**: Spinner animation during async operations
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic invalid styling when used with Phoenix forms

  ## Examples

      # Basic switch
      <.switch field={@form[:notifications_enabled]} />

      # With variant, color and size
      <.switch
        field={@form[:dark_mode]}
        variant="outline"
        color="primary"
        size="lg"
      />

      # Loading state during async operation
      <.switch
        field={@form[:public_profile]}
        loading={@updating_privacy}
        color="success"
      />



      # Ghost variant for compact UI
      <.switch
        field={@form[:compact_mode]}
        variant="ghost"
        size="sm"
        color="neutral"
      />

      # Custom loading content
      <.switch
        field={@form[:sync_enabled]}
        loading={@syncing}
      >
        <:loading_content>
          <div class="flex items-center gap-1">
            <div class="text-xs">Syncing...</div>
          </div>
        </:loading_content>
      </.switch>

  ## Switch vs Checkbox

  Use a switch for immediate on/off actions that take effect instantly (like toggling
  a setting), and checkboxes for selections that may require form submission.
  Switches imply the action happens now, like a physical light switch.

  ## Form Integration

  The switch uses a hidden checkbox input for proper form submission. When the form
  is submitted, the switch value will be included in the form params as "true" when
  checked and "false" when unchecked.

  ## Invalid State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback.

  ## Accessibility

  The switch provides full keyboard and screen reader support:
  - Space key toggles the switch
  - Tab key moves focus to/from the switch
  - Screen readers announce the switch state
  - ARIA attributes provide proper semantic information
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for both track and thumb
  @size_config %{
    "lg" => %{
      spinner: "h-5 w-5",
      thumb: "h-5 w-5 top-0.5 left-0.5 translate-x-0 peer-checked:translate-x-[32px]",
      track: "h-6 w-14"
    },
    "md" => %{
      spinner: "h-4 w-4",
      thumb: "h-4 w-4 top-0.5 left-0.5 translate-x-0 peer-checked:translate-x-[24px]",
      track: "h-5 w-11"
    },
    "sm" => %{
      spinner: "h-3 w-3",
      thumb: "h-3 w-3 top-0.5 left-0.5 translate-x-0 peer-checked:translate-x-[20px]",
      track: "h-4 w-9"
    },
    "xl" => %{
      spinner: "h-6 w-6",
      thumb: "h-[22px] w-[22px] top-[3px] left-[3px] translate-x-0 peer-checked:translate-x-[36px]",
      track: "h-7 w-16"
    },
    "xs" => %{
      spinner: "h-2 w-2",
      thumb: "h-2.5 w-2.5 top-0.5 left-0.5 translate-x-0 peer-checked:translate-x-[14px]",
      track: "h-3.5 w-7"
    }
  }

  # Color configuration for different variants
  @color_config %{
    "danger" => %{
      ghost: %{
        checked: "peer-checked:bg-danger/15 hover:peer-checked:bg-danger/20"
      },
      outline: %{
        checked: "peer-checked:bg-danger/10 peer-checked:border-danger"
      },
      solid: %{
        checked: "peer-checked:bg-danger/90 peer-checked:hover:bg-danger"
      }
    },
    "info" => %{
      ghost: %{
        checked: "peer-checked:bg-info/15 hover:peer-checked:bg-info/20"
      },
      outline: %{
        checked: "peer-checked:bg-info/10 peer-checked:border-info"
      },
      solid: %{
        checked: "peer-checked:bg-info/90 peer-checked:hover:bg-info"
      }
    },
    "neutral" => %{
      ghost: %{
        checked: "peer-checked:bg-neutral/15 hover:peer-checked:bg-neutral/20"
      },
      outline: %{
        checked: "peer-checked:bg-neutral/10 peer-checked:border-neutral"
      },
      solid: %{
        checked: "peer-checked:bg-neutral/90 peer-checked:hover:bg-neutral"
      }
    },
    "primary" => %{
      ghost: %{
        checked: "peer-checked:bg-primary/15 hover:peer-checked:bg-primary/20"
      },
      outline: %{
        checked: "peer-checked:bg-primary/10 peer-checked:border-primary"
      },
      solid: %{
        checked: "peer-checked:bg-primary/90 peer-checked:hover:bg-primary"
      }
    },
    "secondary" => %{
      ghost: %{
        checked: "peer-checked:bg-secondary/15 hover:peer-checked:bg-secondary/20"
      },
      outline: %{
        checked: "peer-checked:bg-secondary/10 peer-checked:border-secondary"
      },
      solid: %{
        checked: "peer-checked:bg-secondary/90 peer-checked:hover:bg-secondary"
      }
    },
    "success" => %{
      ghost: %{
        checked: "peer-checked:bg-success/15 hover:peer-checked:bg-success/20"
      },
      outline: %{
        checked: "peer-checked:bg-success/10 peer-checked:border-success"
      },
      solid: %{
        checked: "peer-checked:bg-success/90 peer-checked:hover:bg-success"
      }
    },
    "warning" => %{
      ghost: %{
        checked: "peer-checked:bg-warning/15 hover:peer-checked:bg-warning/20"
      },
      outline: %{
        checked: "peer-checked:bg-warning/10 peer-checked:border-warning"
      },
      solid: %{
        checked: "peer-checked:bg-warning/90 peer-checked:hover:bg-warning"
      }
    }
  }

  # Base switch track classes
  @switch_base_classes [
    "relative inline-flex rounded-full cursor-pointer",
    "transition-all duration-normal ease-standard",
    "transform-gpu",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
    "focus-visible:ring-ring",
    "focus-visible:ring-offset-background",
    "data-[disabled=true]:opacity-disabled data-[disabled=true]:cursor-not-allowed data-[disabled=true]:pointer-events-none",
    "data-[loading=true]:cursor-wait",
    "shadow-inner shadow-black/5",
    "hover:shadow-inner hover:shadow-black/10"
  ]

  # Base thumb classes
  @thumb_base_classes [
    "absolute rounded-full",
    "transition-all duration-normal ease-standard",
    "transform-gpu",
    "flex items-center justify-center pointer-events-none",
    "data-[loading=true]:bg-background",
    "group-hover:scale-105",
    "group-active:scale-95",
    "peer-focus-visible:scale-110"
  ]

  # Inline ID generator (replacing Stellar.Helpers.IdGenerator)
  defp generate_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Essential Stellar helpers copied locally for normalization
  defp normalize_field_props(assigns) do
    field = assigns[:field]

    if field do
      %{
        checked: checked?(field.value, assigns[:value] || "true"),
        errors: field.errors || [],
        id: assigns[:id] || field.id || generate_id("switch"),
        name: assigns[:name] || field.name
      }
    else
      %{
        checked: assigns[:checked] || false,
        errors: [],
        id: assigns[:id] || generate_id("switch"),
        name: assigns[:name]
      }
    end
  end

  defp checked?(field_value, switch_value) do
    to_string(field_value) == to_string(switch_value)
  end

  defp assign_computed_attributes(assigns, normalized) do
    assigns
    |> assign(:id, normalized.id)
    |> assign(:name, normalized.name)
    |> assign(:checked, normalized.checked)
    |> assign(:field_errors, normalized.errors)
  end

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the switch"
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the switch (overridden by error state)"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the switch"
  )

  attr(:show_loading_spinner, :boolean,
    default: true,
    doc: "Show automatic spinner when loading (can be disabled for custom loading content)"
  )

  # Stellar switch attributes - copied from Stellar.Components.Switch
  attr(:field, FormField, default: nil, doc: "Phoenix form field")

  # Core attributes
  attr(:id, :string,
    default: nil,
    doc: "Switch ID (auto-generated if not provided)"
  )

  attr(:name, :string,
    default: nil,
    doc: "Switch name (from field if not provided)"
  )

  attr(:value, :any,
    default: "true",
    doc: "Value when switch is checked"
  )

  attr(:checked, :boolean,
    default: false,
    doc: "Switch state (from field if not provided)"
  )

  attr(:unchecked_value, :string,
    default: "false",
    doc: "Hidden input value when unchecked"
  )

  attr(:loading, :boolean,
    default: false,
    doc: "Loading state for async operations"
  )

  attr(:render_hidden, :boolean,
    default: true,
    doc: "Render hidden input for unchecked value"
  )

  # State attributes
  attr(:required, :boolean,
    default: false,
    doc: "Mark switch as required"
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Disable the switch"
  )

  attr(:invalid, :boolean,
    default: nil,
    doc: "Force invalid state; defaults to Phoenix field errors when nil"
  )

  # Accessibility attributes
  attr(:aria_label, :string,
    default: nil,
    doc: "Accessible label for the switch"
  )

  attr(:aria_labelledby, :string,
    default: nil,
    doc: "ID of element that labels the switch"
  )

  # Styling
  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  # Global attributes (allows all Phoenix and HTML attributes)
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:loading_content,
    required: false,
    doc: "Custom loading content that replaces the switch when loading"
  )

  @doc """
  Renders an iOS-style toggle switch component.

  The switch is implemented as a styled checkbox input for proper form integration,
  with visual styling applied via Tailwind CSS classes that respond to the checkbox state.

  ## Variants
  - **solid**: Filled background when checked (default, most prominent)
  - **outline**: Bordered with subtle fill when checked
  - **ghost**: Minimal styling, transparent until checked



  ## Examples

        # Standard switch
        <.switch field={@form[:notifications]} />

        # Outline variant
        <.switch
          field={@form[:dark_mode]}
          variant="outline"
        />

        # Large success switch
        <.switch
          field={@form[:feature_enabled]}
          color="success"
          size="lg"
        />
  """
  @spec switch(map()) :: Rendered.t()
  def switch(assigns) do
    # Validate required attributes
    if is_nil(assigns[:field]) and is_nil(assigns[:name]) do
      raise ArgumentError,
            "Switch requires :field or :name; provide :name only when not using a Phoenix form field"
    end

    # Normalize field properties
    normalized = normalize_field_props(assigns)

    # Detect errors and compute effective color
    has_errors = not Enum.empty?(normalized.errors)
    user_invalid = Map.get(assigns, :invalid)
    invalid = if is_nil(user_invalid), do: has_errors, else: user_invalid
    effective_color = if invalid, do: "danger", else: assigns.color

    # Build class string for switch
    switch_class =
      merge([
        base_switch_classes(),
        track_size_classes(assigns.size),
        track_variant_classes(assigns.variant, effective_color),
        state_classes(assigns.disabled, invalid),
        assigns.class
      ])

    # Build thumb class string
    thumb_class =
      merge([
        base_thumb_classes(),
        thumb_classes(assigns.size, assigns.variant)
      ])

    assigns =
      assigns
      |> assign_computed_attributes(normalized)
      |> assign(:switch_class, switch_class)
      |> assign(:thumb_class, thumb_class)
      |> assign(:effective_color, effective_color)
      |> assign(:invalid, invalid)

    render_switch_only(assigns)
  end

  # Switch only (no label wrapper) - now using checkbox for proper form submission
  defp render_switch_only(assigns) do
    ~H"""
    <div class="relative inline-flex group">
      <input
        :if={@render_hidden}
        type="hidden"
        name={@name}
        value={@unchecked_value}
        disabled={@disabled}
      />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        class="sr-only peer"
        required={@required}
        disabled={@disabled}
        role="switch"
        aria-checked={if @checked, do: "true", else: "false"}
        aria-label={@aria_label}
        aria-labelledby={@aria_labelledby}
        aria-invalid={@invalid && "true"}
        {@rest}
      />
      
    <!-- Visual switch track (clickable) -->
      <button
        type="button"
        tabindex="-1"
        phx-click={JS.dispatch("click", to: "##{@id}")}
        class={@switch_class}
        data-loading={@loading && "true"}
        data-disabled={@disabled && "true"}
        disabled={@disabled}
      />
      
    <!-- Custom thumb with loading state -->
      <div
        class={@thumb_class}
        data-loading={(@loading && "true") || "false"}
        data-disabled={(@disabled && "true") || "false"}
      >
        <!-- Loading spinner with fade-in animation -->
        <svg
          :if={@loading && @show_loading_spinner && @loading_content == []}
          aria-hidden="true"
          class={[
            "animate-spin text-muted-foreground animate-fade-in",
            spinner_size_classes(@size)
          ]}
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"></circle>
          <path
            fill="currentColor"
            class="opacity-75"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
        
    <!-- Custom loading content -->
        <div :if={@loading && @loading_content != []}>
          {render_slot(@loading_content)}
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # SWITCH COMPONENT HELPERS
  # ============================================================================

  # Base switch track classes using module attribute
  @spec base_switch_classes() :: list(String.t())
  defp base_switch_classes do
    @switch_base_classes
  end

  # Track size classes from configuration map
  @spec track_size_classes(String.t()) :: String.t()
  defp track_size_classes(size) do
    @size_config[size][:track]
  end

  # Track variant classes using configuration map
  @spec track_variant_classes(String.t(), String.t()) :: String.t()
  defp track_variant_classes("solid", color) do
    [
      "bg-muted/80",
      "hover:bg-muted/90",
      "peer-focus-visible:bg-muted",
      @color_config[color][:solid][:checked]
    ]
    |> Enum.join(" ")
  end

  defp track_variant_classes("outline", color) do
    [
      "border-2",
      "bg-background border-border/70",
      "hover:border-border",
      "peer-focus-visible:border-border",
      @color_config[color][:outline][:checked]
    ]
    |> Enum.join(" ")
  end

  defp track_variant_classes("ghost", color) do
    [
      "border-2 border-transparent",
      "bg-muted/30 hover:bg-muted/40",
      "peer-focus-visible:bg-muted/50",
      @color_config[color][:ghost][:checked]
    ]
    |> Enum.join(" ")
  end

  # Base thumb classes using module attribute
  @spec base_thumb_classes() :: list(String.t())
  defp base_thumb_classes do
    @thumb_base_classes
  end

  # Combined thumb classes from configuration map
  @spec thumb_classes(String.t(), String.t()) :: String.t()
  defp thumb_classes(size, variant) do
    [
      @size_config[size][:thumb],
      thumb_variant_classes(variant)
    ]
    |> Enum.join(" ")
  end

  # Thumb variant classes (shadow and border)
  @spec thumb_variant_classes(String.t()) :: String.t()
  defp thumb_variant_classes("solid") do
    "bg-background shadow-modal shadow-black/10"
  end

  defp thumb_variant_classes("outline") do
    "bg-background shadow-dropdown shadow-black/8 border border-border/30"
  end

  defp thumb_variant_classes("ghost") do
    "bg-background shadow-dropdown shadow-black/6"
  end

  # State classes for invalid states
  @spec state_classes(boolean(), boolean()) :: String.t()
  defp state_classes(_disabled, invalid) do
    if invalid do
      "ring-2 ring-danger"
    else
      ""
    end
  end

  # Loading spinner size classes from configuration map
  @spec spinner_size_classes(String.t()) :: String.t()
  defp spinner_size_classes(size) do
    @size_config[size][:spinner]
  end
end
