defmodule Pulsar.Components.Calendar do
  @moduledoc """
  A locale-aware month-grid for selecting a single date or a date range.

  Renders one or more month grids and writes the selected date(s) as ISO 8601
  into hidden inputs. Month and weekday names, the first day of the week, and
  display formatting come from the visitor's browser locale, so the grid is
  localized with no server-side configuration. The selectable value the server
  receives is always ISO `YYYY-MM-DD`.

  Use it inline (a scheduling panel, a dashboard filter) or inside
  `Pulsar.Components.DatePicker`, which wraps it in a popover.

  ## Examples

      # Inline single-date, bound to a form field
      <.calendar field={@form[:starts_on]} />

      # Range across two months, bound to two fields
      <.calendar mode="range" start_field={@form[:from]} end_field={@form[:to]} />

      # Standalone, reacting to selection on the client
      <.calendar id="cal" on_select={JS.push("date_chosen")} />

  ## Modes

  `mode="single"` selects one date; `mode="range"` selects a start and end
  (first click sets the start, second sets the end). `months` controls how many
  month grids show at once (default 1 for single, 2 for range).

  ## Constraints

  `min`/`max` clamp the selectable window; `disabled_dates` is a list of ISO
  dates that render un-selectable; `disable_weekends` greys out the locale's
  weekend days.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  # Cell scale per size.
  @cell_size %{
    "xs" => "h-7 w-7 text-xs",
    "sm" => "h-8 w-8 text-sm",
    "md" => "h-9 w-9 text-sm",
    "lg" => "h-10 w-10 text-base",
    "xl" => "h-11 w-11 text-base"
  }

  # Selection accent per color, keyed off data-* attributes the hook flips so the
  # visuals never freeze when the client swaps state.
  @cell_accent %{
    "neutral" =>
      "data-[selected=true]:bg-foreground data-[selected=true]:text-background data-[in-range=true]:bg-foreground/10",
    "primary" =>
      "data-[selected=true]:bg-primary data-[selected=true]:text-primary-foreground data-[in-range=true]:bg-primary/10",
    "secondary" =>
      "data-[selected=true]:bg-secondary data-[selected=true]:text-secondary-foreground data-[in-range=true]:bg-secondary/10",
    "success" =>
      "data-[selected=true]:bg-success data-[selected=true]:text-success-foreground data-[in-range=true]:bg-success/10",
    "danger" =>
      "data-[selected=true]:bg-danger data-[selected=true]:text-danger-foreground data-[in-range=true]:bg-danger/10",
    "warning" =>
      "data-[selected=true]:bg-warning data-[selected=true]:text-warning-foreground data-[in-range=true]:bg-warning/10",
    "info" => "data-[selected=true]:bg-info data-[selected=true]:text-info-foreground data-[in-range=true]:bg-info/10"
  }

  @doc """
  Renders a locale-aware calendar grid.
  """
  @spec calendar(map()) :: Rendered.t()

  attr(:id, :string, default: nil, doc: "Calendar id (auto-generated if omitted)")
  attr(:mode, :string, default: "single", values: ~w(single range), doc: "Single date or a start/end range")
  attr(:value, :any, default: nil, doc: "Selected Date/ISO (single) or {start, end} (range)")
  attr(:months, :integer, default: nil, doc: "Month grids shown at once (nil → 1 single / 2 range)")
  attr(:min, :any, default: nil, doc: "Earliest selectable Date/ISO")
  attr(:max, :any, default: nil, doc: "Latest selectable Date/ISO")
  attr(:disabled_dates, :list, default: [], doc: "List of Date/ISO dates that are un-selectable")
  attr(:disable_weekends, :boolean, default: false, doc: "Disable the locale's weekend days")
  attr(:locale, :string, default: nil, doc: "BCP-47 locale tag (nil → browser locale)")

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Selection accent"
  )

  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "Cell size")
  attr(:on_select, JS, default: %JS{}, doc: ~s{JS run when a date/range is chosen. Server: JS.push("event")})
  attr(:field, FormField, default: nil, doc: "Single-mode form field (writes a hidden ISO input)")
  attr(:start_field, FormField, default: nil, doc: "Range start form field")
  attr(:end_field, FormField, default: nil, doc: "Range end form field")
  attr(:class, :string, default: "", doc: "Additional CSS classes for the container")
  attr(:rest, :global, doc: "Additional container attributes")

  def calendar(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "calendar-#{System.unique_integer([:positive])}" end)
      |> normalize_months()
      |> normalize_hidden_inputs()
      |> assign(:cell_class, cell_classes(assigns.color, assigns.size))

    ~H"""
    <div
      id={@id}
      phx-hook=".PulsarCalendar"
      role="application"
      aria-roledescription="calendar"
      data-mode={@mode}
      data-months={@months}
      data-locale={@locale}
      data-value={@encoded_value}
      data-min={iso_or_nil(@min)}
      data-max={iso_or_nil(@max)}
      data-disabled-dates={Enum.map_join(@disabled_dates, " ", &iso_or_nil/1)}
      data-disable-weekends={to_string(@disable_weekends)}
      data-cell-class={@cell_class}
      data-on-select={@on_select}
      class={merge(["inline-flex flex-col gap-3 rounded-box border border-border bg-surface-1 p-3", @class])}
      {@rest}
    >
      <input :if={@single_name} type="hidden" name={@single_name} value={@single_value} data-cal-value="single" />
      <input :if={@start_name} type="hidden" name={@start_name} value={@start_value} data-cal-value="start" />
      <input :if={@end_name} type="hidden" name={@end_name} value={@end_value} data-cal-value="end" />
      <div data-cal-grids class="flex flex-wrap gap-4"></div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarCalendar">
        export default {
          mounted() { /* filled in Task 3 */ },
          updated() {},
          destroyed() {}
        }
      </script>
    </div>
    """
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  defp normalize_months(assigns) do
    months = assigns.months || if assigns.mode == "range", do: 2, else: 1
    assign(assigns, :months, months)
  end

  # Build hidden-input name/value triples from the bound form field(s), and the
  # data-value seed the hook reads on mount.
  defp normalize_hidden_inputs(assigns) do
    single = assigns.field
    start_f = assigns.start_field
    end_f = assigns.end_field

    assigns
    |> assign(:single_name, single && single.name)
    |> assign(:single_value, single && iso_or_nil(single.value))
    |> assign(:start_name, start_f && start_f.name)
    |> assign(:start_value, start_f && iso_or_nil(start_f.value))
    |> assign(:end_name, end_f && end_f.name)
    |> assign(:end_value, end_f && iso_or_nil(end_f.value))
    |> assign(:encoded_value, encode_seed(assigns))
  end

  defp encode_seed(%{mode: "range"} = assigns) do
    {a, b} =
      case assigns.value do
        {a, b} -> {a, b}
        _ -> {assigns.start_field && assigns.start_field.value, assigns.end_field && assigns.end_field.value}
      end

    case {iso_or_nil(a), iso_or_nil(b)} do
      {nil, nil} -> nil
      {a, b} -> "#{a}/#{b}"
    end
  end

  defp encode_seed(assigns), do: iso_or_nil(assigns.value || (assigns.field && assigns.field.value))

  # Accepts a Date, an ISO string, or nil; returns an ISO string or nil.
  defp iso_or_nil(%Date{} = d), do: Date.to_iso8601(d)
  defp iso_or_nil(s) when is_binary(s) and s != "", do: s
  defp iso_or_nil(_), do: nil

  @spec cell_classes(String.t(), String.t()) :: String.t()
  defp cell_classes(color, size) do
    merge([
      "flex items-center justify-center rounded-field tabular-nums transition-colors duration-fast ease-standard",
      "data-[today=true]:font-semibold data-[today=true]:ring-1 data-[today=true]:ring-border-strong",
      "data-[disabled=true]:opacity-disabled data-[disabled=true]:pointer-events-none",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
      @cell_size[size] || @cell_size["md"],
      @cell_accent[color] || @cell_accent["primary"]
    ])
  end
end
