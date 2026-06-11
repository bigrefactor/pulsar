defmodule Pulsar.DevApp.Keyboard.DatePickerLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.DatePicker`. A single-mode
  picker with stable ids and a fixed selectable window (June 2026), so the
  integration suite can open the popover, click a calendar day, type a date,
  and assert the hidden ISO value updates. Behavior comes from
  `.PulsarDatePicker` + `.PulsarCalendar`.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.DatePicker

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{"on" => "2026-06-10"}, as: :ev)
     )}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-date-picker" title="DatePicker interaction fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-dp-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="single" title="Single (June 2026)">
        <form id="kbd-dp-form">
          <DatePicker.date_picker
            id="kbd-dp"
            field={@form[:on]}
            min="2026-06-01"
            max="2026-06-30"
          />
        </form>
      </.fixture_section>

      <.fixture_section name="single-gb" title="Single en-GB locale (June 2026)">
        <form id="kbd-dp-gb-form">
          <DatePicker.date_picker
            id="kbd-dp-gb"
            field={@form[:on]}
            locale="en-GB"
            min="2026-06-01"
            max="2026-06-30"
          />
        </form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
