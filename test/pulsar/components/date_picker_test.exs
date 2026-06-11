defmodule Pulsar.Components.DatePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.DatePicker

  describe "date_picker/1 single mode" do
    test "renders a typeable display input, a hidden ISO input, and the calendar popover" do
      form = to_form(%{"on" => "2026-06-10"}, as: :ev)
      assigns = %{field: form[:on]}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" field={@field} />
        """)

      assert html =~ ~s(phx-hook="Pulsar.Components.DatePicker.PulsarDatePicker")
      # hidden ISO input is the submitted value
      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="ev[on]")
      assert html =~ ~s(value="2026-06-10")
      # display input carries no name (never submitted)
      assert html =~ ~s(data-dp-display="single")
      # composes the calendar
      assert html =~ ~s(phx-hook="Pulsar.Components.Calendar.PulsarCalendar")
      assert html =~ ~s(data-mode="single")
    end
  end

  describe "date_picker/1 field wrapper and anchor" do
    test "wrapper div carries the -field id and popover panel carries the matching anchor" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" />
        """)

      assert html =~ ~s(id="dp-field")
      assert html =~ ~s(data-anchor="#dp-field")
    end
  end

  describe "date_picker/1 range mode" do
    test "renders two display inputs and two hidden ISO inputs" do
      form = to_form(%{"from" => "2026-06-10", "to" => "2026-06-20"}, as: :trip)
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" mode="range" start_field={@form[:from]} end_field={@form[:to]} />
        """)

      assert html =~ ~s(name="trip[from]")
      assert html =~ ~s(name="trip[to]")
      # both ends are backed by hidden ISO inputs carrying the seeded values
      assert html =~ ~s(data-dp-value="start")
      assert html =~ ~s(data-dp-value="end")
      assert html =~ ~s(value="2026-06-10")
      assert html =~ ~s(value="2026-06-20")
      assert html =~ ~s(data-dp-display="start")
      assert html =~ ~s(data-dp-display="end")
      assert html =~ ~s(data-mode="range")
    end

    test "honors the variant attr on the input wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" variant="solid" />
        """)

      assert html =~ "bg-surface-2"
    end
  end
end
