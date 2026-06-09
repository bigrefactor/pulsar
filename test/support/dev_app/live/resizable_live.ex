defmodule Pulsar.DevApp.ResizableLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Resizable

  def render(assigns) do
    orientation = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, orientation: orientation)

    ~H"""
    <.fixture_page name={"resizable-#{@orientation}"} title={"Resizable (#{@orientation})"}>
      <.fixture_section name={"#{@orientation}-basic"} title={"#{@orientation} · basic"}>
        <Resizable.resizable
          id={"rz-#{@orientation}-basic"}
          orientation={@orientation}
          class="h-64 border border-border rounded-lg"
          data-fixture-cell={"#{@orientation}-basic"}
        >
          <:panel><div class="p-4">Primary content</div></:panel>
          <:panel label={"Resize #{@orientation} basic panel"}>
            <div class="p-4">Side content</div>
          </:panel>
        </Resizable.resizable>
      </.fixture_section>

      <.fixture_section name={"#{@orientation}-collapsible"} title={"#{@orientation} · collapsible"}>
        <Resizable.resizable
          id={"rz-#{@orientation}-collapsible"}
          orientation={@orientation}
          collapsible
          class="h-64 border border-border rounded-lg"
          data-fixture-cell={"#{@orientation}-collapsible"}
        >
          <:panel><div class="p-4">Primary content</div></:panel>
          <:panel label={"Resize #{@orientation} collapsible panel"}>
            <div class="p-4">Side content</div>
          </:panel>
        </Resizable.resizable>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
