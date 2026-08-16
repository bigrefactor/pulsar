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

    test "table/1 derives its ids from the caller-supplied id without repeating one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.table id="users" rows={[]}>
          <:col :let={u} label="Name">{u}</:col>
        </CoreComponents.table>
        """)

      ids = Regex.scan(~r/ id="([^"]*)"/, html, capture: :all_but_first) |> List.flatten()

      assert "users-tbody" in ids
      assert ids == Enum.uniq(ids)
      assert Enum.all?(ids, &String.starts_with?(&1, "users"))
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

  describe "table/1 sortable headers" do
    test "forwards the complete sortable column contract" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.table id="people" rows={[]} aria-label="People">
          <:col label="Name" sortable sort_direction="descending" on_sort="sort-name" />
        </CoreComponents.table>
        """)

      document = LazyHTML.from_fragment(html)
      [header] = document |> LazyHTML.query("thead th[aria-sort=descending]") |> Enum.to_list()

      assert LazyHTML.query(header, "button[phx-click=sort-name]") |> Enum.to_list() != []
      assert LazyHTML.query(header, ".hero-chevron-down[aria-hidden=true]") |> Enum.to_list() != []
    end
  end

  describe "simple_form/1 layout" do
    test "renders children as direct form children under the form's own rhythm" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <CoreComponents.simple_form for={@form}>
          <p>inner content</p>
          <:actions>
            <button type="submit">Save</button>
          </:actions>
        </CoreComponents.simple_form>
        """)

      assert html =~ "inner content"
      assert html =~ "Save"
      assert html =~ "space-y-6"
      refute html =~ "space-y-8"
    end
  end

  describe "button/1 invoker attributes" do
    # The drop-in splats `@rest` into `Button.button`, so it needs the same opt-in
    # its delegate has — otherwise a call site through core_components warns even
    # though the attribute renders.
    test "the :global opts them in so call sites do not warn" do
      attrs = CoreComponents.__components__()[:button].attrs
      global = Enum.find(attrs, &(&1.type == :global))
      include = Keyword.get(global.opts, :include, [])

      for name <- ~w(popovertarget popovertargetaction command commandfor) do
        assert name in include,
               "core_components button/1 does not include #{name} in its :global"
      end
    end

    test "the invoker attributes survive the delegation to Button.button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CoreComponents.button popovertarget="filters" popovertargetaction="hide">
          Cancel
        </CoreComponents.button>
        """)

      assert html =~ ~r/<button[^>]*popovertarget="filters"/
      assert html =~ ~r/<button[^>]*popovertargetaction="hide"/
    end
  end
end
