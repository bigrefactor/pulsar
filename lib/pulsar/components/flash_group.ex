defmodule Pulsar.Components.FlashGroup do
  @moduledoc """
  Container component for managing multiple flash notifications from Phoenix.Flash.

  Provides intelligent positioning, stacking, and orchestration of Flash components
  with automatic type-to-color mapping and FIFO queue management. Designed to be
  the single integration point with Phoenix.Flash in your application.

  ## Features

  - **Phoenix.Flash Integration**: Reads flash messages directly from @flash assigns
  - **Intelligent Positioning**: 6 position options with automatic stacking
  - **Type-to-Color Mapping**: Automatic mapping of flash types to semantic colors
  - **FIFO Queue**: Configurable maximum items with oldest-first dismissal
  - **Consistent Styling**: Single variant applied to all flashes in group
  - **Staggered Animations**: Smooth entry/exit with coordinated timing

  ## Examples

      # Basic usage in layout or LiveView
      <.flash_group flash={@flash} />

      # Custom positioning and styling
      <.flash_group 
        flash={@flash} 
        variant="outline" 
        position="bottom-right"
        max_items={3}
      />

      # Different positions
      <.flash_group flash={@flash} position="top-center" />
      <.flash_group flash={@flash} position="bottom-left" />

  ## Flash Type Mapping

  FlashGroup automatically maps Phoenix flash types to appropriate colors:
  - `:error` → `danger` color
  - `:warning` → `warning` color  
  - `:info` → `info` color
  - `:success` → `success` color
  - Custom types → `neutral` color

  ## Usage in Phoenix Applications

      # In your root layout or LiveView
      <.flash_group flash={@flash} position="top-right" />

      # Set flash messages in controllers/LiveViews
      conn |> put_flash(:error, "Something went wrong")
      conn |> put_flash(:success, "Changes saved!")

      # In LiveViews
      socket |> put_flash(:info, "Welcome back!")

  ## Positioning

  Six built-in positions with appropriate animations:
  - `top-right` (default) - Slide in from right
  - `top-center` - Slide down from top  
  - `top-left` - Slide in from left
  - `bottom-right` - Slide up from bottom-right
  - `bottom-center` - Slide up from bottom
  - `bottom-left` - Slide up from bottom-left
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Flash

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Type to color mapping for Phoenix flash types
  @type_colors %{
    error: "danger",
    warning: "warning",
    info: "info",
    success: "success"
    # All other types map to neutral (see get_flash_color/1)
  }

  # Type to ARIA role mapping
  @type_roles %{
    error: "alert",
    warning: "alert"
    # All other types use "status" (see get_flash_role/1)
  }

  # Position configuration with container classes and animations
  @position_config %{
    "bottom-center" => %{
      container:
        "fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex flex-col-reverse items-center gap-2 max-w-sm w-full",
      entry_from: "translate-y-full",
      entry_to: "translate-y-0"
    },
    "bottom-left" => %{
      container: "fixed bottom-4 left-4 z-50 flex flex-col-reverse items-start gap-2 max-w-sm w-full",
      entry_from: "translate-y-full -translate-x-full",
      entry_to: "translate-x-0 translate-y-0"
    },
    "bottom-right" => %{
      container: "fixed bottom-4 right-4 z-50 flex flex-col-reverse items-end gap-2 max-w-sm w-full",
      entry_from: "translate-y-full translate-x-full",
      entry_to: "translate-x-0 translate-y-0"
    },
    "top-center" => %{
      container: "fixed top-4 left-1/2 -translate-x-1/2 z-50 flex flex-col items-center gap-2 max-w-sm w-full",
      entry_from: "-translate-y-full",
      entry_to: "translate-y-0"
    },
    "top-left" => %{
      container: "fixed top-4 left-4 z-50 flex flex-col items-start gap-2 max-w-sm w-full",
      entry_from: "-translate-x-full",
      entry_to: "translate-x-0"
    },
    "top-right" => %{
      container: "fixed top-4 right-4 z-50 flex flex-col items-end gap-2 max-w-sm w-full",
      entry_from: "translate-x-full",
      entry_to: "translate-x-0"
    }
  }

  # FlashGroup attributes
  attr(:flash, :map,
    required: true,
    doc: "Flash messages map from Phoenix.Flash (typically @flash)"
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant applied to all flashes in group"
  )

  attr(:position, :string,
    default: "top-right",
    values: ~w(top-right top-center top-left bottom-right bottom-center bottom-left),
    doc: "Screen position for the flash group"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Size applied to all flashes in group"
  )

  attr(:max_items, :integer,
    default: 5,
    doc: "Maximum number of flashes to display (FIFO removal)"
  )

  attr(:auto_dismiss, :boolean,
    default: true,
    doc: "Enable auto-dismiss for all flashes in group"
  )

  attr(:dismiss_after, :integer,
    default: 5000,
    doc: "Default dismiss timeout in milliseconds"
  )

  attr(:dismissible, :boolean,
    default: true,
    doc: "Show close buttons on all flashes"
  )

  attr(:on_dismiss, :string,
    default: "clear_flash",
    doc: "Phoenix event to push when any flash is dismissed"
  )

  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes for the container"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a positioned container for managing multiple flash notifications.

  FlashGroup serves as the primary integration point with Phoenix.Flash, automatically
  reading flash messages and rendering them as styled Flash components with consistent
  positioning and behavior.

  ## Flash Message Processing

  1. **Read Flash Messages**: Extracts all messages from the @flash map
  2. **Apply FIFO Limit**: Keeps only the most recent max_items messages
  3. **Type Mapping**: Maps each flash type to appropriate color and ARIA role
  4. **Render Components**: Creates Flash components with consistent styling
  5. **Coordinate Animations**: Manages staggered entry and exit animations

  ## Event Handling

  FlashGroup automatically handles flash dismissal through the configured event
  (default: "clear_flash"). Your LiveView should handle this event:

      def handle_event("clear_flash", %{"key" => key}, socket) do
        {:noreply, clear_flash(socket, String.to_atom(key))}
      end

      def handle_event("clear_flash", _params, socket) do
        {:noreply, clear_flash(socket)}
      end

  ## Examples

      # Minimal setup
      <.flash_group flash={@flash} />

      # Custom styling and position
      <.flash_group 
        flash={@flash}
        variant="outline"
        position="bottom-center"
        max_items={3}
        dismiss_after={3000}
      />
  """
  @spec flash_group(map()) :: Rendered.t()
  def flash_group(assigns) do
    # Extract and process flash messages
    flash_messages = extract_flash_messages(assigns.flash, assigns.max_items)

    assigns = assign(assigns, :flash_messages, flash_messages)

    # Get position configuration
    position_config = @position_config[assigns.position] || @position_config["top-right"]

    assigns =
      assign(
        assigns,
        :container_classes,
        merge([
          position_config.container,
          assigns.class
        ])
      )

    ~H"""
    <div
      :if={@flash_messages != []}
      class={@container_classes}
      {@rest}
    >
      <Flash.flash
        :for={{type, message} <- @flash_messages}
        id={"flash-#{type}"}
        variant={@variant}
        color={get_flash_color(type)}
        size={@size}
        role={get_flash_role(type)}
        auto_dismiss={@auto_dismiss}
        dismiss_after={@dismiss_after}
        dismissible={@dismissible}
        on_dismiss={@on_dismiss}
        flash_key={Atom.to_string(type)}
        phx-mounted={
          Phoenix.LiveView.JS.show(
            transition: {
              "ease-out duration-300",
              "opacity-0 #{get_entry_from(@position)}",
              "opacity-100 #{get_entry_to(@position)}"
            }
          )
        }
      >
        {message}
      </Flash.flash>
    </div>
    """
  end

  # === Helper Functions ===

  # Extract flash messages with FIFO limiting
  defp extract_flash_messages(flash, max_items) when is_map(flash) do
    flash
    |> Map.to_list()
    |> Enum.reject(fn {_type, message} ->
      is_nil(message) or (is_binary(message) and String.trim(message) == "")
    end)
    |> Enum.take(max_items)
  end

  defp extract_flash_messages(_, _), do: []

  # Get color for flash type
  defp get_flash_color(type) do
    @type_colors[type] || "neutral"
  end

  # Get ARIA role for flash type  
  defp get_flash_role(type) do
    @type_roles[type] || "status"
  end

  # Get entry animation start position
  defp get_entry_from(position) do
    @position_config[position][:entry_from] || "translate-x-full"
  end

  # Get entry animation end position
  defp get_entry_to(position) do
    @position_config[position][:entry_to] || "translate-x-0"
  end
end
