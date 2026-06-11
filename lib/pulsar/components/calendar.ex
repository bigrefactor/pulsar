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

  attr(:id, :string, doc: "Calendar id (derived from the bound field, or auto-generated, if omitted)")
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
    validate_fields!(assigns)

    assigns =
      assigns
      |> assign_new(:id, fn -> stable_id(assigns) end)
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
      <div data-cal-announce aria-live="polite" aria-atomic="true" class="sr-only"></div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarCalendar">
        export default {
          mounted() {
            this.gridsEl = this.el.querySelector("[data-cal-grids]")
            this.announceEl = this.el.querySelector("[data-cal-announce]")
            this.syncAttrs()

            // selection state, seeded from data-value (client state from here on)
            const seed = this.el.dataset.value || ""
            if (this.mode === "range") {
              const [a, b] = seed.split("/")
              this.start = a || null
              this.end = b || null
            } else {
              this.start = seed || null
              this.end = null
            }

            // the month the left-most grid shows; focus cursor for keyboard nav
            const anchor = this.start ? this.parseISO(this.start) : this.today()
            this.view = new Date(anchor.getFullYear(), anchor.getMonth(), 1)
            this.cursor = anchor

            this.bound = false
            this.render()
          },

          updated() {
            // A server patch can revert client DOM and change config (min/max/
            // disabled/locale). Re-read config and re-render, preserving client
            // selection state (this.start/end) and keyboard focus.
            const hadFocus = this.gridsEl.contains(document.activeElement)
            this.syncAttrs()
            this.render()
            if (hadFocus) {
              const cell = this.gridsEl.querySelector(`[data-cal-day="${this.toISO(this.cursor)}"]`)
              if (cell) cell.focus()
            }
          },

          destroyed() {
            if (this._onKeydown) this.gridsEl.removeEventListener("keydown", this._onKeydown)
            if (this._onClick) this.gridsEl.removeEventListener("click", this._onClick)
          },

          // Read config from data-* attrs (on mount and after every server patch, so
          // dynamic min/max/disabled/locale changes take effect). Rebuilds the Intl
          // formatters + week info only when the locale actually changes.
          syncAttrs() {
            this.cellClass = this.el.dataset.cellClass || ""
            this.mode = this.el.dataset.mode || "single"
            this.months = parseInt(this.el.dataset.months, 10) || 1
            this.min = this.el.dataset.min || null
            this.max = this.el.dataset.max || null
            this.disabled = new Set((this.el.dataset.disabledDates || "").split(" ").filter(Boolean))
            this.disableWeekends = this.el.dataset.disableWeekends === "true"

            const locale = this.el.dataset.locale || undefined
            if (!this.intl || locale !== this.locale) {
              this.locale = locale
              this.intl = {
                month: new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }),
                weekdayNarrow: new Intl.DateTimeFormat(locale, { weekday: "narrow" }),
                weekdayLong: new Intl.DateTimeFormat(locale, { weekday: "long" }),
                dayLong: new Intl.DateTimeFormat(locale, { dateStyle: "full" })
              }
              this.week = this.weekInfo(locale)
            }
          },

          // --- locale helpers -----------------------------------------------------

          // firstDay: 1=Mon..7=Sun (CLDR). weekend: array of those day numbers.
          weekInfo(locale) {
            try {
              const loc = new Intl.Locale(locale || navigator.language)
              const info = loc.weekInfo || (loc.getWeekInfo && loc.getWeekInfo())
              if (info && info.firstDay) return { firstDay: info.firstDay, weekend: info.weekend || [6, 7] }
            } catch (_e) { /* fall through */ }
            // Fallback only for browsers without Intl.Locale weekInfo. Heuristic by
            // region; a language-only tag (no region subtag) defaults to Sunday-first.
            const region = (locale || navigator.language || "en-US").split("-")[1] || "US"
            const sunday = ["US", "CA", "JP", "IL", "MX", "PH"].includes(region.toUpperCase())
            return { firstDay: sunday ? 7 : 1, weekend: [6, 7] }
          },

          // JS getDay(): 0=Sun..6=Sat. Convert to CLDR 1=Mon..7=Sun.
          cldrDow(date) { return ((date.getDay() + 6) % 7) + 1 },

          // --- date utilities (all local, date-only) ------------------------------

          today() { const n = new Date(); return new Date(n.getFullYear(), n.getMonth(), n.getDate()) },
          parseISO(s) { const [y, m, d] = s.split("-").map(Number); return new Date(y, m - 1, d) },
          toISO(date) {
            const y = date.getFullYear()
            const m = String(date.getMonth() + 1).padStart(2, "0")
            const d = String(date.getDate()).padStart(2, "0")
            return `${y}-${m}-${d}`
          },
          addMonths(date, n) { return new Date(date.getFullYear(), date.getMonth() + n, 1) },
          addDays(date, n) { return new Date(date.getFullYear(), date.getMonth(), date.getDate() + n) },
          sameDay(a, b) { return a && b && this.toISO(a) === this.toISO(b) },

          isDisabled(iso, date) {
            if (this.min && iso < this.min) return true
            if (this.max && iso > this.max) return true
            if (this.disabled.has(iso)) return true
            if (this.disableWeekends && this.week.weekend.includes(this.cldrDow(date))) return true
            return false
          },

          isInRange(iso) {
            if (this.mode !== "range" || !this.start || !this.end) return false
            return iso > this.start && iso < this.end
          },
          isSelected(iso) {
            if (this.mode === "range") return iso === this.start || iso === this.end
            return iso === this.start
          },

          // --- rendering ----------------------------------------------------------

          render() {
            this.gridsEl.innerHTML = ""
            for (let i = 0; i < this.months; i++) {
              this.gridsEl.appendChild(this.renderMonth(this.addMonths(this.view, i), i === 0, i === this.months - 1))
            }
            this.attachEvents()
          },

          renderMonth(monthStart, showPrev, showNext) {
            const wrap = document.createElement("div")
            wrap.className = "flex flex-col gap-2"

            // header: ‹  Month YYYY  ›
            const head = document.createElement("div")
            head.className = "flex items-center justify-between px-1"
            const prev = this.navButton("‹", "prev", showPrev, this.intl.month.format(this.addMonths(monthStart, -1)))
            const next = this.navButton("›", "next", showNext, this.intl.month.format(this.addMonths(monthStart, 1)))
            const title = document.createElement("div")
            title.className = "text-sm font-semibold text-foreground"
            title.textContent = this.intl.month.format(monthStart)
            head.append(prev, title, next)

            // weekday header row, ordered from the locale's first day
            const grid = document.createElement("div")
            grid.setAttribute("role", "grid")
            grid.setAttribute("aria-label", title.textContent)
            grid.className = "grid grid-cols-7 gap-0.5"

            for (let d = 0; d < 7; d++) {
              // CLDR weekday for this column (1=Mon..7=Sun), converted to a JS
              // getDay offset (0=Sun..6=Sat) so it indexes off the Sunday ref date.
              const dow = (((this.week.firstDay - 1 + d) % 7) + 1) % 7
              const ref = new Date(2024, 0, 7 + dow) // 2024-01-07 is a Sunday
              const th = document.createElement("div")
              th.setAttribute("role", "columnheader")
              th.setAttribute("aria-label", this.intl.weekdayLong.format(ref))
              th.className = "flex h-6 items-center justify-center text-xs font-medium text-muted-foreground"
              th.textContent = this.intl.weekdayNarrow.format(ref)
              grid.appendChild(th)
            }

            // leading blanks so day 1 lands under the right weekday
            const first = new Date(monthStart.getFullYear(), monthStart.getMonth(), 1)
            const lead = (this.cldrDow(first) - this.week.firstDay + 7) % 7
            for (let b = 0; b < lead; b++) grid.appendChild(this.blankCell())

            const daysInMonth = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0).getDate()
            const todayISO = this.toISO(this.today())
            for (let day = 1; day <= daysInMonth; day++) {
              const date = new Date(monthStart.getFullYear(), monthStart.getMonth(), day)
              grid.appendChild(this.dayCell(date, todayISO))
            }

            wrap.append(head, grid)
            return wrap
          },

          navButton(label, dir, visible, ariaLabel) {
            const b = document.createElement("button")
            b.type = "button"
            b.dataset.calNav = dir
            b.setAttribute("aria-label", `${dir === "prev" ? "Previous" : "Next"} month, ${ariaLabel}`)
            b.className = "flex h-7 w-7 items-center justify-center rounded-field text-muted-foreground hover:bg-surface-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring cursor-pointer"
            b.textContent = label
            b.style.visibility = visible ? "visible" : "hidden"
            return b
          },

          blankCell() {
            const c = document.createElement("div")
            c.setAttribute("aria-hidden", "true")
            c.className = "h-9 w-9"
            return c
          },

          dayCell(date, todayISO) {
            const iso = this.toISO(date)
            const cell = document.createElement("button")
            cell.type = "button"
            cell.dataset.calDay = iso
            cell.className = this.cellClass
            cell.textContent = String(date.getDate())
            cell.setAttribute("role", "gridcell")
            cell.setAttribute("aria-label", this.intl.dayLong.format(date))

            const disabled = this.isDisabled(iso, date)
            cell.dataset.disabled = String(disabled)
            cell.dataset.today = String(iso === todayISO)
            cell.dataset.selected = String(this.isSelected(iso))
            cell.dataset.inRange = String(this.isInRange(iso))
            if (iso === todayISO) cell.setAttribute("aria-current", "date")
            cell.setAttribute("aria-selected", String(this.isSelected(iso)))
            if (disabled) cell.setAttribute("aria-disabled", "true")

            // roving tabindex: only the cursor cell is tabbable
            cell.tabIndex = this.sameDay(date, this.cursor) ? 0 : -1
            return cell
          },

          // --- event handling -----------------------------------------------------

          attachEvents() {
            if (this.bound) return
            this.bound = true

            this._onClick = (e) => {
              const nav = e.target.closest("[data-cal-nav]")
              if (nav) { this.navigate(nav.dataset.calNav); return }
              const cell = e.target.closest("[data-cal-day]")
              if (cell && cell.dataset.disabled !== "true") this.select(cell.dataset.calDay)
            }
            this.gridsEl.addEventListener("click", this._onClick)

            this._onKeydown = (e) => this.onKeydown(e)
            this.gridsEl.addEventListener("keydown", this._onKeydown)
          },

          navigate(dir) {
            this.view = this.addMonths(this.view, dir === "next" ? 1 : -1)
            this.render()
            // render() rebuilds the grids (and the nav buttons inside them), so the
            // clicked button is gone and focus has dropped to <body>. Restore focus
            // to the same-direction button in the freshly rendered grids, then
            // announce the new month for screen readers.
            const btn = this.gridsEl.querySelector(`[data-cal-nav="${dir}"]`)
            if (btn) btn.focus()
            if (this.announceEl) this.announceEl.textContent = this.intl.month.format(this.view)
          },

          select(iso) {
            if (this.mode === "range") return this.selectRange(iso)
            this.start = iso
            this.cursor = this.parseISO(iso)
            this.writeValues()
            this.refreshCells()
            this.runSelect()
          },

          // Update only the cells' state attributes in place (cheaper than re-render,
          // and keeps focus on the active cell).
          refreshCells() {
            const todayISO = this.toISO(this.today())
            this.gridsEl.querySelectorAll("[data-cal-day]").forEach((cell) => {
              const iso = cell.dataset.calDay
              cell.dataset.selected = String(this.isSelected(iso))
              cell.dataset.inRange = String(this.isInRange(iso))
              cell.setAttribute("aria-selected", String(this.isSelected(iso)))
              cell.tabIndex = iso === this.toISO(this.cursor) ? 0 : -1
              cell.dataset.today = String(iso === todayISO)
            })
          },

          writeValues() {
            const single = this.el.querySelector('[data-cal-value="single"]')
            const start = this.el.querySelector('[data-cal-value="start"]')
            const end = this.el.querySelector('[data-cal-value="end"]')
            if (single) this.setInput(single, this.start || "")
            if (start) this.setInput(start, this.start || "")
            if (end) this.setInput(end, this.end || "")
            // keep data-value in sync so updated() re-seeds correctly
            this.el.dataset.value = this.mode === "range" ? `${this.start || ""}/${this.end || ""}` : (this.start || "")
          },

          // Set a hidden input's value AND notify LiveView. A bare `.value =` does not
          // fire input/change, so phx-change/form recovery never sees it — dispatch a
          // bubbling "input" event so the enclosing form picks up the new value.
          setInput(input, value) {
            if (input.value === value) return
            input.value = value
            input.setAttribute("value", value)
            input.dispatchEvent(new Event("input", { bubbles: true }))
          },

          runSelect() {
            const encoded = this.el.dataset.onSelect
            if (encoded && encoded !== "[]" && this.liveSocket) this.liveSocket.execJS(this.el, encoded)
          },

          // --- range selection ----------------------------------------------------

          selectRange(iso) {
            // First click (or a click after a complete range) starts a new range.
            if (!this.start || this.end) {
              this.start = iso
              this.end = null
            } else if (iso < this.start) {
              // clicking before the start resets the start
              this.start = iso
            } else {
              this.end = iso
            }
            this.cursor = this.parseISO(iso)
            this.writeValues()
            this.refreshCells()
            // Only fire the callback when the range is complete.
            if (this.start && this.end) this.runSelect()
          },

          // --- APG grid keyboard navigation ---------------------------------------

          onKeydown(e) {
            const map = {
              ArrowRight: () => this.moveCursor(1),
              ArrowLeft: () => this.moveCursor(-1),
              ArrowDown: () => this.moveCursor(7),
              ArrowUp: () => this.moveCursor(-7),
              Home: () => this.moveToWeekEdge("start"),
              End: () => this.moveToWeekEdge("end"),
              PageUp: () => this.pageBy(e.shiftKey ? -12 : -1),
              PageDown: () => this.pageBy(e.shiftKey ? 12 : 1),
              Enter: () => this.activateCursor(),
              " ": () => this.activateCursor()
            }
            const fn = map[e.key]
            if (!fn) return
            e.preventDefault()
            fn()
          },

          // Move by n days, skipping disabled cells (search up to ~6 weeks).
          moveCursor(n) {
            let next = this.addDays(this.cursor, n)
            let guard = 0
            while (guard++ < 45) {
              const iso = this.toISO(next)
              if (!this.isDisabled(iso, next)) break
              next = this.addDays(next, n > 0 ? 1 : -1)
            }
            // If nothing selectable was found within the look-ahead, don't move the
            // cursor onto a disabled cell.
            if (this.isDisabled(this.toISO(next), next)) return
            this.setCursor(next)
          },

          moveToWeekEdge(edge) {
            const dow = (this.cldrDow(this.cursor) - this.week.firstDay + 7) % 7
            const delta = edge === "start" ? -dow : 6 - dow
            let target = this.addDays(this.cursor, delta)
            // The edge cell may be disabled (min/max/disabled_dates cutting into the
            // week). Walk inward toward the cursor, staying within the week, so we
            // never land focus on a cell Enter/Space can't activate — matching the
            // skip-disabled behavior of the arrow keys.
            const step = edge === "start" ? 1 : -1
            let guard = 0
            while (guard++ < 7 && this.isDisabled(this.toISO(target), target)) {
              target = this.addDays(target, step)
            }
            if (this.isDisabled(this.toISO(target), target)) return
            this.setCursor(target)
          },

          pageBy(months) { this.setCursor(this.addMonthsKeepDay(this.cursor, months)) },

          // Like addMonths but preserves the day-of-month (JS clamps overflow, e.g.
          // Jan 31 + 1mo → Mar 3; acceptable for month paging).
          addMonthsKeepDay(date, n) {
            return new Date(date.getFullYear(), date.getMonth() + n, date.getDate())
          },

          // Bring the cursor's month into view, re-render, focus the cursor cell.
          setCursor(date) {
            this.cursor = date
            const cm = new Date(date.getFullYear(), date.getMonth(), 1)
            const lastVisible = this.addMonths(this.view, this.months - 1)
            if (cm < this.view) this.view = cm
            else if (cm > lastVisible) this.view = this.addMonths(cm, -(this.months - 1))
            this.render()
            const cell = this.gridsEl.querySelector(`[data-cal-day="${this.toISO(date)}"]`)
            if (cell) cell.focus()
          },

          activateCursor() {
            const iso = this.toISO(this.cursor)
            if (!this.isDisabled(iso, this.cursor)) this.select(iso)
          }
        }
      </script>
    </div>
    """
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  # A colocated hook holds selection/cursor state in JS, so the element id must be
  # stable across re-renders — a changing id makes morphdom replace the node and
  # remount the hook, dropping client state. Derive it from the bound field when
  # present (stable across the form's re-renders); otherwise fall back to a
  # generated id for unbound, client-only use.
  defp stable_id(%{field: %FormField{} = field}), do: "calendar-#{field.id}"
  defp stable_id(%{start_field: %FormField{} = field}), do: "calendar-#{field.id}"
  defp stable_id(_assigns), do: generate_id()

  defp generate_id(prefix \\ "calendar") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # Range mode binds both a start and end field; single mode binds one. Partially
  # binding (one of the two, or mixing modes and fields) silently renders display
  # inputs with no matching hidden ISO input, breaking form submission — fail fast.
  defp validate_fields!(%{mode: "range"} = assigns) do
    case {assigns.start_field, assigns.end_field} do
      {%FormField{}, nil} ->
        raise ArgumentError,
              ~s(<.calendar mode="range"> was given start_field but not end_field; range binding needs both)

      {nil, %FormField{}} ->
        raise ArgumentError,
              ~s(<.calendar mode="range"> was given end_field but not start_field; range binding needs both)

      _ ->
        :ok
    end

    if assigns.field do
      raise ArgumentError, ~s(<.calendar mode="range"> binds start_field/end_field, not field)
    end
  end

  defp validate_fields!(assigns) do
    if assigns.start_field || assigns.end_field do
      raise ArgumentError, ~s(<.calendar mode="single"> binds field, not start_field/end_field)
    end
  end

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
      "flex items-center justify-center rounded-field tabular-nums transition-colors duration-fast ease-standard cursor-pointer",
      "data-[today=true]:font-semibold data-[today=true]:ring-1 data-[today=true]:ring-border-strong",
      "data-[disabled=true]:opacity-disabled data-[disabled=true]:pointer-events-none",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
      @cell_size[size] || @cell_size["md"],
      @cell_accent[color] || @cell_accent["primary"]
    ])
  end
end
