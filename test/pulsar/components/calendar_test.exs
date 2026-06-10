defmodule Pulsar.Components.CalendarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Calendar

  describe "calendar/1 structure" do
    test "renders the grid container wired to the colocated hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" />
        """)

      assert html =~ ~s(id="cal")
      assert html =~ ~s(phx-hook="Pulsar.Components.Calendar.PulsarCalendar")
      assert html =~ ~s(data-mode="single")
      assert html =~ ~s(data-months="1")
      assert html =~ ~s(role="application")
    end

    test "range mode defaults to two months" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" mode="range" />
        """)

      assert html =~ ~s(data-mode="range")
      assert html =~ ~s(data-months="2")
    end
  end
end
