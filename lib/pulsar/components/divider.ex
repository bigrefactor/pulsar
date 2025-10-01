defmodule Pulsar.Components.Divider do
  @moduledoc """
  Divider component for visually separating content sections.

  Provides styled dividers with optional labels that can be oriented horizontally
  or vertically. All styling is applied via Tailwind CSS utilities with semantic
  color tokens that support both light and dark modes.

  ## Features

  - **Multiple Variants**: solid, outline, ghost for different visual emphasis
  - **Line Styles**: solid, dashed, dotted border patterns
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl for thickness and spacing control
  - **Orientations**: horizontal (default) and vertical layouts
  - **Optional Labels**: Add text or content in the center of the divider

  ## Examples

      # Simple horizontal divider
      <.divider />

      # Colored divider with variant
      <.divider variant="solid" color="primary" />

      # Labeled divider (common for "OR" separators)
      <.divider>OR</.divider>

      # Dashed section divider with label
      <.divider style="dashed" color="neutral">
        Section 2
      </.divider>

      # Vertical divider (requires height constraint)
      <.divider orientation="vertical" class="h-8" />

      # Subtle ghost divider
      <.divider variant="ghost" />

      # Large primary divider with label
      <.divider size="lg" color="primary">
        Featured Content
      </.divider>

  ## Usage Patterns

      # Between form sections
      <.simple_form for={@form}>
        <.input field={@form[:name]} />
        <.input field={@form[:email]} />

        <.divider>Account Settings</.divider>

        <.input field={@form[:password]} type="password" />
      </.simple_form>

      # In flex layouts with vertical divider
      <div class="flex items-center gap-4">
        <.button>Save</.button>
        <.divider orientation="vertical" class="h-6" />
        <.button variant="ghost">Cancel</.button>
      </div>

      # Section separators in cards
      <.card>
        <p>First section content</p>
        <.divider />
        <p>Second section content</p>
      </.card>

  ## Accessibility

  - Uses semantic HTML (`<hr>` for unlabeled, appropriate elements for labeled)
  - Proper ARIA roles for labeled dividers
  - Screen reader friendly text for visual separators
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  alias Phoenix.LiveView.Rendered

  # Size configuration for thickness and spacing
  @size_config %{
    "lg" => %{
      horizontal: %{
        border: "border-t-4",
        spacing: "my-8"
      },
      vertical: %{
        border: "border-l-4",
        spacing: "mx-8"
      },
      label: "text-lg mx-4"
    },
    "md" => %{
      horizontal: %{
        border: "border-t-2",
        spacing: "my-6"
      },
      vertical: %{
        border: "border-l-2",
        spacing: "mx-6"
      },
      label: "text-base mx-3"
    },
    "sm" => %{
      horizontal: %{
        border: "border-t",
        spacing: "my-4"
      },
      vertical: %{
        border: "border-l",
        spacing: "mx-4"
      },
      label: "text-sm mx-2"
    },
    "xl" => %{
      horizontal: %{
        border: "border-t-8",
        spacing: "my-10"
      },
      vertical: %{
        border: "border-l-8",
        spacing: "mx-10"
      },
      label: "text-xl mx-6"
    },
    "xs" => %{
      horizontal: %{
        border: "border-t",
        spacing: "my-2"
      },
      vertical: %{
        border: "border-l",
        spacing: "mx-2"
      },
      label: "text-xs mx-1.5"
    }
  }

  # Line style configuration
  @style_config %{
    "dashed" => "border-dashed",
    "dotted" => "border-dotted",
    "solid" => "border-solid"
  }

  # Color and opacity by variant
  @color_config %{
    "ghost" => %{
      "danger" => "border-danger/30 dark:border-dark-danger/30",
      "info" => "border-info/30 dark:border-dark-info/30",
      "neutral" => "border-border/30 dark:border-dark-border/30",
      "primary" => "border-primary/30 dark:border-dark-primary/30",
      "secondary" => "border-secondary/30 dark:border-dark-secondary/30",
      "success" => "border-success/30 dark:border-dark-success/30",
      "warning" => "border-warning/30 dark:border-dark-warning/30"
    },
    "outline" => %{
      "danger" => "border-danger/60 dark:border-dark-danger/60",
      "info" => "border-info/60 dark:border-dark-info/60",
      "neutral" => "border-border dark:border-dark-border",
      "primary" => "border-primary/60 dark:border-dark-primary/60",
      "secondary" => "border-secondary/60 dark:border-dark-secondary/60",
      "success" => "border-success/60 dark:border-dark-success/60",
      "warning" => "border-warning/60 dark:border-dark-warning/60"
    },
    "solid" => %{
      "danger" => "border-danger dark:border-dark-danger",
      "info" => "border-info dark:border-dark-info",
      "neutral" => "border-neutral dark:border-dark-neutral",
      "primary" => "border-primary dark:border-dark-primary",
      "secondary" => "border-secondary dark:border-dark-secondary",
      "success" => "border-success dark:border-dark-success",
      "warning" => "border-warning dark:border-dark-warning"
    }
  }

  # Label text colors by variant and color
  @label_color_config %{
    "ghost" => %{
      "danger" => "text-danger/70 dark:text-dark-danger/70",
      "info" => "text-info/70 dark:text-dark-info/70",
      "neutral" => "text-muted-foreground dark:text-dark-muted-foreground",
      "primary" => "text-primary/70 dark:text-dark-primary/70",
      "secondary" => "text-secondary/70 dark:text-dark-secondary/70",
      "success" => "text-success/70 dark:text-dark-success/70",
      "warning" => "text-warning/70 dark:text-dark-warning/70"
    },
    "outline" => %{
      "danger" => "text-danger dark:text-dark-danger",
      "info" => "text-info dark:text-dark-info",
      "neutral" => "text-foreground dark:text-dark-foreground",
      "primary" => "text-primary dark:text-dark-primary",
      "secondary" => "text-secondary dark:text-dark-secondary",
      "success" => "text-success dark:text-dark-success",
      "warning" => "text-warning dark:text-dark-warning"
    },
    "solid" => %{
      "danger" => "text-danger dark:text-dark-danger",
      "info" => "text-info dark:text-dark-info",
      "neutral" => "text-foreground dark:text-dark-foreground",
      "primary" => "text-primary dark:text-dark-primary",
      "secondary" => "text-secondary dark:text-dark-secondary",
      "success" => "text-success dark:text-dark-success",
      "warning" => "text-warning dark:text-dark-warning"
    }
  }

  # ============================================================================
  # DIVIDER COMPONENT
  # ============================================================================

  attr :variant, :string,
    default: "outline",
    values: ~w(solid outline ghost),
    doc: "Visual emphasis level of the divider"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the divider"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size affecting thickness and spacing"

  attr :orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "Orientation of the divider"

  attr :style, :string,
    default: "solid",
    values: ~w(solid dashed dotted),
    doc: "Line style pattern"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, doc: "Optional label content for the divider"

  @doc """
  Renders a divider component for visually separating content.

  The divider uses semantic color tokens and supports both horizontal and
  vertical orientations. Labels can be added via the inner_block slot.

  ## Examples

      # Simple divider
      <.divider />

      # With label
      <.divider>Section Title</.divider>

      # Vertical divider (needs height)
      <.divider orientation="vertical" class="h-8" />
  """
  @spec divider(map()) :: Rendered.t()
  def divider(assigns) do
    has_label = assigns.inner_block != []

    if has_label do
      render_labeled_divider(assigns)
    else
      render_simple_divider(assigns)
    end
  end

  # ============================================================================
  # DIVIDER RENDERING FUNCTIONS
  # ============================================================================

  # Render simple divider
  defp render_simple_divider(assigns) do
    case assigns.orientation do
      "horizontal" ->
        divider_class = build_simple_divider_classes(assigns)
        assigns = assign(assigns, :divider_class, divider_class)

        ~H"""
        <hr class={@divider_class} {@rest} />
        """

      "vertical" ->
        divider_class = build_simple_divider_classes(assigns)
        assigns = assign(assigns, :divider_class, divider_class)

        ~H"""
        <div role="separator" aria-orientation="vertical" class={@divider_class} {@rest}></div>
        """
    end
  end

  # Render labeled divider (flex container with lines and label)
  defp render_labeled_divider(assigns) do
    container_class = build_container_classes(assigns)
    line_class = build_line_classes(assigns)
    label_class = build_label_classes(assigns)

    assigns =
      assigns
      |> assign(:container_class, container_class)
      |> assign(:line_class, line_class)
      |> assign(:label_class, label_class)

    ~H"""
    <div
      class={@container_class}
      role="separator"
      aria-orientation={if @orientation == "vertical", do: "vertical", else: nil}
      {@rest}
    >
      <div class={@line_class} aria-hidden="true"></div>
      <span class={@label_class}>
        {render_slot(@inner_block)}
      </span>
      <div class={@line_class} aria-hidden="true"></div>
    </div>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Build classes for simple hr divider
  defp build_simple_divider_classes(assigns) do
    size_config = @size_config[assigns.size][String.to_atom(assigns.orientation)]

    merge([
      size_config[:border],
      size_config[:spacing],
      border_style_classes(assigns.style),
      color_classes(assigns.variant, assigns.color),
      orientation_classes(assigns.orientation),
      assigns.class
    ])
  end

  # Build container classes for labeled divider
  defp build_container_classes(assigns) do
    size_config = @size_config[assigns.size][String.to_atom(assigns.orientation)]
    spacing = size_config[:spacing]

    base_classes =
      case assigns.orientation do
        "horizontal" -> "flex items-center w-full"
        "vertical" -> "flex flex-col items-center h-full"
      end

    merge([base_classes, spacing, assigns.class])
  end

  # Build classes for divider lines in labeled divider
  defp build_line_classes(assigns) do
    size_config = @size_config[assigns.size][String.to_atom(assigns.orientation)]
    border = size_config[:border]

    flex_class =
      case assigns.orientation do
        "horizontal" -> "flex-1 h-0"
        "vertical" -> "flex-1 w-0"
      end

    merge([
      flex_class,
      border,
      border_style_classes(assigns.style),
      color_classes(assigns.variant, assigns.color)
    ])
  end

  # Build classes for label in labeled divider
  defp build_label_classes(assigns) do
    size_config = @size_config[assigns.size]
    label_size = size_config[:label]

    merge([
      "font-medium whitespace-nowrap",
      label_size,
      label_color_classes(assigns.variant, assigns.color)
    ])
  end

  # Get border style classes
  defp border_style_classes(style) do
    @style_config[style]
  end

  # Get color classes by variant
  defp color_classes(variant, color) do
    @color_config[variant][color]
  end

  # Get label color classes by variant
  defp label_color_classes(variant, color) do
    @label_color_config[variant][color]
  end

  # Get orientation-specific classes for simple divider
  defp orientation_classes(orientation) do
    case orientation do
      "horizontal" -> "w-full"
      "vertical" -> "h-full"
    end
  end
end
