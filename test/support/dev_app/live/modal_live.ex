defmodule Pulsar.DevApp.ModalLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Modal

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="modal" title="Modal">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Modal.modal
          :for={color <- @colors}
          id={"modal-#{variant}-#{color}"}
          variant={variant}
          color={color}
          title={"#{variant} #{color}"}
          open
          class="static m-0 w-64"
          data-fixture-cell={"#{variant}-#{color}"}
        >
          <:description>Dialog body for {variant} {color}.</:description>
          <p class="text-sm">Panel content</p>
          <:footer>
            <button type="button" class="rounded-field border border-border px-3 py-1.5 text-sm">
              Cancel
            </button>
          </:footer>
        </Modal.modal>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <Modal.modal
          :for={size <- @sizes}
          id={"modal-size-#{size}"}
          size={size}
          title={"size #{size}"}
          open
          class="static m-0"
          data-fixture-cell={"size-#{size}"}
        >
          <p class="text-sm">Panel content</p>
        </Modal.modal>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
