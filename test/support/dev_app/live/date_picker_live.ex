defmodule Pulsar.DevApp.DatePickerLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.DatePicker

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       single_form: to_form(%{"on" => ""}, as: :single),
       range_form: to_form(%{"from" => "", "to" => ""}, as: :range)
     )}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="date-picker" title="DatePicker">
      <.fixture_section name="single" title="Single date picker">
        <form>
          <DatePicker.date_picker
            id="dp-single"
            field={@single_form[:on]}
            aria-label="Pick a single date"
            data-fixture-cell="single"
          />
        </form>
      </.fixture_section>

      <.fixture_section name="range" title="Range date picker">
        <form>
          <DatePicker.date_picker
            id="dp-range"
            mode="range"
            start_field={@range_form[:from]}
            end_field={@range_form[:to]}
            aria-label="Pick a date range"
            data-fixture-cell="range"
          />
        </form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
