defmodule Pulsar.Components.FlashGroup do
  @moduledoc """
  Container component for managing multiple flash notifications from Phoenix.Flash.

   Provides intelligent positioning, stacking, and orchestration of Flash components
   with automatic type-to-color mapping and item limiting. Designed to be
   the single integration point with Phoenix.Flash in your application.

  ## Features

  - **Phoenix.Flash Integration**: Reads flash messages directly from @flash assigns
  - **Intelligent Positioning**: 6 position options with automatic stacking
  - **Type-to-Color Mapping**: Automatic mapping of flash types to semantic colors
   - **Item Limiting**: Configurable maximum number of flash messages to display
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

   ## Optional Event Handler

   FlashGroup can optionally push dismiss events for tracking or custom behavior.
   Most applications don't need this since flash messages auto-clear on navigation.

       defmodule MyAppWeb.PageLive do
         use MyAppWeb, :live_view

         def render(assigns) do
           ~H\"\"\"
           <.flash_group flash={@flash} on_dismiss="track_dismissal" />
           <!-- your page content -->
           \"\"\"
         end

         # Optional: Handle dismissal events for analytics/tracking
         def handle_event("track_dismissal", %{"key" => key}, socket) do
           # Safe atom handling to prevent atom exhaustion attacks
           key_atom =
             try do
               String.to_existing_atom(key)
             rescue
               ArgumentError -> nil
             end

           # Track the dismissal (optional)
           case key_atom do
             nil -> MyApp.Analytics.track("flash_dismissed", %{type: "unknown"})
             k when is_atom(k) -> MyApp.Analytics.track("flash_dismissed", %{type: k})
           end

           {:noreply, socket}
         end
       end

   ## Controller Integration

   FlashGroup works seamlessly with controller-set flashes:

       defmodule MyAppWeb.UserController do
         use MyAppWeb, :controller

         def create(conn, %{"user" => user_params}) do
           case Users.create_user(user_params) do
             {:ok, user} ->
               conn
               |> put_flash(:success, "User created successfully!")
                 |> redirect(to: "/users/\#{user.id}")

             {:error, %Ecto.Changeset{} = changeset} ->
               conn
               |> put_flash(:error, "Please check the errors below")
               |> render(:new, changeset: changeset)
         end
       end

   ## Testing FlashGroup Components

   ### Testing Flash Messages in LiveView Tests

       test "displays flash messages with appropriate icons and colors", %{conn: conn} do
         {:ok, view, _html} = live(conn, "/")
         
         # Set flash messages
         view |> put_flash(:success, "Changes saved!")
         view |> put_flash(:error, "Something went wrong")
         
         # Assert flash messages are displayed
         assert has_element?(view, "[role='status']", "Changes saved!")
         assert has_element?(view, "[role='alert']", "Something went wrong") 
         
         # Assert icons are present
         assert has_element?(view, ".hero-check-circle") # success icon
         assert has_element?(view, ".hero-x-circle")     # error icon
       end

   ### Testing Flash Dismissal

       test "handles flash dismissal correctly", %{conn: conn} do
         {:ok, view, _html} = live(conn, "/")
         
         view |> put_flash(:info, "Test message")
         assert has_element?(view, "[role='status']", "Test message")
         
         # Simulate manual dismiss
         view |> element("[aria-label='Dismiss']") |> render_click()
         
         # Flash should be cleared
         refute has_element?(view, "[role='status']", "Test message")
       end

   ### Testing Custom Configuration

       test "respects custom positioning and styling", %{conn: conn} do
         {:ok, view, _html} = live(conn, "/custom-flash")
         
         view |> put_flash(:warning, "Custom styled flash")
         
         # Assert custom positioning
         assert has_element?(view, ".bottom-4.left-4")   # bottom-left position
         assert has_element?(view, ".z-30")              # custom z-index
         
         # Assert custom variant
         assert has_element?(view, ".border.border-warning") # outline variant
       end

   ### Helper Functions for Testing

   Add these helpers to your test support modules:

       def put_flash(view, type, message) do
         Phoenix.LiveViewTest.put_flash(view, type, message)
       end

       def assert_flash(view, type, message) do
         role = if type in [:error, :warning], do: "alert", else: "status"
         assert has_element?(view, "[role='\#{role}']", message)
       end

       def refute_flash(view, type, message) do
         role = if type in [:error, :warning], do: "alert", else: "status" 
         refute has_element?(view, "[role='\#{role}']", message)
       end
       end

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
  alias Pulsar.Components.Icon

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

  # Type to icon mapping
  @type_icons %{
    error: "hero-x-circle",
    warning: "hero-exclamation-triangle",
    info: "hero-information-circle",
    success: "hero-check-circle"
    # All other types use "hero-bell" (see get_flash_icon/1)
  }

  # Position configuration with container classes and animations (without z-index)
  @position_config %{
    "bottom-center" => %{
      container: "fixed bottom-4 left-1/2 -translate-x-1/2 flex flex-col-reverse items-center gap-2 max-w-sm w-full",
      entry_from: "translate-y-full",
      entry_to: "translate-y-0"
    },
    "bottom-left" => %{
      container: "fixed bottom-4 left-4 flex flex-col-reverse items-start gap-2 max-w-sm w-full",
      entry_from: "translate-y-full -translate-x-full",
      entry_to: "translate-x-0 translate-y-0"
    },
    "bottom-right" => %{
      container: "fixed bottom-4 right-4 flex flex-col-reverse items-end gap-2 max-w-sm w-full",
      entry_from: "translate-y-full translate-x-full",
      entry_to: "translate-x-0 translate-y-0"
    },
    "top-center" => %{
      container: "fixed top-4 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 max-w-sm w-full",
      entry_from: "-translate-y-full",
      entry_to: "translate-y-0"
    },
    "top-left" => %{
      container: "fixed top-4 left-4 flex flex-col items-start gap-2 max-w-sm w-full",
      entry_from: "-translate-x-full",
      entry_to: "translate-x-0"
    },
    "top-right" => %{
      container: "fixed top-4 right-4 flex flex-col items-end gap-2 max-w-sm w-full",
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
    doc: "Maximum number of flashes to display (limits displayed items)"
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

  attr(:stagger_delay, :integer,
    default: 100,
    doc: "Milliseconds between staggered flash animations (0 to disable)"
  )

  attr(:on_dismiss, :string,
    default: "clear_flash",
    doc: "Phoenix event to push when any flash is dismissed"
  )

  attr(:z_index, :string,
    default: "50",
    values: ~w(10 20 30 40 50 auto),
    doc: "Z-index for the flash group (10=dropdown, 20=sticky, 30=header, 40=overlay, 50=modal)"
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
   2. **Apply Item Limit**: Limits displayed messages to max_items (Phoenix.Flash stores one message per type)
   3. **Type Mapping**: Maps each flash type to appropriate color and ARIA role
   4. **Render Components**: Creates Flash components with consistent styling
   5. **Coordinate Animations**: Manages staggered entry and exit animations

  ## Event Handling

  FlashGroup automatically handles flash dismissal through the configured event
  (default: "clear_flash"). Your LiveView should handle this event:

      def handle_event("clear_flash", %{"key" => key}, socket) do
        # Safe atom handling to prevent atom exhaustion attacks
        key_atom =
          try do
            String.to_existing_atom(key)
          rescue
            ArgumentError -> :info
          end

        {:noreply, clear_flash(socket, key_atom)}
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

    # Generate unique component ID to prevent collisions
    component_id = System.unique_integer([:positive])

    assigns =
      assigns
      |> assign(:flash_messages, flash_messages)
      |> assign(:component_id, component_id)

    # Get position configuration with validation
    position_config = get_position_config(assigns.position)

    assigns =
      assign(
        assigns,
        :container_classes,
        merge([
          position_config.container,
          get_z_index_class(assigns.z_index),
          # Allow click-through container
          "pointer-events-none",
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
        :for={{{type, message}, index} <- Enum.with_index(@flash_messages)}
        id={"flash-#{@component_id}-#{type}"}
        variant={@variant}
        color={get_flash_color(type)}
        size={@size}
        role={get_flash_role(type)}
        auto_dismiss={@auto_dismiss}
        dismiss_after={@dismiss_after}
        dismissible={@dismissible}
        on_dismiss={@on_dismiss}
        flash_key={normalize_flash_key(type)}
        style={get_animation_style(index, @stagger_delay)}
        phx-mounted={
          Phoenix.LiveView.JS.show(
            transition: {
              "ease-out duration-200",
              "opacity-0 #{get_entry_from(@position)}",
              "opacity-100 #{get_entry_to(@position)}"
            }
          )
        }
      >
        <:start_icon>
          <Icon.icon name={get_flash_icon(type)} variant="mini" color={get_flash_color(type)} />
        </:start_icon>
        {message}
      </Flash.flash>
    </div>
    """
  end

  # === Helper Functions ===

  # Extract flash messages with item limiting and consistent ordering
  # Note: Phoenix.Flash stores one message per type (not a true queue),
  # so max_items effectively limits how many different flash types are shown
  defp extract_flash_messages(flash, max_items) when is_map(flash) do
    flash
    |> Map.to_list()
    |> Enum.reject(fn {_type, message} ->
      is_nil(message) or (is_binary(message) and String.trim(message) == "")
    end)
    |> Enum.sort_by(fn {type, _message} -> flash_priority(type) end)
    |> Enum.take(max_items)
  end

  defp extract_flash_messages(_, _), do: []

  # Define flash message display priority (lower numbers show first)
  defp flash_priority(:error), do: 1
  defp flash_priority(:warning), do: 2
  defp flash_priority(:info), do: 3
  defp flash_priority(:success), do: 4
  defp flash_priority(_), do: 5

  # Get color for flash type
  defp get_flash_color(type) do
    @type_colors[normalize_type(type)] || "neutral"
  end

  # Get ARIA role for flash type
  defp get_flash_role(type) do
    @type_roles[normalize_type(type)] || "status"
  end

  # Get entry animation start position
  defp get_entry_from(position) do
    get_position_config(position)[:entry_from]
  end

  # Get position configuration with validation and fallback
  defp get_position_config(position) do
    case @position_config[position] do
      nil ->
        require Logger

        Logger.warning("Invalid flash group position '#{position}', falling back to 'top-right'")
        @position_config["top-right"]

      config ->
        config
    end
  end

  # Get entry animation end position
  defp get_entry_to(position) do
    get_position_config(position)[:entry_to]
  end

  # Get icon for flash type
  defp get_flash_icon(type) do
    @type_icons[normalize_type(type)] || "hero-bell"
  end

  # Normalize flash type to atom for consistent lookups
  defp normalize_type(type) when is_atom(type), do: type

  defp normalize_type(type) when is_binary(type) do
    String.to_existing_atom(type)
  rescue
    ArgumentError -> :info
  end

  defp normalize_type(_), do: :info

  # Normalize flash key to string for flash_key attribute
  defp normalize_flash_key(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_flash_key(type) when is_binary(type), do: type
  defp normalize_flash_key(_), do: "info"

  # Get animation style with stagger delay
  defp get_animation_style(index, stagger_delay) when stagger_delay > 0 do
    delay_ms = index * stagger_delay
    "transition-delay: #{delay_ms}ms;"
  end

  defp get_animation_style(_, _), do: nil

  # Get z-index class
  defp get_z_index_class("auto"), do: "z-auto"

  defp get_z_index_class(z_index) when z_index in ~w(10 20 30 40 50) do
    "z-#{z_index}"
  end

  defp get_z_index_class(_), do: "z-50"
end
