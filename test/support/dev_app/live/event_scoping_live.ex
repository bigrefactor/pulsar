defmodule Pulsar.DevApp.EventScopingLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Flash
  alias Pulsar.Components.Modal
  alias Pulsar.Components.Select
  alias Pulsar.Components.Sidebar

  def render(assigns) do
    ~H"""
    <.fixture_page name="event-scoping" title="Nested component event scoping">
      <.fixture_section name="select" title="Nested Select hooks">
        <div
          id="scope-select-outer"
          phx-hook="Pulsar.Components.Select.PulsarSelect"
        >
          <select id="scope-select-outer-control" multiple>
            <option value="shared" selected>Outer shared option</option>
          </select>

          <Select.select
            id="scope-select-inner"
            name="scope_select_inner"
            multiple
            options={[{"Inner shared option", "shared"}]}
            value={["shared"]}
          />
        </div>
      </.fixture_section>

      <.fixture_section name="flash" title="Nested Flash components">
        <Flash.flash id="scope-flash-outer" auto_dismiss={false}>
          Outer flash
          <Flash.flash id="scope-flash-inner" auto_dismiss={false}>
            Inner flash
          </Flash.flash>
        </Flash.flash>
      </.fixture_section>

      <.fixture_section name="modal" title="Nested Modal components">
        <button id="scope-modal-open-outer" type="button" phx-click={Modal.open("scope-modal-outer")}>
          Open outer modal
        </button>

        <Modal.modal id="scope-modal-outer" title="Outer modal">
          <button id="scope-modal-open-inner" type="button" phx-click={Modal.open("scope-modal-inner")}>
            Open inner modal
          </button>

          <Modal.modal id="scope-modal-inner" title="Inner modal">
            Inner modal body
          </Modal.modal>
        </Modal.modal>
      </.fixture_section>

      <.fixture_section name="sidebar" title="Nested Sidebar components">
        <button
          id="scope-sidebar-open-outer"
          type="button"
          phx-click={Sidebar.show("scope-sidebar-outer")}
        >
          Open outer sidebar
        </button>

        <Sidebar.sidebar id="scope-sidebar-outer" label="Outer sidebar" collapsible="none">
          <button
            id="scope-sidebar-open-inner"
            type="button"
            phx-click={Sidebar.show("scope-sidebar-inner")}
          >
            Open inner sidebar
          </button>

          <Sidebar.sidebar id="scope-sidebar-inner" label="Inner sidebar" collapsible="none">
            Inner sidebar content
          </Sidebar.sidebar>
        </Sidebar.sidebar>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
