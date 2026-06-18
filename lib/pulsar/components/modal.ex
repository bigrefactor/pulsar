defmodule Pulsar.Components.Modal do
  @moduledoc """
  Focus-trapped, dismissible overlay dialog with a dimmed backdrop.

  Render a `modal/1` anywhere on the page and open it from a button (or any
  event) with the `open/2` and `close/2` helpers. While open it traps focus,
  dims the page behind a backdrop, locks background scroll, and closes on
  Escape or a backdrop click; closing returns focus to the element that opened
  it. Use it for forms, confirmations, and detail views.

  ## Examples

      <.button phx-click={Modal.open("edit")}>Edit</.button>

      <.modal id="edit" title="Edit user">
        <:description>Update the user's details.</:description>

        <.input field={@form[:name]} />

        <:footer>
          <.button variant="ghost" phx-click={Modal.close("edit")}>Cancel</.button>
          <.button phx-click={JS.push("save") |> Modal.close("edit")}>Save</.button>
        </:footer>
      </.modal>

      # A non-dismissable confirmation: Escape and backdrop clicks are ignored,
      # so the user must pick an action.
      <.modal id="confirm" title="Delete project?" dismissable={false}>
        This can't be undone.
        <:footer>
          <.button variant="ghost" phx-click={Modal.close("confirm")}>Cancel</.button>
          <.button color="danger" phx-click={JS.push("delete") |> Modal.close("confirm")}>
            Delete
          </.button>
        </:footer>
      </.modal>

  ## Opening and closing

  The modal has no trigger of its own — drive it from anywhere with `open/2`
  and `close/2`, passing the dialog `id`. Both return a `Phoenix.LiveView.JS`
  command, so they compose with `JS.push/2` and friends.

  ## Accessibility

  - Renders a native `<dialog>`: the browser provides `role="dialog"`, the
    modal focus trap, and Escape handling.
  - `title` is wired as the dialog's `aria-labelledby`; a `:description` slot is
    wired as its `aria-describedby`. Pass `aria-label` instead when you render no
    visible title.
  - Focus returns to the element that opened the dialog when it closes.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # Inline ID generator
  defp generate_id(prefix \\ "modal") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Max width and interior padding per size.
  @size_config %{
    "sm" => %{width: "max-w-sm", padding: "p-5"},
    "md" => %{width: "max-w-md", padding: "p-6"},
    "lg" => %{width: "max-w-lg", padding: "p-6"},
    "xl" => %{width: "max-w-2xl", padding: "p-7"}
  }

  # Layout + the overlay contract shared by every modal. The dialog is the panel:
  # it centers itself in the viewport and dims the page through its `::backdrop`.
  # The entrance animation is extracted to `panel_animation` so wrappers such as
  # Drawer can substitute a directional slide.
  @panel_base_classes "z-modal m-auto w-[calc(100%-2rem)] max-h-[85vh] overflow-y-auto " <>
                        "rounded-box text-foreground focus:outline-none " <>
                        "backdrop:bg-foreground/50"

  @valid_variants ~w(solid outline ghost elevated)
  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Surface treatment per variant and color (semantic tokens only). Tints keep
  # arbitrary dialog content legible.
  @color_config %{
    "solid" => %{
      "neutral" => "bg-surface-1 border-2 border-border-strong",
      "primary" => "bg-primary/10 border-2 border-primary/20",
      "secondary" => "bg-secondary/10 border-2 border-secondary/20",
      "success" => "bg-success/10 border-2 border-success/20",
      "danger" => "bg-danger/10 border-2 border-danger/20",
      "warning" => "bg-warning/10 border-2 border-warning/20",
      "info" => "bg-info/10 border-2 border-info/20"
    },
    "outline" => %{
      "neutral" => "bg-surface-1 border-2 border-border-strong",
      "primary" => "bg-surface-1 border-2 border-primary",
      "secondary" => "bg-surface-1 border-2 border-secondary",
      "success" => "bg-surface-1 border-2 border-success",
      "danger" => "bg-surface-1 border-2 border-danger",
      "warning" => "bg-surface-1 border-2 border-warning",
      "info" => "bg-surface-1 border-2 border-info"
    },
    "ghost" => %{
      "neutral" => "bg-surface-1 border border-transparent",
      "primary" => "bg-surface-1 border border-transparent",
      "secondary" => "bg-surface-1 border border-transparent",
      "success" => "bg-surface-1 border border-transparent",
      "danger" => "bg-surface-1 border border-transparent",
      "warning" => "bg-surface-1 border border-transparent",
      "info" => "bg-surface-1 border border-transparent"
    },
    "elevated" => %{
      "neutral" => "bg-surface-1 shadow-modal",
      "primary" => "bg-surface-1 shadow-modal",
      "secondary" => "bg-surface-1 shadow-modal",
      "success" => "bg-surface-1 shadow-modal",
      "danger" => "bg-surface-1 shadow-modal",
      "warning" => "bg-surface-1 shadow-modal",
      "info" => "bg-surface-1 shadow-modal"
    }
  }

  # Compile-time check that every variant/color combination is defined.
  for variant <- @valid_variants, color <- @valid_colors do
    if !get_in(@color_config, [variant, color]) do
      raise CompileError, description: "Missing color config for variant=#{variant}, color=#{color}"
    end
  end

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Dialog ID (auto-generated if omitted). Targeted by the open/close helpers.")

  attr(:variant, :string,
    default: "elevated",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style of the dialog surface"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the dialog surface"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg xl),
    doc: "Max width and interior padding"
  )

  attr(:title, :string, default: nil, doc: "Heading text; wired as the dialog's accessible name")

  attr(:dismissable, :boolean,
    default: true,
    doc:
      "When true, Escape closes the dialog; backdrop clicks additionally require backdrop_close and the close button additionally requires show_close_button"
  )

  attr(:close_label, :string,
    default: "Close",
    doc: ~s{Accessible label for the close button. Use with i18n: gettext("Close")}
  )

  attr(:backdrop_close, :boolean,
    default: true,
    doc: "When true (and dismissable), a backdrop click closes the dialog"
  )

  attr(:show_close_button, :boolean,
    default: true,
    doc: "When true (and dismissable), the corner close (X) button is shown"
  )

  attr(:on_open, JS,
    default: %JS{},
    doc: "JS commands to run when the dialog opens"
  )

  attr(:on_close, JS,
    default: %JS{},
    doc: "JS commands to run when the dialog closes (including Escape/backdrop dismissal)"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes for the dialog")

  attr(:panel_animation, :string,
    default: "animate-scale-in",
    doc:
      ~s{CSS animation utility applied to the panel on open. Override for a different entrance, e.g. "animate-drawer-from-right".}
  )

  attr(:rest, :global,
    include: ~w(open),
    doc: "Additional dialog attributes (e.g. aria-label)"
  )

  slot(:description, doc: "Supporting text below the heading; wired as aria-describedby")
  slot(:inner_block, required: true, doc: "Dialog body")
  slot(:footer, doc: "Action row pinned below the body")

  @doc """
  Renders a focus-trapped modal dialog.

  Open and close it with the `open/2` and `close/2` helpers from a control
  elsewhere on the page.

  ## Examples

      <.modal id="edit" title="Edit user">
        <:description>Update the details.</:description>
        ...
        <:footer>
          <.button phx-click={Modal.close("edit")}>Done</.button>
        </:footer>
      </.modal>
  """
  @spec modal(map()) :: Rendered.t()
  def modal(assigns) do
    assigns = assign_new(assigns, :id, fn -> generate_id() end)

    assigns =
      assign(
        assigns,
        :dialog_classes,
        merge([
          base_classes(),
          color_classes(assigns.variant, assigns.color),
          width_classes(assigns.size),
          padding_classes(assigns.size),
          assigns.panel_animation,
          assigns.class
        ])
      )

    assigns =
      assigns
      |> assign(:has_title, assigns.title not in [nil, ""])
      |> assign(:has_description, assigns.description != [])

    ~H"""
    <dialog
      id={@id}
      phx-hook=".PulsarModal"
      data-state="closed"
      data-dismissable={to_string(@dismissable)}
      data-backdrop-close={to_string(@backdrop_close)}
      data-on-open={@on_open}
      data-on-close={@on_close}
      aria-labelledby={@has_title && "#{@id}-title"}
      aria-describedby={@has_description && "#{@id}-desc"}
      class={@dialog_classes}
      {@rest}
    >
      <div
        :if={@has_title || @has_description || (@dismissable && @show_close_button)}
        class="mb-4 flex items-start justify-between gap-4"
      >
        <div :if={@has_title || @has_description} class="space-y-1">
          <h2 :if={@has_title} id={"#{@id}-title"} class="text-lg font-semibold">{@title}</h2>
          <p :if={@has_description} id={"#{@id}-desc"} class="text-sm text-muted-foreground">
            {render_slot(@description)}
          </p>
        </div>

        <button
          :if={@dismissable && @show_close_button}
          type="button"
          aria-label={@close_label}
          phx-click={JS.dispatch("pulsar:modal-close", to: "##{@id}")}
          class="-m-1 shrink-0 rounded-field p-1 text-muted-foreground hover:bg-surface-2 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <Icon.icon name="hero-x-mark" size="sm" />
        </button>
      </div>

      <div>{render_slot(@inner_block)}</div>

      <div :if={@footer != []} class="mt-6 flex justify-end gap-3">
        {render_slot(@footer)}
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarModal">
        // Shared across every modal instance so stacked dialogs refcount the body
        // scroll lock: the first to open captures the prior overflow and the last
        // to close restores it.
        let openModalCount = 0
        let savedBodyOverflow = ""

        export default {
          mounted() {
            this.scrollLocked = false
            this.downTarget = null

            // The markup ships data-state="closed"; reconcile it with the real
            // open state for dialogs pre-opened via the `open` attribute.
            this.el.dataset.state = this.el.open ? "open" : "closed"

            this._onOpen = () => this.open()
            this._onClose = () => this.close()
            this._onCancel = (e) => this.handleCancel(e)
            this._onNativeClose = () => this.handleClose()
            this._onMouseDown = (e) => { this.downTarget = e.target }
            this._onClick = (e) => this.handleClick(e)

            this.el.addEventListener("pulsar:modal-open", this._onOpen)
            this.el.addEventListener("pulsar:modal-close", this._onClose)
            this.el.addEventListener("cancel", this._onCancel)
            this.el.addEventListener("close", this._onNativeClose)
            this.el.addEventListener("mousedown", this._onMouseDown)
            this.el.addEventListener("click", this._onClick)
          },

          isDismissable() {
            return this.el.dataset.dismissable !== "false"
          },

          backdropClose() {
            return this.el.dataset.backdropClose !== "false"
          },

          open() {
            if (this.el.open) return
            this.el.showModal()
            this.el.dataset.state = "open"
            this.lockScroll()
            this.runCallback("onOpen")
          },

          close() {
            if (this.el.open) this.el.close()
          },

          handleClose() {
            this.el.dataset.state = "closed"
            this.unlockScroll()
            this.runCallback("onClose")
          },

          handleCancel(e) {
            if (!this.isDismissable()) e.preventDefault()
          },

          handleClick(e) {
            if (!this.isDismissable() || !this.backdropClose()) return
            // A backdrop click reports the dialog as the target but lands outside
            // the dialog's box; a click on content lands inside it. Require the
            // pointer-down to have landed on the backdrop too, so a text-selection
            // drag that ends on the backdrop doesn't dismiss the dialog.
            const r = this.el.getBoundingClientRect()
            const outside =
              e.clientX < r.left || e.clientX > r.right || e.clientY < r.top || e.clientY > r.bottom
            if (e.target === this.el && this.downTarget === this.el && outside) {
              // Stop the dismissing click from bubbling to ancestors: when the
              // dialog is nested inside an element with its own click handler
              // (e.g. the open-trigger wrapper), an un-stopped backdrop click
              // would re-trigger that handler and instantly re-open the dialog.
              e.stopPropagation()
              this.el.close()
            }
          },

          lockScroll() {
            if (this.scrollLocked) return
            this.scrollLocked = true
            if (openModalCount === 0) {
              savedBodyOverflow = document.body.style.overflow
              document.body.style.overflow = "hidden"
            }
            openModalCount++
          },

          unlockScroll() {
            if (!this.scrollLocked) return
            this.scrollLocked = false
            openModalCount--
            if (openModalCount === 0) {
              document.body.style.overflow = savedBodyOverflow
            }
          },

          runCallback(name) {
            const encoded = this.el.dataset[name]
            if (encoded && encoded !== "[]" && this.liveSocket) {
              this.liveSocket.execJS(this.el, encoded)
            }
          },

          destroyed() {
            this.unlockScroll()
            this.el.removeEventListener("pulsar:modal-open", this._onOpen)
            this.el.removeEventListener("pulsar:modal-close", this._onClose)
            this.el.removeEventListener("cancel", this._onCancel)
            this.el.removeEventListener("close", this._onNativeClose)
            this.el.removeEventListener("mousedown", this._onMouseDown)
            this.el.removeEventListener("click", this._onClick)
          }
        }
      </script>
    </dialog>
    """
  end

  # Each helper is two explicit arities instead of `js \\ %JS{}`: the one-arg form
  # lets `JS.dispatch/2` build the empty pipeline *inside* the JS module, so we
  # never construct the opaque `JS.t()` here (which would trip
  # `call_without_opaque`). The two-arg form composes onto a caller's JS pipeline.

  @doc """
  Opens the modal. Pass the dialog `id`.

      <button phx-click={Modal.open("edit")}>Edit</button>
  """
  def open(id), do: JS.dispatch("pulsar:modal-open", to: "##{id}")

  @doc """
  Opens the modal, composing onto an existing `Phoenix.LiveView.JS` pipeline.
  """
  def open(js, id), do: JS.dispatch(js, "pulsar:modal-open", to: "##{id}")

  @doc """
  Closes the modal. Pass the dialog `id`.
  """
  def close(id), do: JS.dispatch("pulsar:modal-close", to: "##{id}")

  @doc """
  Closes the modal, composing onto an existing `Phoenix.LiveView.JS` pipeline.
  """
  def close(js, id), do: JS.dispatch(js, "pulsar:modal-close", to: "##{id}")

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec base_classes() :: String.t()
  defp base_classes, do: @panel_base_classes

  # `|| ""` makes the return provably `String.t()` (not `String.t() | nil`) so the
  # value passed to `Twm.merge/1` type-checks. `attr :values` guarantees the key
  # exists at runtime, so the fallback is never actually hit.
  @spec color_classes(String.t(), String.t()) :: String.t()
  defp color_classes(variant, color), do: @color_config[variant][color] || ""

  @spec width_classes(String.t()) :: String.t()
  defp width_classes(size), do: @size_config[size][:width] || ""

  @spec padding_classes(String.t()) :: String.t()
  defp padding_classes(size), do: @size_config[size][:padding] || ""
end
