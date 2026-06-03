defmodule Pulsar.DevApp.Keyboard.ModalLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Modal

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-modal-open" type="button" phx-click={Modal.open("kbd-modal")}>
        Open modal
      </button>

      <Modal.modal id="kbd-modal" title="Edit item">
        <:description>Edit the item below.</:description>
        <input id="kbd-modal-input" type="text" autofocus />
        <:footer>
          <button id="kbd-modal-cancel" type="button" phx-click={Modal.close("kbd-modal")}>
            Cancel
          </button>
          <button id="kbd-modal-confirm" type="button">Confirm</button>
        </:footer>
      </Modal.modal>

      <button id="kbd-modal-locked-open" type="button" phx-click={Modal.open("kbd-modal-locked")}>
        Open locked modal
      </button>

      <Modal.modal id="kbd-modal-locked" title="Locked" dismissable={false}>
        <input id="kbd-modal-locked-input" type="text" autofocus />
        <:footer>
          <button
            id="kbd-modal-locked-close"
            type="button"
            phx-click={Modal.close("kbd-modal-locked")}
          >
            Close
          </button>
        </:footer>
      </Modal.modal>
    </main>
    """
  end
end
