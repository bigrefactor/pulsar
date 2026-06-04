defmodule Pulsar.Components.AlertDialog do
  @moduledoc """
  Constrained confirmation dialog for destructive actions.

  Built on `modal/1`: it traps focus, dims the page, and locks background scroll,
  but bakes in a fixed Cancel/Confirm footer so the destructive command rides only
  on the Confirm button. Escape and the Cancel button dismiss it without running
  that command; backdrop clicks and the corner close button are removed so the
  choice can't be dismissed by accident.

  Render it anywhere and open it with `open/2`. Pass the destructive command as
  `on_confirm` — it runs, and then the dialog closes.

  ## Examples

      <.button color="danger" phx-click={AlertDialog.open("delete-account")}>
        Delete account
      </.button>

      <.alert_dialog
        id="delete-account"
        title="Delete account?"
        on_confirm={JS.push("delete_account")}
        confirm_label="Delete"
      >
        This permanently deletes your account and all of its data. This can't be undone.
      </.alert_dialog>

  A non-destructive but important confirm reuses the same component with a
  different `color`, which tints the panel and the Confirm button together:

      <.alert_dialog
        id="publish"
        title="Publish now?"
        variant="solid"
        color="primary"
        confirm_label="Publish"
        on_confirm={JS.push("publish")}
      >
        The post becomes visible to everyone immediately.
      </.alert_dialog>

  ## Passing data to the action

  `on_confirm` is a `Phoenix.LiveView.JS` command, so send data to the server with
  `JS.push/2`'s `value:` — the equivalent of `phx-value-*` on a plain button. This
  is the supported way to pass variables; the command only ever fires from Confirm.

      <.alert_dialog
        id="delete-item"
        title="Delete item?"
        confirm_label="Delete"
        on_confirm={JS.push("delete_item", value: %{id: @item.id})}
      >
        This permanently deletes {@item.name}.
      </.alert_dialog>

  The event arrives in `handle_event/3` with the value as params:

      def handle_event("delete_item", %{"id" => id}, socket) do
        # ...
      end

  Unlike `phx-value-*` (always strings), `value:` preserves JSON types, so `id`
  arrives as an integer here. Compose more commands with `|>` — they all run, then
  the dialog closes: `JS.push("delete_item", value: %{id: id}) |> JS.patch(~p"/items")`.

  ## Accessibility

  - Renders as `role="alertdialog"`; `title` is the accessible name and the body is
    wired as the dialog's `aria-describedby`.
  - Focus lands on the Cancel button when it opens, so an accidental Enter can't
    trigger the destructive action.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Button
  alias Pulsar.Components.Modal

  # Inline ID generator
  defp generate_id(prefix \\ "alert-dialog") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:id, :string, doc: "Dialog ID (auto-generated if omitted). Targeted by the open/close helpers.")

  attr(:title, :string, required: true, doc: "The question; wired as the dialog's accessible name")

  attr(:on_confirm, JS,
    default: %JS{},
    doc:
      "JS commands to run when Confirm is activated (the dialog closes afterward); pass data with JS.push(event, value: %{...})"
  )

  attr(:confirm_label, :string,
    default: "Confirm",
    doc: ~s{Confirm button text. Use with i18n: gettext("Confirm")}
  )

  attr(:cancel_label, :string,
    default: "Cancel",
    doc: ~s{Cancel button text. Use with i18n: gettext("Cancel")}
  )

  attr(:variant, :string,
    default: "elevated",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style of the dialog surface"
  )

  attr(:color, :string,
    default: "danger",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "The dialog's semantic color: tints the panel (for solid/outline/ghost variants) and colors the Confirm button"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg xl),
    doc: "Max width and interior padding"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes for the dialog")

  attr(:rest, :global,
    include: ~w(open),
    doc: "Additional dialog attributes"
  )

  slot(:inner_block, required: true, doc: "The alert message; announced as aria-describedby")

  @doc """
  Renders a focus-trapped confirmation dialog for a destructive action.

  Open it with the `open/2` helper from a control elsewhere on the page. The
  destructive command passed as `on_confirm` is wired only to the Confirm button.

  ## Examples

      <.alert_dialog id="delete" title="Delete project?" on_confirm={JS.push("delete")}>
        This can't be undone.
      </.alert_dialog>
  """
  @spec alert_dialog(map()) :: Rendered.t()
  def alert_dialog(assigns) do
    assigns = assign_new(assigns, :id, fn -> generate_id() end)

    ~H"""
    <Modal.modal
      id={@id}
      title={@title}
      variant={@variant}
      color={@color}
      size={@size}
      dismissable={true}
      backdrop_close={false}
      show_close_button={false}
      role="alertdialog"
      aria-describedby={"#{@id}-message"}
      class={@class}
      {@rest}
    >
      <div id={"#{@id}-message"}>{render_slot(@inner_block)}</div>
      <:footer>
        <Button.button variant="ghost" color="neutral" phx-click={Modal.close(@id)} autofocus>
          {@cancel_label}
        </Button.button>
        <Button.button color={@color} phx-click={Modal.close(@on_confirm, @id)}>
          {@confirm_label}
        </Button.button>
      </:footer>
    </Modal.modal>
    """
  end

  # Each helper delegates to the underlying modal, which dispatches the open/close
  # events its colocated hook listens for. Two explicit arities (not `js \\ %JS{}`)
  # keep the one-arg form from constructing an opaque `JS.t()` here.

  @doc """
  Opens the alert dialog. Pass the dialog `id`.

      <button phx-click={AlertDialog.open("delete")}>Delete</button>
  """
  @spec open(String.t()) :: JS.t()
  def open(id), do: Modal.open(id)

  @doc """
  Opens the alert dialog, composing onto an existing `Phoenix.LiveView.JS` pipeline.
  """
  @spec open(JS.t(), String.t()) :: JS.t()
  def open(js, id), do: Modal.open(js, id)

  @doc """
  Closes the alert dialog. Pass the dialog `id`.
  """
  @spec close(String.t()) :: JS.t()
  def close(id), do: Modal.close(id)

  @doc """
  Closes the alert dialog, composing onto an existing `Phoenix.LiveView.JS` pipeline.
  """
  @spec close(JS.t(), String.t()) :: JS.t()
  def close(js, id), do: Modal.close(js, id)
end
