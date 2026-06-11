defmodule Pulsar.DevApp.Keyboard.CalendarLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Calendar`.

  A single-mode and a range-mode calendar with a fixed selectable window
  (June 2026) and one disabled date, so the integration suite can click and key
  cells and assert real selection state (`data-selected`, hidden input value)
  and that disabled cells are skipped. Behavior comes from the `.PulsarCalendar`
  colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Calendar

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       received: "",
       form: to_form(%{"on" => "2026-06-10"}, as: :ev)
     )}
  end

  # Proves the hook's hidden-input write dispatches a real input event that the
  # form's phx-change picks up — echo the received value into the DOM so the
  # interaction test can assert the server actually saw it. Also update the form
  # so the re-render preserves the updated hidden input value attribute.
  def handle_event("changed", %{"ev" => %{"on" => value}}, socket) do
    {:noreply,
     assign(socket,
       received: value,
       form: to_form(%{"on" => value}, as: :ev)
     )}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-calendar" title="Calendar interaction fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-cal-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="single" title="Single (June 2026, 19th disabled)">
        <form id="kbd-cal-form" phx-change="changed">
          <Calendar.calendar
            id="kbd-cal"
            months={1}
            value={@form[:on].value}
            min="2026-06-01"
            max="2026-06-30"
            disabled_dates={["2026-06-19"]}
            field={@form[:on]}
          />
        </form>
        <p id="kbd-cal-received">{@received}</p>
      </.fixture_section>

      <.fixture_section name="range" title="Range (June–July 2026)">
        <Calendar.calendar id="kbd-cal-range" mode="range" months={2} value={{"2026-06-25", "2026-07-08"}} />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
