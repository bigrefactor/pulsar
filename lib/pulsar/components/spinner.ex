defmodule Pulsar.Components.Spinner do
  @moduledoc """
  Spinner component for loading and async states.

  Provides an accessible, animated loading indicator in three styles. By default
  the spinner announces itself to assistive technologies via a status role and a
  visually-hidden label; mark it `decorative` to silence it when a surrounding
  control or region already conveys the loading state.

  ## Features

  - **Three styles**: ring (default), dots, and bars
  - **Multiple sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Full color palette**: inherits the current text color by default, or pick a
    semantic color
  - **Announce by default**: a status role plus a visually-hidden label, with a
    `decorative` escape hatch

  ## Examples

      # Default ring spinner that announces "Loading"
      <.spinner />

      # Dots style, sized and colored
      <.spinner variant="dots" size="lg" color="primary" />

      # Custom announced label
      <.spinner label="Saving changes" />

      # Decorative — silenced for assistive tech (e.g. inside a labeled region)
      <.spinner decorative />
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  alias Phoenix.LiveView.Rendered

  # Text color tokens; "current" inherits the surrounding text color.
  @color_config %{
    "current" => "",
    "neutral" => "text-foreground",
    "primary" => "text-primary",
    "secondary" => "text-secondary",
    "success" => "text-success",
    "danger" => "text-danger",
    "warning" => "text-warning",
    "info" => "text-info"
  }

  # Ring (SVG) dimensions per size.
  @ring_size_config %{
    "xs" => "h-3 w-3",
    "sm" => "h-4 w-4",
    "md" => "h-5 w-5",
    "lg" => "h-6 w-6",
    "xl" => "h-8 w-8"
  }

  # Dots: container gap + individual dot dimensions per size.
  @dots_gap_config %{
    "xs" => "gap-0.5",
    "sm" => "gap-1",
    "md" => "gap-1",
    "lg" => "gap-1.5",
    "xl" => "gap-2"
  }

  @dots_dot_config %{
    "xs" => "h-1 w-1",
    "sm" => "h-1.5 w-1.5",
    "md" => "h-2 w-2",
    "lg" => "h-2.5 w-2.5",
    "xl" => "h-3 w-3"
  }

  # Bars: container gap + container height + individual bar width per size.
  @bars_gap_config %{
    "xs" => "gap-0.5",
    "sm" => "gap-0.5",
    "md" => "gap-1",
    "lg" => "gap-1",
    "xl" => "gap-1.5"
  }

  @bars_height_config %{
    "xs" => "h-3",
    "sm" => "h-4",
    "md" => "h-5",
    "lg" => "h-6",
    "xl" => "h-8"
  }

  @bars_bar_config %{
    "xs" => "w-0.5",
    "sm" => "w-0.5",
    "md" => "w-1",
    "lg" => "w-1",
    "xl" => "w-1.5"
  }

  # ============================================================================
  # SPINNER COMPONENT
  # ============================================================================

  attr :variant, :string,
    default: "ring",
    values: ~w(ring dots bars),
    doc: "Animation style of the spinner"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the spinner"

  attr :color, :string,
    default: "current",
    values: ~w(current neutral primary secondary success danger warning info),
    doc: "Color of the spinner; \"current\" inherits the surrounding text color"

  attr :label, :string,
    default: "Loading",
    doc: "Accessible label announced by screen readers. Ignored when decorative."

  attr :decorative, :boolean,
    default: false,
    doc: "When true, hides the spinner from assistive technologies and omits the status role and label."

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders an accessible, animated loading spinner.

  By default the wrapper carries `role="status"` with a visually-hidden label so
  screen readers announce loading. Pass `decorative` to silence it.
  """
  @spec spinner(map()) :: Rendered.t()
  def spinner(assigns) do
    assigns =
      assigns
      |> assign(:class, build_spinner_classes(assigns))
      |> assign(:role, status_role(assigns.decorative))
      |> assign(:aria_hidden, aria_hidden(assigns.decorative))
      |> assign(:ring_class, ring_classes(assigns.size))
      |> assign(:dots_class, dots_container_classes(assigns.size))
      |> assign(:dot_class, dot_classes(assigns.size))
      |> assign(:bars_class, bars_container_classes(assigns.size))
      |> assign(:bar_class, bar_classes(assigns.size))

    ~H"""
    <span class={@class} role={@role} aria-hidden={@aria_hidden} {@rest}>
      <svg
        :if={@variant == "ring"}
        aria-hidden="true"
        class={@ring_class}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25" />
        <path
          fill="currentColor"
          class="opacity-75"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        />
      </svg>
      <span :if={@variant == "dots"} aria-hidden="true" class={@dots_class}>
        <span :for={_ <- 1..3} class={@dot_class}></span>
      </span>
      <span :if={@variant == "bars"} aria-hidden="true" class={@bars_class}>
        <span :for={_ <- 1..4} class={@bar_class}></span>
      </span>
      <span :if={not @decorative} class="sr-only">{@label}</span>
    </span>
    """
  end

  # ============================================================================
  # SPINNER HELPER FUNCTIONS
  # ============================================================================

  # Builds the merged class string for the wrapper.
  defp build_spinner_classes(assigns) do
    merge([
      "inline-flex items-center justify-center",
      color_classes(assigns.color),
      assigns.class
    ])
  end

  @spec status_role(boolean()) :: String.t() | nil
  defp status_role(true), do: nil
  defp status_role(false), do: "status"

  @spec aria_hidden(boolean()) :: String.t() | nil
  defp aria_hidden(true), do: "true"
  defp aria_hidden(false), do: nil

  @spec color_classes(String.t()) :: String.t()
  defp color_classes(color), do: @color_config[color] || ""

  @spec ring_classes(String.t()) :: String.t()
  defp ring_classes(size), do: merge(["animate-spin", @ring_size_config[size] || ""])

  @spec dots_container_classes(String.t()) :: String.t()
  defp dots_container_classes(size),
    do: merge(["pulsar-spinner-dots inline-flex items-center", @dots_gap_config[size] || ""])

  @spec dot_classes(String.t()) :: String.t()
  defp dot_classes(size), do: merge(["rounded-full bg-current", @dots_dot_config[size] || ""])

  @spec bars_container_classes(String.t()) :: String.t()
  defp bars_container_classes(size),
    do:
      merge([
        "pulsar-spinner-bars inline-flex items-end",
        @bars_gap_config[size] || "",
        @bars_height_config[size] || ""
      ])

  @spec bar_classes(String.t()) :: String.t()
  defp bar_classes(size), do: merge(["h-full rounded-full bg-current origin-bottom", @bars_bar_config[size] || ""])
end
