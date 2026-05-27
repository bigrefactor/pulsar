defmodule Pulsar.Components.Table do
  @moduledoc """
  Table component for displaying tabular data with Phoenix LiveView integration.

  Provides beautiful, accessible data tables with Pulsar's consistent styling patterns.
  Perfect for displaying structured data with sorting, actions, and real-time updates
  via Phoenix LiveView LiveStream.

  ## Features

  - **LiveStream Support**: Real-time data updates with Phoenix LiveView streams
  - **Multiple Variants**: solid, outline, and ghost for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl for different data densities
  - **Interactive Rows**: Row click handlers for navigation and actions
  - **Action Column**: Dedicated column for row-specific actions
  - **Visual Options**: striped rows, sticky headers, and responsive design
  - **Empty State**: Customizable empty state with default fallback
  - **Loading State**: Skeleton loading states for better UX
  - **Accessibility**: Semantic table markup with proper ARIA attributes

  ## Examples

      # Basic table
      <.table id="users" rows={@users}>
        <:col :let={user} label="Name"><%= user.name %></:col>
        <:col :let={user} label="Email"><%= user.email %></:col>
        <:col :let={user} label="Status">
          <.badge color={status_color(user.status)}>
            <%= user.status %>
          </.badge>
        </:col>
      </.table>

      # With variant and size
      <.table
        id="products"
        rows={@products}
        variant="outline"
        color="primary"
        size="sm"
      >
        <:col :let={product} label="Name"><%= product.name %></:col>
        <:col :let={product} label="Price" align="right">
          $<%= product.price %>
        </:col>
      </.table>

      # With row actions
      <.table id="posts" rows={@posts}>
        <:col :let={post} label="Title"><%= post.title %></:col>
        <:col :let={post} label="Author"><%= post.author %></:col>
        <:action :let={post}>
          <.link navigate={~p"/posts/<%= post.id %>"}>View</.link>
          <.link navigate={~p"/posts/<%= post.id %>/edit"}>Edit</.link>
        </:action>
      </.table>

      # With LiveStream
      <.table id="events" rows={@streams.events}>
        <:col :let={{_id, event}} label="Event"><%= event.name %></:col>
        <:col :let={{_id, event}} label="Time"><%= event.timestamp %></:col>
      </.table>

      # With row click handler
      <.table
        id="items"
        rows={@items}
        row_click={fn item -> JS.navigate(~p"/items/<%= item.id %>") end}
      >
        <:col :let={item} label="Name"><%= item.name %></:col>
        <:col :let={item} label="Description"><%= item.description %></:col>
      </.table>

      # With striped rows and sticky header
      <.table
        id="transactions"
        rows={@transactions}
        striped={true}
        sticky_header={true}
        variant="outline"
      >
        <:col :let={tx} label="ID"><%= tx.id %></:col>
        <:col :let={tx} label="Amount" align="right"><%= tx.amount %></:col>
      </.table>

      # With empty state
      <.table id="results" rows={@search_results}>
        <:col :let={result} label="Name"><%= result.name %></:col>
        <:col :let={result} label="Score"><%= result.score %></:col>
        <:empty>
          <div class="text-center py-8 text-muted-foreground">
            <.icon name="hero-magnifying-glass" class="mx-auto h-12 w-12 mb-4" />
            <p class="font-medium">No results found</p>
            <p class="text-sm">Try adjusting your search terms</p>
          </div>
        </:empty>
      </.table>

  ## Accessibility Features

  - **Semantic HTML**: Uses proper `<table>`, `<thead>`, `<tbody>` structure
  - **Header Semantics**: Column headers with appropriate `scope` attributes
  - **Screen Reader Support**: ARIA labels for actions and empty states
  - **Keyboard Navigation**: Proper tab order for interactive elements
  - **Loading Announcements**: Screen reader announcements for loading states
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.LiveStream
  alias Phoenix.LiveView.Rendered

  # Inline ID generator (replacing external dependencies)
  defp generate_id(prefix \\ "table") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for different table densities
  @size_config %{
    "lg" => %{
      cell: "px-6 py-3 text-lg",
      header: "px-6 py-3 text-lg font-semibold"
    },
    "md" => %{
      cell: "px-4 py-2 text-base",
      header: "px-4 py-2 text-base font-medium"
    },
    "sm" => %{
      cell: "px-3 py-1.5 text-sm",
      header: "px-3 py-1.5 text-sm font-medium"
    },
    "xl" => %{
      cell: "px-8 py-4 text-xl",
      header: "px-8 py-4 text-xl font-semibold"
    },
    "xs" => %{
      cell: "px-2 py-1 text-xs",
      header: "px-2 py-1 text-xs font-medium"
    }
  }

  # Base classes for table structure
  @table_base_classes [
    "w-full border-collapse"
  ]

  @container_base_classes [
    "relative overflow-x-auto"
  ]

  # Alignment classes for columns
  @alignment_classes %{
    "center" => "text-center",
    "left" => "text-left",
    "right" => "text-right"
  }

  # ============================================================================
  # VARIANT/COLOR CONFIGURATION MAPS
  # ============================================================================
  #
  # Map-based color system for PurgeCSS compatibility. Each variant/color
  # combination defines static class strings for optimal bundle size.
  # ============================================================================

  # Container variant classes
  @container_variant_config %{
    "ghost" => "",
    "outline" => "rounded-box border border-border",
    "solid" => "rounded-box overflow-hidden"
  }

  # Header variant/color classes
  @header_variant_config %{
    "ghost" => %{
      "danger" => "border-b border-danger/20",
      "info" => "border-b border-info/20",
      "neutral" => "border-b border-border/30",
      "primary" => "border-b border-primary/20",
      "secondary" => "border-b border-secondary/20",
      "success" => "border-b border-success/20",
      "warning" => "border-b border-warning/20"
    },
    "outline" => %{
      "danger" => "border-b-2 border-danger/30 bg-surface-1",
      "info" => "border-b-2 border-info/30 bg-surface-1",
      "neutral" => "border-b-2 border-border bg-surface-1",
      "primary" => "border-b-2 border-primary/30 bg-surface-1",
      "secondary" => "border-b-2 border-secondary/30 bg-surface-1",
      "success" => "border-b-2 border-success/30 bg-surface-1",
      "warning" => "border-b-2 border-warning/30 bg-surface-1"
    },
    "solid" => %{
      "danger" => "bg-danger text-danger-foreground",
      "info" => "bg-info text-info-foreground",
      "neutral" => "bg-neutral text-neutral-foreground",
      "primary" => "bg-primary text-primary-foreground",
      "secondary" => "bg-secondary text-secondary-foreground",
      "success" => "bg-success text-success-foreground",
      "warning" => "bg-warning text-warning-foreground"
    }
  }

  # Striped row classes by variant
  @striped_variant_config %{
    "ghost" => "[&_tbody_tr:nth-child(even)]:bg-surface-1/20",
    "outline" => "[&_tbody_tr:nth-child(even)]:bg-surface-1/30",
    "solid" => "[&_tbody_tr:nth-child(even)]:bg-surface-1/50"
  }

  # Row base classes
  @row_base_classes [
    "transition-colors duration-quick",
    "border-b border-border/50 last:border-b-0"
  ]

  # ============================================================================
  # COMPONENT ATTRIBUTES
  # ============================================================================

  # Attributes
  attr :id, :string,
    default: nil,
    doc: "Unique identifier for the table (auto-generated if not provided)"

  attr :rows, :any,
    required: true,
    doc: "List of rows to display or Phoenix.LiveView.LiveStream for real-time updates"

  # Styling attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the table"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color accent for header (mainly affects solid variant)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of table rows and padding"

  # Functional attributes
  attr :row_id, :any,
    default: nil,
    doc: "Function for generating unique row IDs"

  attr :row_click, :any,
    default: nil,
    doc: "Function called when a row is clicked"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "Function to transform row data before passing to slots"

  # Visual features
  attr :striped, :boolean,
    default: false,
    doc: "Enable zebra striping for rows"

  attr :sticky_header, :boolean,
    default: false,
    doc: "Whether header should stick to top when scrolling"

  attr :loading, :boolean,
    default: false,
    doc: "Show loading skeleton rows"

  # Layout and styling
  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  # Accessible-name affordances (WCAG 2.4.6 — see docs/a11y/table.md)
  attr :aria_label, :string,
    default: nil,
    doc: "Accessible name for the table, applied as aria-label. Use when no visible caption is appropriate."

  attr :aria_labelledby, :string,
    default: nil,
    doc: "ID of an existing element (e.g. a heading above the table) that names this table."

  attr :rest, :global

  # Slot definitions
  slot :col, required: true do
    attr :label, :string, required: true
    attr :align, :string, values: ~w(left center right)
    attr :class, :string
  end

  slot :action,
    doc: "Actions to show in the last column"

  slot :empty,
    doc: "Content to show when there are no rows"

  slot :caption,
    doc: "Optional <caption> rendered as the first child of <table>. Provides a visible table title."

  # ============================================================================
  # MAIN COMPONENT FUNCTION
  # ============================================================================

  @doc """
  Renders a styled table component.

  Self-contained table component with LiveStream support and Pulsar's styling system.
  Styling is controlled via configuration maps and Twm for intelligent
  class composition and conflict resolution.

  ## Size Behavior
  All variants respect size settings for consistent density control.

  ## LiveStream Support
  Automatically detects Phoenix.LiveView.LiveStream and applies appropriate
  attributes for real-time updates.

  ## Accessible name (WCAG 2.4.6)

  Every table should expose a programmatic name. Provide one of:

  * a `:caption` slot — rendered as `<caption>` inside `<table>`,
  * an `aria_label` attr — rendered as `aria-label`, or
  * an `aria_labelledby` attr — referencing an existing heading's id.

  Passing `aria-label` / `aria-labelledby` via global attributes also works. If
  none of these is provided, a `Logger.warning` message is emitted to nudge the
  caller; rendering is not blocked.

  ## Examples

      # Minimal table
      <.table id="users" rows={@users} aria_label="Users">
        <:col :let={user} label="Name"><%= user.name %></:col>
      </.table>

      # Visible caption
      <.table id="users" rows={@users}>
        <:caption>Active users this week</:caption>
        <:col :let={user} label="Name"><%= user.name %></:col>
      </.table>

      # Named by an existing heading
      <h2 id="orders-heading">Recent orders</h2>
      <.table id="orders" rows={@orders} aria_labelledby="orders-heading">
        <:col :let={order} label="ID"><%= order.id %></:col>
      </.table>

      # Full featured table
      <.table
        id="orders"
        rows={@orders}
        aria_label="Orders"
        variant="solid"
        color="primary"
        size="lg"
        striped={true}
        sticky_header={true}
        row_click={&navigate_to_order/1}
      >
        <:col :let={order} label="ID"><%= order.id %></:col>
        <:col :let={order} label="Customer"><%= order.customer %></:col>
        <:col :let={order} label="Total" align="right">$<%= order.total %></:col>
        <:action :let={order}>
          <.button size="sm">Edit</.button>
        </:action>
      </.table>
  """
  @spec table(map()) :: Rendered.t()
  def table(assigns) do
    warn_if_missing_accessible_name(assigns)

    # Ensure ID exists
    assigns = assign(assigns, :id, assigns[:id] || generate_id())

    # Detect LiveStream and set up row handling
    assigns = setup_stream_handling(assigns)

    # Build complete class strings using Twm
    assigns = build_table_classes(assigns)

    # `data-reflow-allowed`: WCAG 1.4.10 marks data tables as exempt
    # content. The overflow-x-auto container is the recommended pattern;
    # the data attribute lets test/integration/a11y/reflow_test.exs skip
    # the 320 px reflow check inside this scroll container.
    ~H"""
    <div class={@container_classes} data-reflow-allowed>
      <!-- Loading status announcement for screen readers -->
      <div
        :if={@loading}
        role="status"
        aria-live="polite"
        class="sr-only"
      >
        Loading rows
      </div>
      <table
        {@rest}
        aria-busy={to_string(@loading)}
        aria-label={@aria_label}
        aria-labelledby={@aria_labelledby}
        class={@table_classes}
      >
        <caption :if={@caption != []} class="text-sm text-muted-foreground text-left py-2 caption-top">
          {render_slot(@caption)}
        </caption>
        <thead class={@header_classes}>
          <tr>
            <th
              :for={col <- @col}
              scope="col"
              class={build_header_cell_classes(@size, col[:align], col[:class])}
            >
              {col[:label]}
            </th>
            <th :if={@action != []} scope="col" class={build_header_cell_classes(@size, "right", "")}>
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          :if={!@loading}
          id={"#{@id}-tbody"}
          phx-update={@is_stream && "stream"}
          class={@tbody_classes}
        >
          <!-- Empty state row for streams (shown via CSS :only-child when no data) -->
          <tr
            :if={@is_stream}
            id={"#{@id}-empty"}
            class="only:table-row hidden"
          >
            <td :if={@empty != []} colspan={length(@col) + if(@action != [], do: 1, else: 0)} class="p-8">
              {render_slot(@empty)}
            </td>
            <td :if={@empty == []} colspan={length(@col) + if(@action != [], do: 1, else: 0)} class="text-center py-12">
              <div class="text-muted-foreground">
                <svg class="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <p class="font-medium">No data available</p>
                <p class="text-sm mt-1">Data will appear here when available</p>
              </div>
            </td>
          </tr>

          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            phx-click={@row_click && @row_click.(@row_item.(row))}
            phx-hook={@row_click && ".PulsarTableRow"}
            tabindex={@row_click && "0"}
            role={@row_click && "button"}
            class={@row_classes}
          >
            <td
              :for={col <- @col}
              class={build_data_cell_classes(@size, col[:align], col[:class])}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class={build_data_cell_classes(@size, "right", "w-0")}>
              <div class="flex items-center gap-2 justify-end">
                <span :for={action <- @action}>
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
        <tbody :if={@loading} class={@tbody_classes}>
          <tr :for={_ <- 1..5} class={@row_classes}>
            <td :for={_col <- @col} class={build_data_cell_classes(@size, "left", "")}>
              <div class="animate-pulse bg-surface-1 h-4 rounded"></div>
            </td>
            <td :if={@action != []} class={build_data_cell_classes(@size, "right", "w-0")}>
              <div class="animate-pulse bg-surface-1 h-6 w-16 rounded"></div>
            </td>
          </tr>
        </tbody>
      </table>
      <!-- Empty state for lists (streams use CSS :only-child pattern above) -->
      <div :if={!@loading && !@is_stream && @rows == [] && @empty != []} class="p-8">
        {render_slot(@empty)}
      </div>
      <div :if={!@loading && !@is_stream && @rows == [] && @empty == []} class="text-center py-12">
        <div class="text-muted-foreground">
          <svg class="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <p class="font-medium">No data available</p>
          <p class="text-sm mt-1">Data will appear here when available</p>
        </div>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarTableRow">
      export default {
        mounted() {
          const el = this.el
          if (el.getAttribute("role") !== "button") return

          this._onKeydown = (e) => {
            if (e.code === "Enter" || e.key === "Enter" || e.code === "Space" || e.key === " ") {
              e.preventDefault()
              el.click()
            }
          }

          el.addEventListener("keydown", this._onKeydown)
        },

        destroyed() {
          if (this._onKeydown) {
            this.el.removeEventListener("keydown", this._onKeydown)
          }
        }
      }
    </script>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Emit a dev-time nudge when no accessible name is provided.
  #
  # Phoenix convention: caller-facing "you may be holding it wrong" nudges use
  # Logger.warning (see Phoenix.Controller.warn_if_ajax/1). Logger.info is for
  # operational lifecycle events (endpoint start). The caller's app log level
  # filter controls visibility either way.
  defp warn_if_missing_accessible_name(assigns) do
    if assigns[:caption] in [nil, []] and
         not present_string?(assigns[:aria_label]) and
         not present_string?(assigns[:aria_labelledby]) and
         not rest_has_aria_name?(assigns[:rest]) do
      require Logger

      Logger.warning("""
      <.table> rendered without an accessible name. Provide one of:
        * :caption slot
        * aria_label attr
        * aria_labelledby attr
      """)
    end

    :ok
  end

  defp rest_has_aria_name?(nil), do: false

  defp rest_has_aria_name?(rest) do
    Enum.any?(rest, fn {k, v} ->
      k_str = to_string(k)
      (k_str == "aria-label" or k_str == "aria-labelledby") and present_string?(v)
    end)
  end

  defp present_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_string?(_), do: false

  # Set up LiveStream detection and row handling
  defp setup_stream_handling(assigns) do
    case assigns.rows do
      %LiveStream{} ->
        assigns
        |> assign(:is_stream, true)
        |> assign(:row_id, assigns.row_id || fn {id, _item} -> id end)

      _ ->
        assign(assigns, :is_stream, false)
    end
  end

  # Build all CSS class strings using configuration maps
  defp build_table_classes(assigns) do
    container_classes = build_container_classes(assigns)
    table_classes = build_table_base_classes()
    header_classes = build_header_classes(assigns)
    tbody_classes = build_tbody_classes(assigns)
    row_classes = build_row_classes(assigns)

    assigns
    |> assign(:container_classes, container_classes)
    |> assign(:table_classes, table_classes)
    |> assign(:header_classes, header_classes)
    |> assign(:tbody_classes, tbody_classes)
    |> assign(:row_classes, row_classes)
  end

  # Build container classes with variant, striping, and sticky header
  defp build_container_classes(assigns) do
    [
      @container_base_classes,
      @container_variant_config[assigns.variant],
      assigns.sticky_header && "[&_thead_th]:sticky [&_thead_th]:top-0 [&_thead_th]:z-docked",
      assigns.striped && @striped_variant_config[assigns.variant],
      assigns.class
    ]
    |> Enum.filter(& &1)
    |> merge()
  end

  # Build base table classes
  defp build_table_base_classes do
    merge(@table_base_classes)
  end

  # Build header row classes using configuration maps
  defp build_header_classes(assigns) do
    merge([
      @header_variant_config[assigns.variant][assigns.color]
    ])
  end

  # Build tbody classes
  defp build_tbody_classes(_assigns) do
    merge([
      "bg-background"
    ])
  end

  # Build row classes with hover and click states
  defp build_row_classes(assigns) do
    [
      @row_base_classes,
      assigns.row_click &&
        [
          "cursor-pointer",
          "hover:bg-surface-1-hover",
          "focus:outline-none focus:ring-2 focus:ring-primary/20"
        ]
    ]
    |> Enum.filter(& &1)
    |> List.flatten()
    |> merge()
  end

  # Build header cell classes with size and alignment
  defp build_header_cell_classes(size, align, custom_class) do
    merge([
      @size_config[size][:header],
      @alignment_classes[align || "left"],
      custom_class || ""
    ])
  end

  # Build data cell classes with size and alignment
  defp build_data_cell_classes(size, align, custom_class) do
    merge([
      @size_config[size][:cell],
      @alignment_classes[align || "left"],
      custom_class || ""
    ])
  end
end
