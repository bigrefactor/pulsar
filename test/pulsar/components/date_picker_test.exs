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
      # The calendar button invokes the panel from the server's markup: a
      # client-applied popovertarget is reverted by the first patch that
      # re-renders the trigger, which leaves the button dead.
      assert html =~ ~s(popovertarget="dp-pop")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="dp-pop")
    end
  end

  describe "date_picker/1 accessible labelling" do
    test "standalone single picker labels its input \"Date\"" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" />
        """)

      assert html =~ ~s(aria-label="Date")
    end

    test "labelled_externally suppresses the default aria-label so an external <label> wins" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" labelled_externally />
        """)

      refute html =~ ~s(aria-label="Date")
    end
  end

  describe "date_picker/1 required state" do
    test "required marks the display input aria-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" required />
        """)

      assert html =~ ~s(aria-required="true")
    end

    test "not required leaves the display input aria-required false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" />
        """)

      assert html =~ ~s(aria-required="false")
    end

    test "required marks both display inputs aria-required in range mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="dp" mode="range" required />
        """)

      assert html =~ ~s(aria-required="true")
      refute html =~ ~s(aria-required="false")
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

  describe "date_picker/1 id resolution" do
    test "raises when given neither an id nor a field" do
      assigns = %{}

      assert_raise ArgumentError, ~r/<\.date_picker> requires an :id/, fn ->
        rendered_to_string(~H"""
        <DatePicker.date_picker />
        """)
      end
    end

    test "derives its id from a bound field" do
      form = to_form(%{"starts_on" => nil}, as: :user)
      assigns = %{field: form[:starts_on]}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker field={@field} />
        """)

      assert html =~ ~s(id="date-picker-user_starts_on")
    end

    test "renders the caller's id unchanged" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker id="picker" />
        """)

      assert html =~ ~s(id="picker")
    end
  end

  # `disabled` and `form` govern whether and where a value is submitted, so they
  # have to reach the hidden inputs the form actually reads — the visible
  # display input carries no name and is never submitted.
  describe "date_picker/1 submitted inputs" do
    defp submitted_inputs(html) do
      ~r/<input[^>]*data-dp-value[^>]*>/ |> Regex.scan(html) |> Enum.map(&hd/1)
    end

    test "a disabled picker does not submit its value" do
      form = to_form(%{"on" => "2026-06-10"}, as: :ev)
      assigns = %{field: form[:on]}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker field={@field} disabled />
        """)

      assert [input] = submitted_inputs(html)
      assert input =~ "disabled"
    end

    test "an enabled picker leaves its value submittable" do
      form = to_form(%{"on" => "2026-06-10"}, as: :ev)
      assigns = %{field: form[:on]}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker field={@field} />
        """)

      assert [input] = submitted_inputs(html)
      refute input =~ "disabled"
    end

    test "a disabled range picker does not submit either bound value" do
      form = to_form(%{"from" => "2026-06-10", "to" => "2026-06-20"}, as: :trip)
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker mode="range" start_field={@form[:from]} end_field={@form[:to]} disabled />
        """)

      assert [_, _] = inputs = submitted_inputs(html)
      assert Enum.all?(inputs, &(&1 =~ "disabled"))
    end

    test "form associates the hidden input with an external form" do
      form = to_form(%{"on" => "2026-06-10"}, as: :ev)
      assigns = %{field: form[:on]}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker field={@field} form="signup-form" />
        """)

      assert [input] = submitted_inputs(html)
      assert input =~ ~s(form="signup-form")
    end
  end
end
