defmodule Pulsar.Components.Switch do
  @moduledoc """
  iOS-style toggle switch component built on Stellar.Components.Switch.

  Provides beautiful, accessible switches with smooth animations, semantic variants,
  and consistent styling. All styling is applied via Tailwind CSS utilities with semantic
  color tokens that support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible switch component
  - **iOS-inspired Design**: Smooth animations with rounded track and sliding thumb
  - **Variants**: solid, outline, ghost with semantic styling
  - **Colors**: neutral, primary, secondary, success, danger, warning, info for consistent theming
  - **Multiple Sizes**: xs, sm, md, lg, xl for complete range
   - **Loading State**: Spinner animation during async operations
   - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Automatic error styling when used with Phoenix forms
  - **Full Stellar API**: All Stellar switch props are supported

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

  ## Error State Handling

  When used with Phoenix forms, validation errors automatically override styling
  to show danger (red) styling. This provides consistent error feedback.

  ## Stellar Integration

  This component wraps Stellar.Components.Switch and passes through all its props:
  - `:field` - Phoenix form field integration
  - `:checked`, `:loading` - State management
  - `:name`, `:value`, `:unchecked_value` - Value handling
  - `:disabled`, `:required` - Form states
  - `:aria_label`, `:aria_labelledby` - Accessibility
  - All Phoenix LiveView attributes (phx-click, etc.)
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered
  alias Stellar.Components.Switch, as: StellarSwitch

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

  attr(:error, :boolean,
    default: nil,
    doc: "Force error state; defaults to Phoenix field errors when nil"
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

  This function wraps Stellar.Components.Switch with Pulsar's styling system.
  All Stellar props are passed through, with styling controlled via CSS classes
  that respond to the switch's data attributes.

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

    # Detect errors and compute effective color
    has_errors = if is_nil(assigns.error), do: has_field_errors(assigns), else: assigns.error
    effective_color = if has_errors, do: "danger", else: assigns.color

    # Build class string for switch
    switch_class =
      merge([
        base_switch_classes(),
        track_classes(assigns.variant, effective_color, assigns.size),
        state_classes(assigns.disabled, has_errors),
        assigns.class
      ])

    # Build thumb class string
    thumb_class =
      merge([
        base_thumb_classes(),
        thumb_size_classes(assigns.size),
        thumb_variant_classes(assigns.variant),
        thumb_position_classes(assigns.size)
      ])

    assigns =
      assigns
      |> assign(:switch_class, switch_class)
      |> assign(:thumb_class, thumb_class)
      |> assign(:effective_color, effective_color)
      |> assign(:has_errors, has_errors)

    render_switch_only(assigns)
  end

  # Switch only (no label wrapper)
  defp render_switch_only(assigns) do
    ~H"""
    <div class="relative inline-flex">
      <StellarSwitch.switch
        field={@field}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        unchecked_value={@unchecked_value}
        loading={@loading}
        render_hidden={@render_hidden}
        required={@required}
        disabled={@disabled}
        error={@has_errors}
        aria_label={@aria_label}
        aria_labelledby={@aria_labelledby}
        class={@switch_class}
        {@rest}
      />
      
    <!-- Custom thumb with loading state -->
      <div
        class={@thumb_class}
        data-loading={(@loading && "true") || "false"}
        data-disabled={(@disabled && "true") || "false"}
      >
        <!-- Loading spinner -->
        <svg
          :if={@loading && @show_loading_spinner && @loading_content == []}
          aria-hidden="true"
          class={["animate-spin text-muted-foreground dark:text-dark-muted-foreground", spinner_size_classes(@size)]}
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

  # Base switch track classes
  @spec base_switch_classes() :: String.t()
  defp base_switch_classes do
    [
      "group relative inline-flex rounded-full cursor-pointer transition-all duration-300 ease-in-out",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
      "focus-visible:ring-ring dark:focus-visible:ring-dark-ring",
      "data-[disabled=true]:opacity-50 data-[disabled=true]:cursor-not-allowed",
      "data-[loading=true]:cursor-wait"
    ]
    |> Enum.join(" ")
  end

  # Track classes combining variant, color, and size
  @spec track_classes(String.t(), String.t(), String.t()) :: String.t()
  defp track_classes(variant, color, size) do
    [
      track_size_classes(size),
      track_variant_classes(variant, color)
    ]
    |> List.flatten()
    |> Enum.join(" ")
  end

  # Track size classes
  @spec track_size_classes(String.t()) :: String.t()
  defp track_size_classes("xs"), do: "h-4 w-7"
  defp track_size_classes("sm"), do: "h-5 w-9"
  defp track_size_classes("md"), do: "h-6 w-11"
  defp track_size_classes("lg"), do: "h-7 w-14"
  defp track_size_classes("xl"), do: "h-8 w-16"

  # Track variant classes by color
  @spec track_variant_classes(String.t(), String.t()) :: list(String.t())
  defp track_variant_classes("solid", color) do
    [
      "data-[state=unchecked]:bg-muted dark:data-[state=unchecked]:bg-dark-muted",
      track_solid_checked_classes(color)
    ]
  end

  defp track_variant_classes("outline", color) do
    [
      "border-2",
      "data-[state=unchecked]:bg-background data-[state=unchecked]:border-border",
      "dark:data-[state=unchecked]:bg-dark-background dark:data-[state=unchecked]:border-dark-border",
      track_outline_checked_classes(color)
    ]
  end

  defp track_variant_classes("ghost", color) do
    [
      "border-2 border-transparent",
      "data-[state=unchecked]:bg-transparent hover:data-[state=unchecked]:bg-muted/20",
      "dark:hover:data-[state=unchecked]:bg-dark-muted/20",
      track_ghost_checked_classes(color)
    ]
  end

  # Solid variant checked state classes by color
  @spec track_solid_checked_classes(String.t()) :: String.t()
  defp track_solid_checked_classes("neutral"),
    do: "data-[state=checked]:bg-neutral dark:data-[state=checked]:bg-dark-neutral"

  defp track_solid_checked_classes("primary"),
    do: "data-[state=checked]:bg-primary dark:data-[state=checked]:bg-dark-primary"

  defp track_solid_checked_classes("secondary"),
    do: "data-[state=checked]:bg-secondary dark:data-[state=checked]:bg-dark-secondary"

  defp track_solid_checked_classes("success"),
    do: "data-[state=checked]:bg-success dark:data-[state=checked]:bg-dark-success"

  defp track_solid_checked_classes("danger"),
    do: "data-[state=checked]:bg-danger dark:data-[state=checked]:bg-dark-danger"

  defp track_solid_checked_classes("warning"),
    do: "data-[state=checked]:bg-warning dark:data-[state=checked]:bg-dark-warning"

  defp track_solid_checked_classes("info"), do: "data-[state=checked]:bg-info dark:data-[state=checked]:bg-dark-info"

  # Outline variant checked state classes by color
  @spec track_outline_checked_classes(String.t()) :: String.t()
  defp track_outline_checked_classes("neutral") do
    [
      "data-[state=checked]:bg-neutral/10 data-[state=checked]:border-neutral",
      "dark:data-[state=checked]:bg-dark-neutral/10 dark:data-[state=checked]:border-dark-neutral"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("primary") do
    [
      "data-[state=checked]:bg-primary/10 data-[state=checked]:border-primary",
      "dark:data-[state=checked]:bg-dark-primary/10 dark:data-[state=checked]:border-dark-primary"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("secondary") do
    [
      "data-[state=checked]:bg-secondary/10 data-[state=checked]:border-secondary",
      "dark:data-[state=checked]:bg-dark-secondary/10 dark:data-[state=checked]:border-dark-secondary"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("success") do
    [
      "data-[state=checked]:bg-success/10 data-[state=checked]:border-success",
      "dark:data-[state=checked]:bg-dark-success/10 dark:data-[state=checked]:border-dark-success"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("danger") do
    [
      "data-[state=checked]:bg-danger/10 data-[state=checked]:border-danger",
      "dark:data-[state=checked]:bg-dark-danger/10 dark:data-[state=checked]:border-dark-danger"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("warning") do
    [
      "data-[state=checked]:bg-warning/10 data-[state=checked]:border-warning",
      "dark:data-[state=checked]:bg-dark-warning/10 dark:data-[state=checked]:border-dark-warning"
    ]
    |> Enum.join(" ")
  end

  defp track_outline_checked_classes("info") do
    [
      "data-[state=checked]:bg-info/10 data-[state=checked]:border-info",
      "dark:data-[state=checked]:bg-dark-info/10 dark:data-[state=checked]:border-dark-info"
    ]
    |> Enum.join(" ")
  end

  # Ghost variant checked state classes by color
  @spec track_ghost_checked_classes(String.t()) :: String.t()
  defp track_ghost_checked_classes("neutral") do
    [
      "data-[state=checked]:bg-neutral/15 hover:data-[state=checked]:bg-neutral/20",
      "dark:data-[state=checked]:bg-dark-neutral/15 dark:hover:data-[state=checked]:bg-dark-neutral/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("primary") do
    [
      "data-[state=checked]:bg-primary/15 hover:data-[state=checked]:bg-primary/20",
      "dark:data-[state=checked]:bg-dark-primary/15 dark:hover:data-[state=checked]:bg-dark-primary/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("secondary") do
    [
      "data-[state=checked]:bg-secondary/15 hover:data-[state=checked]:bg-secondary/20",
      "dark:data-[state=checked]:bg-dark-secondary/15 dark:hover:data-[state=checked]:bg-dark-secondary/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("success") do
    [
      "data-[state=checked]:bg-success/15 hover:data-[state=checked]:bg-success/20",
      "dark:data-[state=checked]:bg-dark-success/15 dark:hover:data-[state=checked]:bg-dark-success/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("danger") do
    [
      "data-[state=checked]:bg-danger/15 hover:data-[state=checked]:bg-danger/20",
      "dark:data-[state=checked]:bg-dark-danger/15 dark:hover:data-[state=checked]:bg-dark-danger/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("warning") do
    [
      "data-[state=checked]:bg-warning/15 hover:data-[state=checked]:bg-warning/20",
      "dark:data-[state=checked]:bg-dark-warning/15 dark:hover:data-[state=checked]:bg-dark-warning/20"
    ]
    |> Enum.join(" ")
  end

  defp track_ghost_checked_classes("info") do
    [
      "data-[state=checked]:bg-info/15 hover:data-[state=checked]:bg-info/20",
      "dark:data-[state=checked]:bg-dark-info/15 dark:hover:data-[state=checked]:bg-dark-info/20"
    ]
    |> Enum.join(" ")
  end

  # Base thumb classes
  @spec base_thumb_classes() :: String.t()
  defp base_thumb_classes do
    [
      "absolute rounded-full transition-all duration-300 ease-in-out",
      "flex items-center justify-center pointer-events-none",
      "data-[loading=true]:bg-background data-[loading=true]:dark:bg-dark-background"
    ]
    |> Enum.join(" ")
  end

  # Thumb size classes
  @spec thumb_size_classes(String.t()) :: String.t()
  defp thumb_size_classes("xs"), do: "h-3 w-3 top-0.5"
  defp thumb_size_classes("sm"), do: "h-4 w-4 top-0.5"
  defp thumb_size_classes("md"), do: "h-5 w-5 top-0.5"
  defp thumb_size_classes("lg"), do: "h-6 w-6 top-0.5"
  defp thumb_size_classes("xl"), do: "h-7 w-7 top-0.5"

  # Thumb variant classes (shadow and border)
  @spec thumb_variant_classes(String.t()) :: String.t()
  defp thumb_variant_classes("solid"), do: "bg-background dark:bg-dark-background shadow-lg"

  defp thumb_variant_classes("outline"),
    do: "bg-background dark:bg-dark-background shadow-md border border-border/20 dark:border-dark-border/20"

  defp thumb_variant_classes("ghost"), do: "bg-background dark:bg-dark-background shadow-sm"

  # Thumb position classes based on size
  @spec thumb_position_classes(String.t()) :: String.t()
  defp thumb_position_classes("xs") do
    [
      "left-0.5 translate-x-0",
      "group-data-[state=checked]:translate-x-[14px]"
    ]
    |> Enum.join(" ")
  end

  defp thumb_position_classes("sm") do
    [
      "left-0.5 translate-x-0",
      "group-data-[state=checked]:translate-x-[18px]"
    ]
    |> Enum.join(" ")
  end

  defp thumb_position_classes("md") do
    [
      "left-0.5 translate-x-0",
      "group-data-[state=checked]:translate-x-[22px]"
    ]
    |> Enum.join(" ")
  end

  defp thumb_position_classes("lg") do
    [
      "left-0.5 translate-x-0",
      "group-data-[state=checked]:translate-x-[30px]"
    ]
    |> Enum.join(" ")
  end

  defp thumb_position_classes("xl") do
    [
      "left-0.5 translate-x-0",
      "group-data-[state=checked]:translate-x-[34px]"
    ]
    |> Enum.join(" ")
  end

  # State classes for error states
  @spec state_classes(boolean(), boolean()) :: String.t()
  defp state_classes(_disabled, has_errors) do
    if has_errors do
      "ring-2 ring-danger dark:ring-dark-danger"
    else
      ""
    end
  end

  # Loading spinner size classes
  @spec spinner_size_classes(String.t()) :: String.t()
  defp spinner_size_classes("xs"), do: "h-2 w-2"
  defp spinner_size_classes("sm"), do: "h-3 w-3"
  defp spinner_size_classes("md"), do: "h-4 w-4"
  defp spinner_size_classes("lg"), do: "h-5 w-5"
  defp spinner_size_classes("xl"), do: "h-6 w-6"

  # Helper for error detection - checks if a Phoenix form field has validation errors
  @spec has_field_errors(map()) :: boolean()
  defp has_field_errors(%{field: %FormField{errors: errors}}) when is_list(errors) do
    not Enum.empty?(errors)
  end

  defp has_field_errors(_assigns), do: false
end
