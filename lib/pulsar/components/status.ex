defmodule Pulsar.Components.Status do
  @moduledoc """
  Status indicator: a small colored dot for signalling state.

  Renders a colored dot for states such as online/offline/busy, unread, or live.
  Use it standalone next to a text label, or place it on the corner of another
  element (avatar, button, icon) with `indicator/1`.

  This is a *status* marker, distinct from `spinner/1` (a busy/activity
  animation). The optional `ping` animation gives a "live/active" treatment: an
  expanding halo behind the dot.

  ## Features

  - **House colors**: neutral, primary, secondary, success, danger, warning, info
  - **Sizes**: xs, sm, md, lg, xl
  - **Ping**: an optional expanding-halo animation for live/active states
  - **Corner placement**: `indicator/1` overlays the dot on any element

  ## Examples

      # Standalone dot (decorative — pair it with visible text)
      <.status color="success" /> Online

      # Meaningful dot — announced to screen readers
      <.status color="success" label="Online" />

      # Live / active treatment
      <.status color="danger" ping label="Live" />

      # On the corner of an avatar
      <.indicator placement="bottom-right">
        <:item><.status color="success" label="Online" /></:item>
        <.avatar name="Jane Doe" />
      </.indicator>

  ## Accessible name

  A dot with no `label` is decorative (`aria-hidden`), on the assumption that
  adjacent text carries the meaning. Pass `label` when the dot is the only signal
  of state; it is then exposed via `role="img"` and `aria-label`.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Dot background color per house color token.
  @color_config %{
    "neutral" => "bg-neutral",
    "primary" => "bg-primary",
    "secondary" => "bg-secondary",
    "success" => "bg-success",
    "danger" => "bg-danger",
    "warning" => "bg-warning",
    "info" => "bg-info"
  }

  # Dot dimensions per size.
  @size_config %{
    "xs" => "h-1.5 w-1.5",
    "sm" => "h-2 w-2",
    "md" => "h-2.5 w-2.5",
    "lg" => "h-3 w-3",
    "xl" => "h-4 w-4"
  }

  # ============================================================================
  # STATUS COMPONENT
  # ============================================================================

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Dot color from the house palette"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Dot size"

  attr :ping, :boolean,
    default: false,
    doc: "When true, renders an expanding-halo animation behind the dot for live/active states"

  attr :label, :string,
    default: nil,
    doc:
      "Accessible label. When set the dot is exposed via role=\"img\" and aria-label; " <>
        "when omitted the dot is decorative (aria-hidden), assuming adjacent text conveys the state."

  attr :class, :string, default: "", doc: "Additional CSS classes"

  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders a colored status dot.
  """
  @spec status(map()) :: Rendered.t()
  def status(assigns) do
    label = present_or_nil(assigns.label)

    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:wrapper_class, build_wrapper_classes(assigns))
      |> assign(:color_class, color_classes(assigns.color))
      |> assign(:role, status_role(label))
      |> assign(:aria_hidden, aria_hidden(label))

    ~H"""
    <span
      class={@wrapper_class}
      role={@role}
      aria-label={@label}
      aria-hidden={@aria_hidden}
      {@rest}
    >
      <span
        :if={@ping}
        aria-hidden="true"
        class={[
          "absolute inline-flex h-full w-full rounded-full opacity-75 animate-ping motion-reduce:hidden",
          @color_class
        ]}
      >
      </span>
      <span class={["relative inline-flex h-full w-full rounded-full", @color_class]}></span>
    </span>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  defp build_wrapper_classes(assigns) do
    merge([
      "relative inline-flex shrink-0 rounded-full",
      size_classes(assigns.size),
      assigns.class
    ])
  end

  @spec color_classes(String.t()) :: String.t()
  defp color_classes(color), do: @color_config[color] || @color_config["neutral"]

  @spec size_classes(String.t()) :: String.t()
  defp size_classes(size), do: @size_config[size] || @size_config["md"]

  defp status_role(nil), do: nil
  defp status_role(_label), do: "img"

  defp aria_hidden(nil), do: "true"
  defp aria_hidden(_label), do: nil

  defp present_or_nil(value) when is_binary(value) do
    if String.trim(value) != "", do: value
  end

  defp present_or_nil(_value), do: nil
end
