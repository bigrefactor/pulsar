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
  @filterable ["Aardvark", "Beetle", "Beetlejuice"]
  @async_options ["Cormorant", "Dugong"]
  @async_error_options ["Egret", "Flamingo"]

  # Deliberately slow, so a test can observe the in-flight state before it
  # resolves; and deliberately raising, to exercise the failure branch.
  defp slow_filter do
    fn _query, _options ->
      Process.sleep(50)
      [{"Remote result", "remote"}]
    end
  end

  defp failing_filter, do: fn _query, _options -> raise "upstream down" end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       flat: @flat,
       grouped: @grouped,
       decorated: @decorated,
       slotted: @slotted,
       filterable: @filterable,
       slow: slow_filter(),
       failing: failing_filter(),
       async_options: @async_options,
       async_error_options: @async_error_options
     )}
  end

  def handle_event("touch_async", _params, socket) do
    send_update(Command, id: "cmd-async", class: "ring-0")
    {:noreply, socket}
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

      <.fixture_section name="filterable" title="Filtering target">
        <Command.command id="cmd-filter" label="Search filterable" options={@filterable} />
      </.fixture_section>

      <.fixture_section name="globals" title="Global attributes">
        <Command.command
          id="cmd-globals"
          label="Search globals"
          options={@flat}
          data-testid="cmd-globals-marker"
        />
      </.fixture_section>

      <.fixture_section name="slots" title="Custom item and empty slots">
        <Command.command id="cmd-item-slot" label="Search custom rows" options={@slotted}>
          <:item :let={option}>ROW[{option.value}]</:item>
        </Command.command>

        <Command.command id="cmd-empty-slot" label="Search custom empty" options={[]}>
          <:empty>CUSTOM-EMPTY</:empty>
        </Command.command>
      </.fixture_section>

      <.fixture_section name="async" title="Async source">
        <Command.command
          id="cmd-async"
          label="Search remote"
          options={@async_options}
          filter={@slow}
          async
        />
        <button id="cmd-async-touch" type="button" phx-click="touch_async">Touch</button>
      </.fixture_section>

      <.fixture_section name="async-error" title="Async source that fails">
        <Command.command
          id="cmd-async-error"
          label="Search failing remote"
          options={@async_error_options}
          filter={@failing}
          async
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
