defmodule Pulsar.DevApp.CommandLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Command

  @flat ["Alpha", "Beta", "Gamma"]
  @grouped [{"Europe", ["UK", "Sweden"]}, {"Asia", ["Japan"]}]
  @decorated [
    [key: "Home", value: "home", icon: "hero-home", shortcut: "G H"],
    [key: "Settings", value: "settings", icon: "hero-cog-6-tooth", description: "Workspace preferences"]
  ]
  @slotted [[key: "Zulu", value: "zulu", description: "SLOT-DEFAULT-MARKER"]]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, flat: @flat, grouped: @grouped, decorated: @decorated, slotted: @slotted)}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="command" title="Command">
      <.fixture_section
        :for={variant <- ~w(solid outline ghost elevated)}
        name={variant}
        title={"Variant: #{variant}"}
      >
        <Command.command
          id={"cmd-#{variant}"}
          label={"Search #{variant} commands"}
          variant={variant}
          options={@flat}
        />
      </.fixture_section>

      <.fixture_section name="grouped" title="Grouped">
        <Command.command id="cmd-grouped" label="Search regions" options={@grouped} />
      </.fixture_section>

      <.fixture_section name="decorated" title="Icons, shortcuts and descriptions">
        <Command.command id="cmd-decorated" label="Search settings" options={@decorated} />
      </.fixture_section>

      <.fixture_section name="empty" title="Empty">
        <Command.command id="cmd-empty" label="Search nothing" options={[]} />
      </.fixture_section>

      <.fixture_section name="slots" title="Custom item and empty slots">
        <Command.command id="cmd-item-slot" label="Search custom rows" options={@slotted}>
          <:item :let={option}>ROW[{option.value}]</:item>
        </Command.command>

        <Command.command id="cmd-empty-slot" label="Search custom empty" options={[]}>
          <:empty>CUSTOM-EMPTY</:empty>
        </Command.command>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
