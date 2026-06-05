defmodule Pulsar.Components.Alert do
  @moduledoc """
  Inline alert banner for in-content status messages.

  Displays a non-toast, in-content banner for form-level and page-level messages
  in success, info, warning, and danger styles. For transient toast
  notifications, use `flash` instead.

  ## Features

  - **Variants**: solid, outline, and ghost (tinted)
  - **Color palette**: semantic colors, each with an auto-selected status icon
  - **Title + description**: optional title with body text or rich content
  - **Actions**: optional right-aligned action buttons
  - **Dismissible**: optional close button with a smooth exit
  - **Accessibility**: opt-in `role` for dynamically shown alerts

  ## Examples

      # Simplest — info color, auto icon, ghost tint
      <.alert description="Your changes have been saved." />

      # Title + description
      <.alert color="warning" title="Heads up" description="Your trial ends in 3 days." />

      # Rich body via inner_block (used when description is omitted)
      <.alert color="info" title="New version available">
        A new version is ready. Reload to update.
      </.alert>
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Inline ID generator (auto-assigned when the caller omits one).
  defp generate_id(prefix \\ "alert") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Per-size container padding/text/gap/radius, icon size token, title text size,
  # and close-button box. close keeps a uniform 24x24 (h-6 w-6) hit target across
  # sizes to satisfy WCAG 2.5.8; padding scales the inner glyph.
  @size_config %{
    "sm" => %{container: "gap-2 rounded-field p-2 text-sm", icon: "sm", title: "text-sm", close: "h-6 w-6 p-1.5"},
    "md" => %{container: "gap-2 rounded-field p-3 text-base", icon: "md", title: "text-base", close: "h-6 w-6 p-1"},
    "lg" => %{container: "gap-3 rounded-box p-4 text-base", icon: "lg", title: "text-lg", close: "h-6 w-6 p-0.5"}
  }

  @alert_base_classes "flex w-full items-center"

  # Color classes per variant. Mirrors the Flash palette so text-on-tint clears
  # WCAG AA; ghost neutral uses the surface token rather than a neutral tint.
  @color_config %{
    "ghost" => %{
      "danger" => "text-danger bg-danger/10",
      "info" => "text-info bg-info/10",
      "neutral" => "text-foreground bg-surface-1",
      "primary" => "text-primary bg-primary/10",
      "secondary" => "text-secondary bg-secondary/10",
      "success" => "text-success bg-success/10",
      "warning" => "text-warning bg-warning/10"
    },
    "outline" => %{
      "danger" => "border border-danger bg-background text-danger",
      "info" => "border border-info bg-background text-info",
      "neutral" => "border border-neutral bg-background text-foreground",
      "primary" => "border border-primary bg-background text-primary",
      "secondary" => "border border-secondary bg-background text-secondary",
      "success" => "border border-success bg-background text-success",
      "warning" => "border border-warning bg-background text-warning"
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

  # ============================================================================
  # ATTRIBUTES & SLOTS
  # ============================================================================

  attr :id, :string, doc: "Alert ID (auto-generated if omitted)"

  attr :variant, :string,
    default: "ghost",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the alert"

  attr :color, :string,
    default: "info",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the alert; also selects the default status icon"

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Size of the alert"

  attr :title, :string, default: nil, doc: "Optional heading line shown above the description"

  attr :description, :string,
    default: nil,
    doc: "Body text. When omitted, the inner_block is rendered instead (for rich content)"

  attr :icon, :any,
    default: nil,
    doc: ~s{Leading icon: a "hero-..." name overrides the color default; false hides it; nil auto-selects from color}

  attr :dismissible, :boolean, default: false, doc: "Show a close button for manual dismissal"

  attr :on_dismiss, JS,
    default: %JS{},
    doc: "JS commands to run when the close button is clicked (in addition to hiding the alert)"

  attr :dismiss_label, :string,
    default: "Dismiss",
    doc: ~s{Accessible label for the close button. Use with i18n: gettext("Dismiss")}

  attr :role, :string,
    default: nil,
    values: [nil, "alert", "status"],
    doc:
      ~s{ARIA role. Leave unset for a static banner; set "alert" (assertive) or "status" (polite) when the alert is shown dynamically}

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, doc: "Rich body content, used when the description attr is omitted"
  slot :actions, doc: "Optional right-aligned action buttons"

  @doc """
  Renders an inline alert banner.

  ## Examples

      <.alert color="success" title="Saved" description="Your changes have been saved." />
  """
  @spec alert(map()) :: Rendered.t()
  def alert(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> generate_id() end)
      |> assign(:icon_name, resolve_icon(assigns.icon, assigns.color))
      |> assign(
        :merged_classes,
        merge([
          @alert_base_classes,
          size_classes(assigns.size),
          color_classes(assigns.variant, assigns.color),
          assigns.class
        ])
      )

    ~H"""
    <div id={@id} role={@role} class={@merged_classes} {@rest}>
      <Icon.icon :if={@icon_name} name={@icon_name} size={icon_size(@size)} color="current" class="shrink-0" />
      <div class="min-w-0 flex-1">
        <p :if={present?(@title)} class={title_classes(@size)}>{@title}</p>
        <p :if={present?(@description)} class="font-normal">{@description}</p>
        <div :if={!present?(@description)} class="font-normal">{render_slot(@inner_block)}</div>
      </div>

      <div :if={@actions != []} class="flex shrink-0 items-center gap-2">
        {render_slot(@actions)}
      </div>

      <button
        :if={@dismissible}
        type="button"
        class={close_button_classes(@size)}
        aria-label={@dismiss_label}
        aria-controls={@id}
        phx-click={
          JS.hide(@on_dismiss,
            to: "##{@id}",
            time: 120,
            transition: {"transition-opacity duration-fast ease-accelerate", "opacity-100", "opacity-0"}
          )
        }
      >
        <Icon.icon name="hero-x-mark" size="sm" color="current" />
      </button>
    </div>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec size_classes(String.t()) :: String.t()
  defp size_classes(size), do: @size_config[size][:container] || ""

  @spec icon_size(String.t()) :: String.t()
  defp icon_size(size), do: @size_config[size][:icon] || "md"

  @spec title_classes(String.t()) :: String.t()
  defp title_classes(size), do: merge(["font-semibold", @size_config[size][:title] || ""])

  @spec close_button_classes(String.t()) :: String.t()
  defp close_button_classes(size) do
    merge([
      "inline-flex shrink-0 items-center justify-center rounded-field transition-colors duration-fast ease-standard",
      "hover:bg-foreground/10",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-current focus-visible:ring-offset-2",
      @size_config[size][:close] || ""
    ])
  end

  @spec color_classes(String.t(), String.t()) :: String.t()
  defp color_classes(variant, color) do
    get_in(@color_config, [variant, color]) || get_in(@color_config, ["ghost", "info"]) || ""
  end

  # Resolve the leading icon: false hides it, a binary overrides, nil auto-maps.
  defp resolve_icon(false, _color), do: nil
  defp resolve_icon(name, _color) when is_binary(name), do: name
  defp resolve_icon(_icon, color), do: default_icon(color)

  defp default_icon("success"), do: "hero-check-circle"
  defp default_icon("danger"), do: "hero-x-circle"
  defp default_icon("warning"), do: "hero-exclamation-triangle"
  defp default_icon(_color), do: "hero-information-circle"

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
