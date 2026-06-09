defmodule Pulsar.Components.Resizable do
  @moduledoc """
  Two panels split by a draggable handle.

  The region stays in normal document flow — it does not overlay or trap focus.
  Drag the handle (or focus it and use the keyboard) to resize the second panel;
  the first panel flexes to fill the rest of the space.

  ## Examples

      <.resizable id="dock" default_size={30} min_size={15} max_size={60}>
        <:panel>
          <main>Primary content…</main>
        </:panel>
        <:panel label="Resize side panel">
          <section>Side content…</section>
        </:panel>
      </.resizable>

      # Stacked, collapsible
      <.resizable id="logs" orientation="vertical" collapsible default_size={40}>
        <:panel>…</:panel>
        <:panel label="Resize log panel">…</:panel>
      </.resizable>

  ## Sizing

  `default_size`, `min_size` and `max_size` are percentages of the group that
  control the second panel; the first panel flexes to fill the remainder. Sizing
  is ephemeral and resets on reload.

  ## Keyboard

  Focus the handle, then: arrow keys resize by 1%, Page Up/Down by 10%, and
  Home/End jump to the minimum/maximum. Double-click the handle to reset to
  `default_size`. When `collapsible`, press Enter on the focused handle to collapse or expand the
  second panel.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Pulsar.Components.Icon

  attr :id, :string, required: true, doc: "Required. Roots the panel and separator ids and the hook."

  attr :orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "`horizontal` splits side-by-side (drag ←→); `vertical` stacks (drag ↕)."

  attr :default_size, :integer, default: 30, doc: "Initial size of the second panel, as a percent of the group."
  attr :min_size, :integer, default: 15, doc: "Smallest size of the second panel, as a percent."
  attr :max_size, :integer, default: 60, doc: "Largest size of the second panel, as a percent."
  attr :collapsible, :boolean, default: false, doc: "Allow the second panel to collapse to `collapsed_size`."
  attr :collapsed_size, :integer, default: 0, doc: "Size the second panel snaps to when collapsed, as a percent."
  attr :class, :string, default: "", doc: "Additional classes for the group element."
  attr :rest, :global, doc: "Additional HTML attributes for the group element."

  slot :panel, required: true, doc: "Exactly two panels, in source order. `label` on the second names the separator." do
    attr :label, :string
    attr :class, :string
  end

  def resizable(assigns) do
    {panel_one, panel_two} =
      case assigns.panel do
        [one, two] -> {one, two}
        _ -> raise ArgumentError, "resizable/1 requires exactly two <:panel> slots"
      end

    label = Map.get(panel_two, :label) || "Resize panel"

    assigns =
      assigns
      |> assign(:panel_one, panel_one)
      |> assign(:panel_two, panel_two)
      |> assign(:panel_one_id, "#{assigns.id}-panel-1")
      |> assign(:panel_two_id, "#{assigns.id}-panel-2")
      |> assign(:panel_label, label)

    ~H"""
    <div
      id={@id}
      phx-hook=".PulsarResizable"
      data-orientation={@orientation}
      data-min={@min_size}
      data-max={@max_size}
      data-default={@default_size}
      data-collapsed-size={@collapsed_size}
      data-collapsible={to_string(@collapsible)}
      style={"--pulsar-resizable-size: #{@default_size}%"}
      class={merge([group_classes(@orientation), @class])}
      {@rest}
    >
      <div
        id={@panel_one_id}
        class={merge(["min-w-0 min-h-0 flex-1 basis-0 overflow-auto", Map.get(@panel_one, :class) || ""])}
      >
        {render_slot(@panel_one)}
      </div>

      <div class={handle_wrapper_classes(@orientation)}>
        <div
          role="separator"
          id={"#{@id}-separator"}
          tabindex="0"
          aria-orientation={separator_orientation(@orientation)}
          aria-controls={"#{@panel_one_id} #{@panel_two_id}"}
          aria-label={@panel_label}
          aria-valuemin={@min_size}
          aria-valuenow={@default_size}
          aria-valuetext={"#{@default_size}%"}
          aria-valuemax={@max_size}
          data-resizable-handle
          class={handle_classes(@orientation)}
        >
          <span aria-hidden="true" class={line_classes(@orientation)}></span>
        </div>
        <button
          :if={@collapsible}
          type="button"
          data-resizable-toggle
          tabindex="-1"
          aria-expanded="true"
          aria-controls={@panel_two_id}
          aria-label={@panel_label}
          class={toggle_classes(@orientation)}
        >
          <Icon.icon name="hero-chevron-right" class="size-3" />
        </button>
      </div>

      <div
        id={@panel_two_id}
        data-animating="false"
        style="flex-basis: var(--pulsar-resizable-size)"
        class={merge([panel_two_classes(), Map.get(@panel_two, :class) || ""])}
      >
        {render_slot(@panel_two)}
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarResizable">
        export default {
          mounted() {
            this.handle = this.el.querySelector('[data-resizable-handle]')
            this.separator = this.el.querySelector('[role="separator"]')
            this.panelTwo = this.el.querySelector('#' + CSS.escape(this.el.id + '-panel-2'))
            if (!this.handle || !this.separator || !this.panelTwo) return
            this.min = Number(this.el.dataset.min)
            this.max = Number(this.el.dataset.max)
            this.default = Number(this.el.dataset.default)
            this.size = this.default
            this.collapsedSize = Number(this.el.dataset.collapsedSize)
            this.collapsible = this.el.dataset.collapsible === "true"
            this.collapsed = false
            this.toggle = this.el.querySelector('[data-resizable-toggle]')
            this.bind()
          },
          updated() {
            this.min = Number(this.el.dataset.min)
            this.max = Number(this.el.dataset.max)
            this.default = Number(this.el.dataset.default)
            if (!this.separator) return
            if (this.collapsed) {
              // Re-assert collapsed state: a LiveView patch reverts the JS-set
              // aria-expanded and would otherwise clamp the size back up to min.
              this.setCollapsed(true)
              this.applySize(this.collapsedSize, false)
            } else {
              this.applySize(this.clamp(this.size), false)
            }
          },
          destroyed() {
            if (this.handle) this.unbind()
            if (this._animTimer) clearTimeout(this._animTimer)
          },
          bind() {
            this._down = (e) => this.onPointerDown(e)
            this._move = (e) => this.onPointerMove(e)
            this._up = (e) => this.onPointerUp(e)
            this._key = (e) => this.onKeydown(e)
            this._dbl = (e) => {
              if (e.target.closest('[data-resizable-toggle]')) return
              this.reset()
            }
            this.handle.addEventListener("pointerdown", this._down)
            this.handle.addEventListener("keydown", this._key)
            this.handle.addEventListener("dblclick", this._dbl)
            if (this.toggle) {
              this._toggleClick = (e) => { e.stopPropagation(); this.toggleCollapse() }
              this.toggle.addEventListener("click", this._toggleClick)
            }
          },
          unbind() {
            this.handle.removeEventListener("pointerdown", this._down)
            this.handle.removeEventListener("keydown", this._key)
            this.handle.removeEventListener("dblclick", this._dbl)
            if (this.toggle) this.toggle.removeEventListener("click", this._toggleClick)
          },
          isVertical() { return this.el.dataset.orientation === "vertical" },
          groupSize() {
            return this.isVertical() ? this.el.clientHeight : this.el.clientWidth
          },
          clamp(pct) { return Math.min(this.max, Math.max(this.min, pct)) },
          onPointerDown(e) {
            if (e.target.closest('[data-resizable-toggle]')) return
            if (e.pointerType !== "mouse") e.preventDefault()
            this.handle.setPointerCapture(e.pointerId)
            this.dragging = true
            this.animate(false)
            this.handle.addEventListener("pointermove", this._move)
            this.handle.addEventListener("pointerup", this._up)
            this.handle.addEventListener("lostpointercapture", this._up)
            this.handle.focus()
          },
          onPointerMove(e) {
            if (!this.dragging) return
            const total = this.groupSize()
            if (!total) return
            const rect = this.el.getBoundingClientRect()
            const pos = this.isVertical() ? (e.clientY - rect.top) : (e.clientX - rect.left)
            // Panel two is the trailing panel: its size is the distance from the
            // pointer to the far edge of the group.
            const pct = ((total - pos) / total) * 100
            if (this.collapsible && pct < this.min - this.min / 2) {
              if (!this.collapsed) this.collapse()
              return
            }
            if (this.collapsed) this.setCollapsed(false)
            this.applySize(this.clamp(pct), false)
          },
          onPointerUp(e) {
            this.dragging = false
            try { this.handle.releasePointerCapture(e.pointerId) } catch (_) {}
            this.handle.removeEventListener("pointermove", this._move)
            this.handle.removeEventListener("pointerup", this._up)
            this.handle.removeEventListener("lostpointercapture", this._up)
          },
          onKeydown(e) {
            if (e.target.closest('[data-resizable-toggle]')) return
            if (e.key === "Enter") {
              if (this.collapsible) { e.preventDefault(); this.toggleCollapse() }
              return
            }
            // Left/Up grow panel two (drag the handle toward the start);
            // Right/Down shrink it. Keyboard never goes below min_size.
            const growKey = this.isVertical() ? "ArrowUp" : "ArrowLeft"
            const shrinkKey = this.isVertical() ? "ArrowDown" : "ArrowRight"
            let next = this.size
            switch (e.key) {
              case growKey: next = this.size + 1; break
              case shrinkKey: next = this.size - 1; break
              case "PageUp": next = this.size + 10; break
              case "PageDown": next = this.size - 10; break
              case "Home": next = this.min; break
              case "End": next = this.max; break
              default: return
            }
            e.preventDefault()
            if (this.collapsed) this.setCollapsed(false)
            this.applySize(this.clamp(next), false)
          },
          reset() {
            if (this.collapsed) this.setCollapsed(false)
            this.applySize(this.default, true)
          },
          collapse() {
            this.setCollapsed(true)
            this.applySize(this.collapsedSize, false)
          },
          toggleCollapse() {
            if (this.collapsed) {
              this.setCollapsed(false)
              this.applySize(this.default, true)
            } else {
              this.setCollapsed(true)
              this.applySize(this.collapsedSize, true)
            }
          },
          setCollapsed(state) {
            this.collapsed = state
            if (this.toggle) this.toggle.setAttribute("aria-expanded", state ? "false" : "true")
            // Per the APG window-splitter pattern, a collapsed splitter reports its
            // collapsed value in aria-valuenow / aria-valuetext.
            const shown = Math.round(state ? this.collapsedSize : this.size)
            this.separator.setAttribute("aria-valuenow", String(shown))
            this.separator.setAttribute("aria-valuetext", shown + "%")
          },
          setAnimating(on) {
            this.panelTwo.dataset.animating = on ? "true" : "false"
          },
          animate(on) {
            this.setAnimating(on)
            if (this._animTimer) {
              clearTimeout(this._animTimer)
              this._animTimer = null
            }
            if (on) {
              // Guarantee the flag clears even if no transition runs
              // (prefers-reduced-motion, or flex-basis unchanged) so it cannot
              // leave the panel permanently animating.
              this._animTimer = setTimeout(() => {
                this.setAnimating(false)
                this._animTimer = null
              }, 400)
            }
          },
          applySize(pct, animate) {
            const changed = Math.round(pct) !== Math.round(this.size)
            this.size = pct
            this.el.style.setProperty("--pulsar-resizable-size", pct + "%")
            const rounded = Math.round(pct)
            this.separator.setAttribute("aria-valuenow", String(rounded))
            this.separator.setAttribute("aria-valuetext", rounded + "%")
            this.animate(animate && changed)
          }
        }
      </script>
    </div>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # A horizontal split (side-by-side) needs a VERTICAL separator, and vice-versa.
  @spec separator_orientation(String.t()) :: String.t()
  defp separator_orientation("vertical"), do: "horizontal"
  defp separator_orientation(_), do: "vertical"

  @spec group_classes(String.t()) :: String.t()
  defp group_classes("vertical"), do: "flex flex-col w-full h-full min-h-0"
  defp group_classes(_), do: "flex flex-row w-full h-full min-w-0"

  @spec panel_two_classes() :: String.t()
  defp panel_two_classes do
    "min-w-0 min-h-0 grow-0 shrink-0 overflow-auto " <>
      "data-[animating=true]:transition-[flex-basis] data-[animating=true]:duration-normal " <>
      "data-[animating=true]:ease-standard motion-reduce:transition-none"
  end

  # The flex divider slot. Holds the separator and (when collapsible) the toggle
  # as SIBLINGS — the toggle must not nest inside the interactive separator.
  @spec handle_wrapper_classes(String.t()) :: String.t()
  defp handle_wrapper_classes("vertical"), do: "relative flex h-6 shrink-0 grow-0 items-center justify-center"
  defp handle_wrapper_classes(_), do: "relative flex w-6 shrink-0 grow-0 items-center justify-center"

  # ≥24px grab zone (WCAG 2.5.8 Target Size); fills the relative wrapper so the
  # focus ring frames the whole handle and the centered toggle overlays it.
  @spec handle_classes(String.t()) :: String.t()
  defp handle_classes("vertical") do
    "group/handle absolute inset-0 flex cursor-row-resize items-center " <>
      "justify-center touch-none select-none outline-none focus-visible:ring-2 focus-visible:ring-ring " <>
      "focus-visible:ring-offset-1 focus-visible:ring-offset-background"
  end

  defp handle_classes(_) do
    "group/handle absolute inset-0 flex cursor-col-resize items-center " <>
      "justify-center touch-none select-none outline-none focus-visible:ring-2 focus-visible:ring-ring " <>
      "focus-visible:ring-offset-1 focus-visible:ring-offset-background"
  end

  @spec line_classes(String.t()) :: String.t()
  defp line_classes("vertical") do
    "h-px w-full bg-border transition-colors duration-fast ease-standard " <>
      "group-hover/handle:bg-border-strong group-focus-visible/handle:bg-primary"
  end

  defp line_classes(_) do
    "w-px h-full bg-border transition-colors duration-fast ease-standard " <>
      "group-hover/handle:bg-border-strong group-focus-visible/handle:bg-primary"
  end

  # Small round affordance centered on the handle. The chevron flips when the
  # panel is collapsed (aria-expanded="false") and points the right way per
  # orientation.
  @spec toggle_classes(String.t()) :: String.t()
  defp toggle_classes(orientation) do
    rotate =
      if orientation == "vertical",
        do: "rotate-90 aria-[expanded=false]:-rotate-90",
        else: "aria-[expanded=false]:rotate-180"

    merge([
      "absolute left-1/2 top-1/2 z-10 inline-flex size-5 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full",
      "border border-border bg-background text-muted-foreground shadow-sm",
      "transition-[color,transform] duration-fast ease-standard hover:text-foreground",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
      rotate
    ])
  end
end
