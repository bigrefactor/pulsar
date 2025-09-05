defmodule Pulsar.Components.List do
  @moduledoc """
  List component for displaying key-value data pairs with semantic HTML.

  Provides styled lists for displaying structured data with consistent theming.
  Perfect for showing entity details, metadata, or any key-value information 
  with proper accessibility.

  ## Features

  - **Semantic HTML**: Uses `<dl>`, `<dt>`, `<dd>` for proper accessibility
  - **Multiple Variants**: solid, outline, and ghost for different visual emphasis
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Visual Options**: striped rows, dividers, and spacing controls
  - **Flexible Layout**: Apply any Tailwind classes for custom layouts

  ## Examples

      # Basic list
      <.list>
        <:item title="Name">John Doe</:item>
        <:item title="Email">john@example.com</:item>
        <:item title="Role">Administrator</:item>
      </.list>

      # With variant and color
      <.list variant="outline" color="primary">
        <:item title="Project">Phoenix App</:item>
        <:item title="Version">1.7.0</:item>
        <:item title="Status">
          <.badge color="success">Active</.badge>
        </:item>
      </.list>

      # Custom layouts with Tailwind classes
      # Horizontal cards
      <.list class="flex flex-row flex-wrap gap-4" size="md">
        <:item title="Orders">1,234</:item>
        <:item title="Revenue">$45,678</:item>
        <:item title="Customers">890</:item>
      </.list>

      # Grid layout (responsive 2-column)
      <.list class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <:item title="First Name">Jane</:item>
        <:item title="Last Name">Smith</:item>
        <:item title="Department">Engineering</:item>
        <:item title="Location">New York</:item>
      </.list>

      # With visual features
      <.list striped={true} dividers={true} variant="outline">
        <:item title="Created">2024-01-15</:item>
        <:item title="Modified">2024-03-20</:item>
        <:item title="Author">System Admin</:item>
      </.list>
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for container, items, and typography
  @size_config %{
    "lg" => %{
      container: "text-lg",
      content: "text-lg",
      item: "py-3 px-5 gap-5",
      title: "font-semibold text-lg"
    },
    "md" => %{
      container: "text-base",
      content: "text-base",
      item: "py-2 px-4 gap-4",
      title: "font-medium text-base"
    },
    "sm" => %{
      container: "text-sm",
      content: "text-sm",
      item: "py-1.5 px-3 gap-3",
      title: "font-medium text-sm"
    },
    "xl" => %{
      container: "text-xl",
      content: "text-xl",
      item: "py-4 px-6 gap-6",
      title: "font-semibold text-xl"
    },
    "xs" => %{
      container: "text-xs",
      content: "text-xs",
      item: "py-1 px-2 gap-2",
      title: "font-medium text-xs"
    }
  }

  # Base classes for the list container
  @container_base_classes [
    "dl-list"
  ]

  # Base classes for list items
  @item_base_classes [
    "dl-item flex"
  ]

  # Variant-specific classes for container
  @variant_container_classes %{
    "ghost" => [],
    "outline" => [
      "border rounded-lg"
    ],
    "solid" => [
      "rounded-lg"
    ]
  }

  # Color configuration for each variant
  @color_config %{
    "ghost" => %{
      "danger" => %{
        container: "",
        title: "text-danger dark:text-dark-danger"
      },
      "info" => %{
        container: "",
        title: "text-info dark:text-dark-info"
      },
      "neutral" => %{
        container: "",
        title: "text-foreground dark:text-dark-foreground"
      },
      "primary" => %{
        container: "",
        title: "text-primary dark:text-dark-primary"
      },
      "secondary" => %{
        container: "",
        title: "text-secondary dark:text-dark-secondary"
      },
      "success" => %{
        container: "",
        title: "text-success dark:text-dark-success"
      },
      "warning" => %{
        container: "",
        title: "text-warning dark:text-dark-warning"
      }
    },
    "outline" => %{
      "danger" => %{
        container: "border-danger dark:border-dark-danger bg-background dark:bg-dark-background",
        hover: "hover:bg-danger/5 dark:hover:bg-dark-danger/10",
        title: "text-danger dark:text-dark-danger"
      },
      "info" => %{
        container: "border-info dark:border-dark-info bg-background dark:bg-dark-background",
        hover: "hover:bg-info/5 dark:hover:bg-dark-info/10",
        title: "text-info dark:text-dark-info"
      },
      "neutral" => %{
        container: "border-border dark:border-dark-border bg-background dark:bg-dark-background",
        hover: "hover:bg-muted/50 dark:hover:bg-dark-muted/50",
        title: "text-foreground dark:text-dark-foreground"
      },
      "primary" => %{
        container: "border-primary dark:border-dark-primary bg-background dark:bg-dark-background",
        hover: "hover:bg-primary/5 dark:hover:bg-dark-primary/10",
        title: "text-primary dark:text-dark-primary"
      },
      "secondary" => %{
        container: "border-secondary dark:border-dark-secondary bg-background dark:bg-dark-background",
        hover: "hover:bg-secondary/5 dark:hover:bg-dark-secondary/10",
        title: "text-secondary dark:text-dark-secondary"
      },
      "success" => %{
        container: "border-success dark:border-dark-success bg-background dark:bg-dark-background",
        hover: "hover:bg-success/5 dark:hover:bg-dark-success/10",
        title: "text-success dark:text-dark-success"
      },
      "warning" => %{
        container: "border-warning dark:border-dark-warning bg-background dark:bg-dark-background",
        hover: "hover:bg-warning/5 dark:hover:bg-dark-warning/10",
        title: "text-warning dark:text-dark-warning"
      }
    },
    "solid" => %{
      "danger" => %{
        container: "bg-danger/5 dark:bg-dark-danger/10 border border-danger/20 dark:border-dark-danger/30",
        title: "text-danger dark:text-dark-danger"
      },
      "info" => %{
        container: "bg-info/5 dark:bg-dark-info/10 border border-info/20 dark:border-dark-info/30",
        title: "text-info dark:text-dark-info"
      },
      "neutral" => %{
        container: "bg-muted dark:bg-dark-muted border border-border dark:border-dark-border",
        title: "text-foreground dark:text-dark-foreground"
      },
      "primary" => %{
        container: "bg-primary/5 dark:bg-dark-primary/10 border border-primary/20 dark:border-dark-primary/30",
        title: "text-primary dark:text-dark-primary"
      },
      "secondary" => %{
        container: "bg-secondary/5 dark:bg-dark-secondary/10 border border-secondary/20 dark:border-dark-secondary/30",
        title: "text-secondary dark:text-dark-secondary"
      },
      "success" => %{
        container: "bg-success/5 dark:bg-dark-success/10 border border-success/20 dark:border-dark-success/30",
        title: "text-success dark:text-dark-success"
      },
      "warning" => %{
        container: "bg-warning/5 dark:bg-dark-warning/10 border border-warning/20 dark:border-dark-warning/30",
        title: "text-warning dark:text-dark-warning"
      }
    }
  }

  # ============================================================================
  # COMPONENT ATTRIBUTES
  # ============================================================================

  attr :variant, :string,
    default: "ghost",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the list"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the list"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size affecting spacing and typography"

  attr :striped, :boolean,
    default: false,
    doc: "Enable zebra striping for rows"

  attr :dividers, :boolean,
    default: false,
    doc: "Show dividers between items"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global

  slot :item, required: true do
    attr :title, :string,
      required: true,
      doc: "The label/key for the item"

    attr :class, :string, doc: "Additional classes for the item"
  end

  # ============================================================================
  # COMPONENT IMPLEMENTATION
  # ============================================================================

  @doc """
  Renders a semantic list component.

  Uses definition list markup (`<dl>`, `<dt>`, `<dd>`) for proper accessibility
  and screen reader support. Supports multiple variants and visual options.
  """
  def list(assigns) do
    # Build container classes
    container_classes = build_container_classes(assigns)

    # Build item classes
    item_base = build_item_base_classes(assigns)

    assigns =
      assigns
      |> assign(:container_classes, container_classes)
      |> assign(:item_base, item_base)

    ~H"""
    <dl class={@container_classes} {@rest}>
      <div
        :for={{item, index} <- Enum.with_index(Map.get(assigns, :item, []))}
        class={
          merge([
            @item_base,
            item_variant_classes(@variant, @color, index, @striped),
            @dividers && index > 0 && "border-t border-border dark:border-dark-border",
            item[:class] || ""
          ])
        }
      >
        <dt class={title_classes(@variant, @color, @size)}>
          {item.title}
        </dt>
        <dd class={content_classes(@size)}>
          {render_slot(item)}
        </dd>
      </div>
    </dl>
    """
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  defp build_container_classes(assigns) do
    size_classes = Map.get(@size_config, assigns.size).container
    variant_classes = Map.get(@variant_container_classes, assigns.variant)
    color_config = get_in(@color_config, [assigns.variant, assigns.color])
    color_classes = Map.get(color_config, :container, "")

    merge([
      @container_base_classes,
      size_classes,
      variant_classes,
      color_classes,
      assigns.class
    ])
  end

  defp build_item_base_classes(assigns) do
    size_config = Map.get(@size_config, assigns.size)
    item_spacing = Map.get(size_config, :item)

    merge([
      @item_base_classes,
      item_spacing,
      "flex-col"
    ])
  end

  defp item_variant_classes(variant, color, index, striped) do
    color_config = get_in(@color_config, [variant, color])
    hover_classes = Map.get(color_config, :hover, "")

    striped_classes =
      if striped && rem(index, 2) == 1 do
        case variant do
          "ghost" -> "bg-muted/30 dark:bg-dark-muted/20"
          "outline" -> "bg-muted/20 dark:bg-dark-muted/10"
          "solid" -> "bg-foreground/5 dark:bg-dark-foreground/5"
        end
      else
        ""
      end

    merge([hover_classes, striped_classes])
  end

  defp title_classes(variant, color, size) do
    size_config = Map.get(@size_config, size)
    base_title = Map.get(size_config, :title)

    color_config = get_in(@color_config, [variant, color])
    color_classes = Map.get(color_config, :title, "")

    merge([base_title, color_classes])
  end

  defp content_classes(size) do
    size_config = Map.get(@size_config, size)
    Map.get(size_config, :content)
  end
end
