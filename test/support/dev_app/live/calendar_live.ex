defmodule Pulsar.DevApp.CalendarLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Calendar

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, :variant, variant)

    ~H"""
    <.fixture_page name={"calendar-#{@variant}"} title={"Calendar (#{@variant})"}>
      <.fixture_section name={"#{@variant}-single"} title={"#{@variant} · single"}>
        <Calendar.calendar
          id={"cal-#{@variant}-single"}
          color={@variant}
          aria-label={"#{@variant} single date calendar"}
          data-fixture-cell={"#{@variant}-single"}
        />
      </.fixture_section>

      <.fixture_section name={"#{@variant}-range"} title={"#{@variant} · range"}>
        <Calendar.calendar
          id={"cal-#{@variant}-range"}
          mode="range"
          color={@variant}
          aria-label={"#{@variant} date range calendar"}
          data-fixture-cell={"#{@variant}-range"}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
