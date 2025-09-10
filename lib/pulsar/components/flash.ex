defmodule Pulsar.Components.Flash do
  @moduledoc """
  Toast-style notification component for displaying flash messages and alerts.

  Provides styled flash notifications with dismissible controls, auto-dismiss functionality,
  and smooth animations. Perfect for user feedback, status updates, and temporary notifications
  that integrate seamlessly with Phoenix.Flash.

  ## Features

  - **Multiple Variants**: solid, outline, and ghost for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Auto-dismiss**: Configurable timeout with pause-on-hover functionality
  - **Manual Dismiss**: Optional close button for user control
  - **Accessibility**: WCAG 2.1 AA compliance with proper ARIA attributes
  - **Smooth Animations**: Entry and exit transitions using Phoenix.LiveView.JS
  - **Icon Support**: Start icon slot for status indicators and custom icons

  ## Examples

      # Basic flash notification
      <.flash color="success">Changes saved successfully!</.flash>

      # Flash with close button
      <.flash color="danger" dismissible>
        Unable to save changes
      </.flash>

      # Flash with icon and auto-dismiss
      <.flash color="info" auto_dismiss dismiss_after={3000}>
        <:start_icon>
          <.icon name="hero-information-circle" variant="mini" size="sm" />
        </:start_icon>
        New feature available
      </.flash>

      # Custom styled flash
      <.flash variant="outline" color="warning" dismissible>
        <:start_icon>
          <.icon name="hero-exclamation-triangle" variant="mini" size="sm" />
        </:start_icon>
        <strong>Warning:</strong> This action cannot be undone
      </.flash>

  ## Usage with Phoenix.Flash

  While this component can be used standalone, it's designed to work seamlessly
  with FlashGroup for Phoenix.Flash integration:

      # In your layout or LiveView
      <.flash_group flash={@flash} />

  ## Accessibility Features

  - **Screen Reader Support**: Proper ARIA roles and live regions
  - **Keyboard Navigation**: Dismissible flashes are keyboard accessible
  - **Focus Management**: Focus handling for modal-style important flashes
  - **Color Independence**: Icons and text provide non-color-based communication
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS  
  # ============================================================================

  # Inline ID generator (replacing external dependencies)
  defp generate_id(prefix \\ "flash") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Size configuration for flash components
  @size_config %{
    "lg" => %{
      close_button: "h-6 w-6 p-1",
      container: "p-4 text-base gap-3 rounded-lg",
      icon: "h-6 w-6"
    },
    "md" => %{
      close_button: "h-5 w-5 p-0.5",
      container: "p-3 text-sm gap-2 rounded-md",
      icon: "h-5 w-5"
    },
    "sm" => %{
      close_button: "h-4 w-4 p-0.5",
      container: "p-2 text-sm gap-2 rounded-md",
      icon: "h-4 w-4"
    }
  }

  # Base flash styling classes
  @flash_base_classes [
    "flex items-start justify-between",
    "font-medium shadow-md",
    "transition-all duration-200 ease-in-out",
    "focus-within:outline-none focus-within:ring-2",
    "focus-within:ring-current focus-within:ring-offset-2"
  ]

  # Color configuration for each variant
  @color_config %{
    "ghost" => %{
      "danger" => "text-danger bg-danger/10 dark:text-dark-danger dark:bg-dark-danger/10",
      "info" => "text-info bg-info/10 dark:text-dark-info dark:bg-dark-info/10",
      "neutral" => "text-foreground bg-surface-1 dark:text-dark-foreground dark:bg-dark-surface-1",
      "primary" => "text-primary bg-primary/10 dark:text-dark-primary dark:bg-dark-primary/10",
      "secondary" => "text-secondary bg-secondary/10 dark:text-dark-secondary dark:bg-dark-secondary/10",
      "success" => "text-success bg-success/10 dark:text-dark-success dark:bg-dark-success/10",
      "warning" => "text-warning bg-warning/10 dark:text-dark-warning dark:bg-dark-warning/10"
    },
    "outline" => %{
      "danger" =>
        "border border-danger bg-background text-danger dark:border-dark-danger dark:bg-dark-background dark:text-dark-danger",
      "info" =>
        "border border-info bg-background text-info dark:border-dark-info dark:bg-dark-background dark:text-dark-info",
      "neutral" =>
        "border border-neutral bg-background text-foreground dark:border-dark-neutral dark:bg-dark-background dark:text-dark-foreground",
      "primary" =>
        "border border-primary bg-background text-primary dark:border-dark-primary dark:bg-dark-background dark:text-dark-primary",
      "secondary" =>
        "border border-secondary bg-background text-secondary dark:border-dark-secondary dark:bg-dark-background dark:text-dark-secondary",
      "success" =>
        "border border-success bg-background text-success dark:border-dark-success dark:bg-dark-background dark:text-dark-success",
      "warning" =>
        "border border-warning bg-background text-warning dark:border-dark-warning dark:bg-dark-background dark:text-dark-warning"
    },
    "solid" => %{
      "danger" => "bg-danger text-danger-foreground dark:bg-dark-danger dark:text-dark-danger-foreground",
      "info" => "bg-info text-info-foreground dark:bg-dark-info dark:text-dark-info-foreground",
      "neutral" => "bg-neutral text-neutral-foreground dark:bg-dark-neutral dark:text-dark-neutral-foreground",
      "primary" => "bg-primary text-primary-foreground dark:bg-dark-primary dark:text-dark-primary-foreground",
      "secondary" =>
        "bg-secondary text-secondary-foreground dark:bg-dark-secondary dark:text-dark-secondary-foreground",
      "success" => "bg-success text-success-foreground dark:bg-dark-success dark:text-dark-success-foreground",
      "warning" => "bg-warning text-warning-foreground dark:bg-dark-warning dark:text-dark-warning-foreground"
    }
  }

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the flash"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the flash"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Size of the flash notification"
  )

  # Flash-specific functionality
  attr(:dismissible, :boolean,
    default: true,
    doc: "Show close button for manual dismissal"
  )

  attr(:auto_dismiss, :boolean,
    default: true,
    doc: "Automatically dismiss after timeout"
  )

  attr(:dismiss_after, :integer,
    default: 5000,
    doc: "Milliseconds before auto-dismiss (default 5 seconds)"
  )

  attr(:on_dismiss, :string,
    default: nil,
    doc: "Phoenix event to push when flash is dismissed"
  )

  # State and behavior
  attr(:flash_key, :string,
    default: nil,
    doc: "Key for identifying this flash message in Phoenix.Flash"
  )

  # ARIA and accessibility
  attr(:role, :string,
    default: "status",
    values: ~w(alert status),
    doc: "ARIA role - 'alert' for urgent messages, 'status' for general updates"
  )

  attr(:live, :string,
    default: "polite",
    values: ~w(polite assertive off),
    doc: "ARIA live region behavior"
  )

  # Core attributes
  attr(:id, :string,
    default: nil,
    doc: "Flash ID"
  )

  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block,
    required: true,
    doc: "Flash message content"
  )

  slot(:start_icon,
    required: false,
    doc: "Icon displayed at the start of the flash"
  )

  @doc """
  Renders a styled flash notification component.

  Self-contained flash component with auto-dismiss functionality and accessibility
  built-in. Styling is controlled via configuration maps and TailwindMerge for 
  intelligent class composition and conflict resolution.

  ## Auto-dismiss Behavior

  When `auto_dismiss` is true:
  - Timer starts only when flash becomes visible (IntersectionObserver)
  - Timer pauses on hover and resumes on mouse leave
  - Timer can be interrupted by manual dismiss
  - Triggers smooth exit animation before removal

  ## Accessibility

  - Uses `role="status"` for general updates, `role="alert"` for urgent messages
  - Includes `aria-live` regions for screen reader announcements
  - Close button is keyboard accessible with proper ARIA labels
  - Color-independent communication through icons and text

  ## Examples

      # Error flash with icon
      <.flash variant="solid" color="danger" role="alert">
        <:start_icon>
          <.icon name="hero-exclamation-circle" variant="mini" />
        </:start_icon>
        Failed to save changes
      </.flash>
  """
  @spec flash(map()) :: Rendered.t()
  def flash(assigns) do
    # Ensure ID exists for hook functionality
    assigns = assign(assigns, :id, assigns[:id] || generate_id())

    # Build complete class string using TailwindMerge
    assigns =
      assign(
        assigns,
        :merged_classes,
        merge([
          base_flash_classes(),
          size_classes(assigns.size),
          color_classes(assigns.variant, assigns.color),
          assigns.class
        ])
      )

    ~H"""
    <div
      id={@id}
      phx-hook=".PulsarFlash"
      role={@role}
      aria-live={@live}
      class={@merged_classes}
      data-auto-dismiss={data_tf(@auto_dismiss)}
      data-dismiss-after={@dismiss_after}
      data-flash-key={@flash_key}
      data-on-dismiss={@on_dismiss}
      {@rest}
    >
      <div class="flex items-start gap-2 flex-1 min-w-0">
        <div :if={@start_icon != []} class={icon_size_classes(@size)}>
          {render_slot(@start_icon)}
        </div>
        <div class="flex-1 min-w-0">
          {render_slot(@inner_block)}
        </div>
      </div>

      <button
        :if={@dismissible}
        type="button"
        class={close_button_classes(@size)}
        aria-label="Dismiss"
        phx-click={
          Phoenix.LiveView.JS.hide(
            to: "##{@id}",
            transition: {"ease-in duration-200", "opacity-100 translate-y-0", "opacity-0 -translate-y-2"}
          )
          |> push_dismiss_event(@on_dismiss, @flash_key)
        }
      >
        <svg viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
        </svg>
      </button>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarFlash">
      export default {
        mounted() {
          // Initialize timer state
          this.dismissAfter = parseInt(this.el.dataset.dismissAfter || 5000)
          this.autoDismiss = this.el.dataset.autoDismiss === "true"
          this.onDismissEvent = this.el.dataset.onDismiss
          this.flashKey = this.el.dataset.flashKey
          this.remainingTime = this.dismissAfter
          this.timer = null
          this.isVisible = false
          this.isPaused = false
          this.startTime = null

          // Set up IntersectionObserver for visibility detection
          this.observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
              if (entry.isIntersecting && !this.isVisible && this.autoDismiss) {
                this.isVisible = true
                this.startTimer()
              }
            })
          }, { threshold: 0.1 })

          this.observer.observe(this.el)
          
          // Start timer immediately if already visible
          if (this.autoDismiss && !this.timer) {
            const rect = this.el.getBoundingClientRect()
            const vw = window.innerWidth || document.documentElement.clientWidth
            const vh = window.innerHeight || document.documentElement.clientHeight
            const inViewport = rect.bottom > 0 && rect.right > 0 && rect.top < vh && rect.left < vw
            const style = window.getComputedStyle(this.el)
            const isDisplayed = style.display !== 'none' && style.visibility !== 'hidden' && parseFloat(style.opacity || '1') > 0
            if (inViewport && isDisplayed) {
              this.isVisible = true
              this.startTimer()
            }
          }
          
          // Hover handlers for pause/resume
          this._onMouseEnter = () => this.pause()
          this._onMouseLeave = () => this.resume()
          this.el.addEventListener('mouseenter', this._onMouseEnter)
          this.el.addEventListener('mouseleave', this._onMouseLeave)
          
          // Focus handlers for pause/resume (accessibility)
          this._onFocusIn = () => this.pause()
          this._onFocusOut = () => this.resume()
          this.el.addEventListener('focusin', this._onFocusIn)
          this.el.addEventListener('focusout', this._onFocusOut)
        },

        startTimer() {
          if (!this.autoDismiss || this.timer) return

          this.startTime = Date.now()
          this.timer = setTimeout(() => {
            this.dismiss()
          }, this.remainingTime)
        },

        pause() {
          if (!this.timer || !this.autoDismiss) return

          clearTimeout(this.timer)
          this.remainingTime -= (Date.now() - this.startTime)
          this.timer = null
          this.isPaused = true
        },

        resume() {
          if (!this.isPaused || !this.autoDismiss) return

          this.isPaused = false
          this.startTimer()
        },

        dismiss() {
          // Clear timer
          if (this.timer) {
            clearTimeout(this.timer)
            this.timer = null
          }

          // Trigger exit animation and removal

          // Apply exit transition
          this.el.style.transition = "opacity 200ms ease-in, transform 200ms ease-in"
          this.el.style.opacity = "0"
          this.el.style.transform = "translateY(-8px)"

          // Push dismiss event after animation
          setTimeout(() => {
            if (this.onDismissEvent && this.flashKey) {
              this.pushEvent(this.onDismissEvent, {key: this.flashKey})
            } else if (this.onDismissEvent) {
              this.pushEvent(this.onDismissEvent, {})
            }
          }, 200)
        },

        updated() {
          // Update data attributes if they've changed
          const newDismissAfter = parseInt(this.el.dataset.dismissAfter || 5000)
          const newAutoDismiss = this.el.dataset.autoDismiss === "true"
          
          if (newDismissAfter !== this.dismissAfter) {
            this.dismissAfter = newDismissAfter
            if (!this.isVisible) {
              this.remainingTime = this.dismissAfter
            }
          }
          
          if (newAutoDismiss !== this.autoDismiss) {
            this.autoDismiss = newAutoDismiss
            if (!this.autoDismiss && this.timer) {
              clearTimeout(this.timer)
              this.timer = null
            } else if (this.autoDismiss && this.isVisible && !this.timer) {
              this.startTimer()
            }
          }
        },

        destroyed() {
          // Clean up observers and timers
          if (this.observer) {
            this.observer.disconnect()
          }
          if (this.timer) {
            clearTimeout(this.timer)
          }
          
          // Remove event listeners
          if (this._onMouseEnter) this.el.removeEventListener('mouseenter', this._onMouseEnter)
          if (this._onMouseLeave) this.el.removeEventListener('mouseleave', this._onMouseLeave)
          if (this._onFocusIn) this.el.removeEventListener('focusin', this._onFocusIn)
          if (this._onFocusOut) this.el.removeEventListener('focusout', this._onFocusOut)
        }
      }
    </script>
    """
  end

  # === Helper Functions ===

  # Base styles shared by all flashes
  defp base_flash_classes do
    @flash_base_classes
  end

  # Size-specific classes
  defp size_classes(size) do
    @size_config[size][:container]
  end

  # Color classes by variant
  defp color_classes(variant, color) do
    get_in(@color_config, [variant, color]) || get_in(@color_config, ["solid", "neutral"])
  end

  # Icon size classes based on flash size
  defp icon_size_classes(size) do
    @size_config[size][:icon]
  end

  # Close button size classes based on flash size
  defp close_button_classes(size) do
    merge([
      "flex-shrink-0 rounded-md p-1 transition-colors",
      "hover:bg-black/10 dark:hover:bg-white/10",
      "focus:outline-none focus:ring-2 focus:ring-current focus:ring-offset-2",
      @size_config[size][:close_button]
    ])
  end

  # Helper for pushing dismiss events
  defp push_dismiss_event(js, nil, _flash_key), do: js

  defp push_dismiss_event(js, event, flash_key) when is_binary(event) do
    if flash_key do
      JS.push(js, event, value: %{key: flash_key})
    else
      JS.push(js, event)
    end
  end

  # Data attribute helpers
  defp data_tf(true), do: "true"
  defp data_tf(false), do: "false"
  defp data_tf(nil), do: "false"
end
