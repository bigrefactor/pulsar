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

  describe "calendar/1 attributes" do
    test "emits constraint data attributes as ISO strings" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar
          id="cal"
          min={~D[2026-01-01]}
          max={~D[2026-12-31]}
          disabled_dates={[~D[2026-06-19], "2026-07-04"]}
          disable_weekends
        />
        """)

      assert html =~ ~s(data-min="2026-01-01")
      assert html =~ ~s(data-max="2026-12-31")
      assert html =~ ~s(data-disabled-dates="2026-06-19 2026-07-04")
      assert html =~ ~s(data-disable-weekends="true")
    end

    test "single field binding renders a hidden ISO input" do
      form = Phoenix.Component.to_form(%{"starts_on" => "2026-06-10"}, as: :event)
      assigns = %{field: form[:starts_on]}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" field={@field} />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="event[starts_on]")
      assert html =~ ~s(value="2026-06-10")
      assert html =~ ~s(data-cal-value="single")
      assert html =~ ~s(data-value="2026-06-10")
    end

    test "range field binding renders start and end hidden inputs" do
      form = Phoenix.Component.to_form(%{"from" => "2026-06-10", "to" => "2026-06-20"}, as: :trip)
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" mode="range" start_field={@form[:from]} end_field={@form[:to]} />
        """)

      assert html =~ ~s(name="trip[from]")
      assert html =~ ~s(name="trip[to]")
      assert html =~ ~s(data-cal-value="start")
      assert html =~ ~s(data-cal-value="end")
      assert html =~ ~s(data-value="2026-06-10/2026-06-20")
    end

    test "applies the color accent and cell size via data-cell-class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" color="success" size="lg" />
        """)

      assert html =~ "data-[selected=true]:bg-success"
      assert html =~ "h-10 w-10"
    end

    test "day cell class list includes cursor-pointer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="cal" />
        """)

      assert html =~ "cursor-pointer"
    end
  end

  describe "calendar/1 id resolution" do
    test "raises when given neither an id nor a field" do
      assigns = %{}

      assert_raise ArgumentError, ~r/<\.calendar> requires an :id/, fn ->
        rendered_to_string(~H"""
        <Calendar.calendar />
        """)
      end
    end

    test "derives its id from a bound field" do
      form = to_form(%{"starts_on" => nil}, as: :user)
      assigns = %{field: form[:starts_on]}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar field={@field} />
        """)

      assert html =~ ~s(id="calendar-user_starts_on")
    end

    test "renders the caller's id unchanged" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar id="picker" />
        """)

      assert html =~ ~s(id="picker")
    end
  end

  # `rest` is a global, so a caller's `form` would otherwise land on the
  # container div and leave the input the form actually submits unassociated.
  describe "calendar/1 submitted inputs" do
    test "form associates the hidden input with an external form" do
      form = to_form(%{"on" => "2026-06-10"}, as: :ev)
      assigns = %{field: form[:on]}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar field={@field} form="signup-form" />
        """)

      assert [input] = Regex.scan(~r/<input[^>]*data-cal-value[^>]*>/, html) |> Enum.map(&hd/1)
      assert input =~ ~s(form="signup-form")
    end

    test "form associates both bound inputs in range mode" do
      form = to_form(%{"from" => "2026-06-10", "to" => "2026-06-20"}, as: :trip)
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <Calendar.calendar mode="range" start_field={@form[:from]} end_field={@form[:to]} form="signup-form" />
        """)

      inputs = Regex.scan(~r/<input[^>]*data-cal-value[^>]*>/, html) |> Enum.map(&hd/1)

      assert length(inputs) == 2
      assert Enum.all?(inputs, &(&1 =~ ~s(form="signup-form")))
    end
  end
end
