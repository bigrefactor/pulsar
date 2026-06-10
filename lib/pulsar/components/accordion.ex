defmodule Pulsar.Components.Accordion do
  @moduledoc """
  Expandable sections — a set of headers, each toggling a collapsible region.

  Each `:item` slot declares a header (`title`, optional `icon`) and holds its
  panel content as the slot body. Click or press Enter/Space on a header to toggle
  its region; arrow keys move between headers.

  ## Examples

      <.accordion id="faq">
        <:item title="Shipping & delivery">We ship worldwide…</:item>
        <:item title="Returns">30-day returns…</:item>
      </.accordion>

      # Several open at once, two open initially, synced to the server
      <.accordion
        id="settings"
        type="multiple"
        value={["profile", "billing"]}
        variant="solid"
        color="primary"
        on_change={JS.push("section_toggled")}
      >
        <:item id="profile" title="Profile" icon="hero-user">…</:item>
        <:item id="billing" title="Billing" icon="hero-credit-card">…</:item>
      </.accordion>

  ## Variants

  `variant` controls the chrome: `outline` (bordered card with divided rows),
  `solid` (filled header track), `ghost` (borderless, hairline dividers),
  `elevated` (raised card). `color` tints the open header; `size` scales header
  padding and text (`xs`–`xl`).

  ## Behavior

  `type="single"` keeps at most one section open; set `collapsible={false}` to keep
  one always open. `type="multiple"` lets sections open independently. `value` sets
  which section(s) start open — an id, or a list of ids for `multiple`. Up/Down
  arrows move between headers; Home/End jump to the first/last.

  ## Callbacks

  `on_change` is a `%JS{}` command run whenever a section toggles — pair it with
  `JS.push(...)` to sync open state to the server. The toggled item's id is sent as
  `phx-value-id` and its new state as `phx-value-expanded` ("true"/"false").
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  @spec generate_id(String.t()) :: String.t()
  defp generate_id(prefix \\ "accordion") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Open-header text color, gated on the item's `data-expanded` (toggled by the
  # hook) via the section group, written as full literals so Tailwind emits them.
  @header_open %{
    "neutral" => "group-data-[expanded]/item:text-foreground",
    "primary" => "group-data-[expanded]/item:text-primary",
    "secondary" => "group-data-[expanded]/item:text-secondary",
    "success" => "group-data-[expanded]/item:text-success",
    "danger" => "group-data-[expanded]/item:text-danger",
    "warning" => "group-data-[expanded]/item:text-warning",
    "info" => "group-data-[expanded]/item:text-info"
  }

  for color <- @valid_colors do
    if !@header_open[color] do
      raise CompileError, description: "Missing accordion header_open for color=#{color}"
    end
  end

  @size_header %{
    "xs" => "text-xs px-3 py-2 gap-2",
    "sm" => "text-sm px-3.5 py-2.5 gap-2",
    "md" => "text-sm px-4 py-3 gap-2.5",
    "lg" => "text-base px-5 py-4 gap-3",
    "xl" => "text-lg px-6 py-5 gap-3"
  }

  # Panel padding mirrors the header's horizontal padding; bottom padding only
  # (top gap comes from the header).
  @size_panel %{
    "xs" => "px-3 pb-2 text-xs",
    "sm" => "px-3.5 pb-2.5 text-sm",
    "md" => "px-4 pb-3 text-sm",
    "lg" => "px-5 pb-4 text-base",
    "xl" => "px-6 pb-5 text-lg"
  }

  @icon_size %{"xs" => "xs", "sm" => "xs", "md" => "sm", "lg" => "sm", "xl" => "md"}

  # Container chrome per variant.
  @container %{
    "outline" => "rounded-box border border-border divide-y divide-border overflow-hidden",
    "ghost" => "divide-y divide-border",
    "solid" => "rounded-box overflow-hidden flex flex-col gap-px bg-border",
    "elevated" => "rounded-box border border-border shadow-card divide-y divide-border overflow-hidden bg-background"
  }

  # Per-item surface. `solid` rows sit on the container's border-color gap, so each
  # row paints its own background.
  @item_surface %{
    "outline" => "",
    "ghost" => "",
    "solid" => "bg-background",
    "elevated" => ""
  }

  @header_base "group/header flex w-full items-center text-left font-medium cursor-pointer select-none text-muted-foreground transition-[color] duration-normal ease-standard hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset disabled:pointer-events-none disabled:opacity-disabled aria-disabled:pointer-events-none aria-disabled:opacity-disabled"

  @chevron_base "ml-auto shrink-0 transition-transform duration-fast ease-standard group-data-[expanded]/item:rotate-180"

  # In-flow height disclosure (mirrors menu).
  @panel_wrapper "grid grid-rows-[0fr] group-data-[expanded]/item:grid-rows-[1fr] transition-[grid-template-rows] duration-normal ease-emphasized motion-reduce:transition-none"

  @panel_inner "overflow-hidden invisible group-data-[expanded]/item:visible"

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Accordion container id (auto-generated if omitted)")

  attr(:type, :string,
    default: "single",
    values: ~w(single multiple),
    doc: "single keeps at most one section open; multiple lets sections open independently"
  )

  attr(:collapsible, :boolean,
    default: true,
    doc: "When type=single, allow closing the open section so none are open"
  )

  attr(:value, :any,
    default: nil,
    doc: "id (single) or list of ids (multiple) of the section(s) open on first render"
  )

  attr(:variant, :string,
    default: "outline",
    values: ~w(solid outline ghost elevated),
    doc: "Visual chrome of the accordion"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color tint applied to the open header"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Header and panel padding/text size"
  )

  attr(:heading_level, :string,
    default: "h3",
    values: ~w(h2 h3 h4 h5 h6),
    doc: "Heading element wrapping each header button (fits the document outline)"
  )

  attr(:on_change, JS,
    default: %JS{},
    doc: ~s{JS commands run when a section toggles. Use with the server: JS.push("event")}
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes for the container")
  attr(:rest, :global, doc: "Additional container attributes")

  slot :item, required: true, doc: "A section: its header and panel content" do
    attr(:title, :string, required: true, doc: "Header text")
    attr(:id, :string, doc: "Stable id (used by `value`; auto-generated if omitted)")
    attr(:icon, :string, doc: "Heroicon name shown before the title")
    attr(:disabled, :boolean, doc: "Disable this section (not toggleable; skipped by keyboard nav)")
  end

  @doc """
  Renders a set of expandable accordion sections.

  ## Examples

      <.accordion id="faq">
        <:item title="Shipping">We ship worldwide.</:item>
        <:item title="Returns">30-day returns.</:item>
      </.accordion>
  """
  @spec accordion(map()) :: Rendered.t()
  def accordion(assigns) do
    assigns = assign_new(assigns, :id, fn -> generate_id() end)

    prepared = prepare_items(assigns.item, assigns.id, assigns.value, assigns.type, assigns.color)

    assigns =
      assigns
      |> assign(:prepared, prepared)
      |> assign(:container_class, merge([@container[assigns.variant] || "", assigns.class]))

    ~H"""
    <div
      id={@id}
      phx-hook=".PulsarAccordion"
      data-type={@type}
      data-collapsible={to_string(@collapsible)}
      data-on-change={@on_change}
      class={@container_class}
      {@rest}
    >
      <div
        :for={item <- @prepared}
        data-accordion-item
        id={item.item_id}
        data-expanded={(item.open && "") || nil}
        class={["group/item", item_classes(@variant)]}
      >
        <.dynamic_tag tag_name={@heading_level} class="m-0">
          <button
            type="button"
            data-accordion-header
            id={item.header_id}
            aria-controls={item.panel_id}
            aria-expanded={(item.open && "true") || "false"}
            aria-disabled={(item.disabled && "true") || "false"}
            disabled={item.disabled}
            class={header_classes(@size, item.color)}
          >
            <Icon.icon :if={item.icon} name={item.icon} size={icon_size(@size)} />
            <span>{item.title}</span>
            <Icon.icon name="hero-chevron-down" size={icon_size(@size)} class={chevron_class()} />
          </button>
        </.dynamic_tag>
        <div class={panel_wrapper_class()}>
          <div role="region" id={item.panel_id} aria-labelledby={item.header_id} class={panel_inner_class()}>
            <div class={panel_body_class(@size)}>{render_slot(item.slot)}</div>
          </div>
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarAccordion">
      export default {
        mounted() { this.setup(); this.restore() },
        updated() { this.setup(); this.restore() },
        setup() {
          this.single = this.el.dataset.type === "single"
          this.collapsibleSingle = this.el.dataset.collapsible === "true"
          if (!this.openIds) {
            this.openIds = new Set(this.items().filter((i) => i.hasAttribute("data-expanded")).map((i) => i.id))
          }
          if (this._bound) return
          this._onClick = (e) => this.onClick(e)
          this._onKeydown = (e) => this.onKeydown(e)
          this.el.addEventListener("click", this._onClick)
          this.el.addEventListener("keydown", this._onKeydown)
          this._bound = true
        },
        destroyed() {
          if (this._bound) {
            this.el.removeEventListener("click", this._onClick)
            this.el.removeEventListener("keydown", this._onKeydown)
          }
        },
        items() { return Array.from(this.el.querySelectorAll("[data-accordion-item]")) },
        headers() { return Array.from(this.el.querySelectorAll("[data-accordion-header]")) },
        enabledHeaders() {
          return this.headers().filter((h) => !h.disabled && h.getAttribute("aria-disabled") !== "true")
        },
        headerFor(item) { return item.querySelector("[data-accordion-header]") },
        itemFor(header) { return header.closest("[data-accordion-item]") },
        onClick(e) {
          const header = e.target.closest("[data-accordion-header]")
          if (!header || !this.el.contains(header)) return
          if (header.disabled || header.getAttribute("aria-disabled") === "true") return
          this.toggle(header)
        },
        onKeydown(e) {
          const header = e.target.closest("[data-accordion-header]")
          if (!header) return
          const headers = this.enabledHeaders()
          if (headers.length === 0) return
          const idx = headers.indexOf(header)
          if (e.key === "ArrowDown") { e.preventDefault(); this.focusAt(headers, (idx + 1) % headers.length) }
          else if (e.key === "ArrowUp") { e.preventDefault(); this.focusAt(headers, (idx - 1 + headers.length) % headers.length) }
          else if (e.key === "Home") { e.preventDefault(); this.focusAt(headers, 0) }
          else if (e.key === "End") { e.preventDefault(); this.focusAt(headers, headers.length - 1) }
        },
        focusAt(headers, i) { if (headers[i]) headers[i].focus() },
        // DOM mutation only — no callback. Used for silent sibling closes + restore.
        applyState(item, open) {
          const header = this.headerFor(item)
          if (open) { item.setAttribute("data-expanded", ""); if (header) header.setAttribute("aria-expanded", "true"); this.openIds.add(item.id) }
          else { item.removeAttribute("data-expanded"); if (header) header.setAttribute("aria-expanded", "false"); this.openIds.delete(item.id) }
        },
        // Fire the `on_change` command for one section, snapshotting its id/state
        // into phx-value-* so each emission carries its own payload.
        emitChange(id, open) {
          const encoded = this.el.dataset.onChange
          if (!encoded || encoded === "[]" || !this.liveSocket) return
          this.el.setAttribute("phx-value-id", id)
          this.el.setAttribute("phx-value-expanded", open ? "true" : "false")
          this.liveSocket.execJS(this.el, encoded)
        },
        toggle(header) {
          const item = this.itemFor(header)
          const willOpen = !item.hasAttribute("data-expanded")
          if (!willOpen && this.single && !this.collapsibleSingle) return
          if (willOpen && this.single) {
            this.items().forEach((other) => {
              if (other !== item && other.hasAttribute("data-expanded")) {
                this.applyState(other, false)
                this.emitChange(other.id, false)
              }
            })
          }
          this.applyState(item, willOpen)
          this.emitChange(item.id, willOpen)
        },
        // A LiveView re-render reconciles data-expanded/aria-expanded to the server
        // markup; re-apply the client's open set so toggles survive.
        restore() {
          if (!this.openIds) return
          this.items().forEach((item) => {
            const open = this.openIds.has(item.id)
            if (open !== item.hasAttribute("data-expanded")) this.applyState(item, open)
          })
        }
      }
    </script>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Resolve ids and initial-open flag for each item.
  @spec prepare_items(list(map()), String.t(), term(), String.t(), String.t()) :: list(map())
  defp prepare_items(items, group_id, value, type, group_color) do
    open_ids = resolve_open_ids(value, type)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      raw_id = Map.get(item, :id)
      item_id = raw_id || "#{group_id}-item-#{index}"
      disabled = Map.get(item, :disabled, false)

      %{
        slot: item,
        item_id: item_id,
        header_id: "#{item_id}-header",
        panel_id: "#{item_id}-panel",
        title: Map.fetch!(item, :title),
        icon: Map.get(item, :icon),
        disabled: disabled,
        color: group_color,
        open: not disabled and item_id in open_ids
      }
    end)
  end

  # `value` may be a single id or a list; "single" honors only the first.
  @spec resolve_open_ids(term(), String.t()) :: [String.t()]
  defp resolve_open_ids(nil, _type), do: []

  defp resolve_open_ids(value, "single") do
    case List.wrap(value) do
      [first | _] -> [first]
      [] -> []
    end
  end

  defp resolve_open_ids(value, _multiple), do: List.wrap(value)

  @spec icon_size(String.t()) :: String.t()
  defp icon_size(size), do: @icon_size[size] || "sm"

  @spec chevron_class() :: String.t()
  defp chevron_class, do: @chevron_base

  @spec panel_wrapper_class() :: String.t()
  defp panel_wrapper_class, do: @panel_wrapper

  @spec panel_inner_class() :: String.t()
  defp panel_inner_class, do: @panel_inner

  @spec panel_body_class(String.t()) :: String.t()
  defp panel_body_class(size), do: @size_panel[size] || ""

  @spec item_classes(String.t()) :: String.t()
  defp item_classes(variant), do: @item_surface[variant] || ""

  @spec header_classes(String.t(), String.t()) :: String.t()
  defp header_classes(size, color) do
    merge([@header_base, @size_header[size] || "", @header_open[color] || ""])
  end
end
