defmodule Pulsar.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.CoreComponents

  describe "input/1 date delegation" do
    test "type=date delegates to the Pulsar DatePicker, not a native <input type=\"date\">" do
      assigns = %{field: to_form(%{"d" => ""}, as: :ev)[:d]}

      html =
        rendered_to_string(~H"""
        <CoreComponents.input field={@field} type="date" label="Start" />
        """)

      assert html =~ ~s(phx-hook="Pulsar.Components.DatePicker.PulsarDatePicker")
      # The drop-in upgrades the native date control to the calendar picker.
      refute html =~ ~s(type="date")
    end
  end

  describe "translate_error/1" do
    test "interpolates non-count bindings via Gettext.dgettext" do
      assert CoreComponents.translate_error({"must be %{type}", [type: "valid"]}) ==
               "must be valid"
    end

    test "uses count-based plural interpolation via Gettext.dngettext" do
      assert CoreComponents.translate_error({"should be at least %{count} character(s)", [count: 8]}) ==
               "should be at least 8 character(s)"
    end
  end

  describe "translate_errors/2" do
    test "filters a form's full errors keyword list to one field and translates each" do
      errors = [
        name: {"can't be blank", []},
        age: {"is invalid", []},
        name: {"is too short", []}
      ]

      assert CoreComponents.translate_errors(errors, :name) == [
               "can't be blank",
               "is too short"
             ]
    end

    test "returns an empty list when the field has no errors" do
      assert CoreComponents.translate_errors([age: {"is invalid", []}], :name) == []
    end
  end

  describe "global attributes are not spread twice" do
    defp count_attr(html, name) do
      html |> String.split(~s( #{name}=)) |> length() |> Kernel.-(1)
    end

    test "button/1 emits a caller-supplied id exactly once" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.button id="theme-toggle" variant="ghost" color="neutral">Go</CoreComponents.button>
        """)

      assert html =~ ~s(id="theme-toggle")
      assert count_attr(html, "id") == 1
    end

    test "button/1 emits a caller-supplied aria-label exactly once" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.button id="t" aria-label="Switch theme">Go</CoreComponents.button>
        """)

      assert count_attr(html, "aria-label") == 1
    end

    test "header/1 emits a caller-supplied id exactly once" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.header id="page-header">Title</CoreComponents.header>
        """)

      assert count_attr(html, "id") == 1
    end

    test "table/1 derives a single tbody id from the caller-supplied id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.table id="users" rows={[]}>
          <:col :let={u} label="Name">{u}</:col>
        </CoreComponents.table>
        """)

      assert html =~ ~s(id="users-tbody")
      assert count_attr(html, "id") == 1
    end

    test "list/1 emits a caller-supplied id exactly once" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.list id="facts">
          <:item title="Name">Ada</:item>
        </CoreComponents.list>
        """)

      assert count_attr(html, "id") == 1
    end
  end
end
