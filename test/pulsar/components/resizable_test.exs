defmodule Pulsar.Components.ResizableTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Resizable

  defp basic(assigns \\ %{}) do
    assigns = Map.merge(%{id: "rz", extra: []}, assigns)

    rendered_to_string(~H"""
    <Resizable.resizable id={@id} {@extra}>
      <:panel>Primary</:panel>
      <:panel label="Resize side panel">Secondary</:panel>
    </Resizable.resizable>
    """)
  end

  describe "resizable/1 structure & ARIA" do
    test "renders both panels and their content in source order" do
      html = basic()
      assert html =~ "Primary"
      assert html =~ "Secondary"
      assert html =~ ~r/Primary.*Secondary/s
    end

    test "renders a window-splitter separator handle" do
      html = basic()
      assert html =~ ~s(role="separator")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(aria-controls="rz-panel-1 rz-panel-2")
      assert html =~ ~s(aria-label="Resize side panel")
    end

    test "reflects the controlled panel range on the separator" do
      html = basic(%{extra: [min_size: 15, max_size: 60, default_size: 30]})
      assert html =~ ~s(aria-valuemin="15")
      assert html =~ ~s(aria-valuenow="30")
      assert html =~ ~s(aria-valuemax="60")
    end

    test "inverts orientation: horizontal split uses a vertical separator" do
      assert basic() =~ ~s(aria-orientation="vertical")
      assert basic(%{extra: [orientation: "vertical"]}) =~ ~s(aria-orientation="horizontal")
    end

    test "seeds the size CSS var on the group from default_size" do
      assert basic(%{extra: [default_size: 40]}) =~ "--pulsar-resizable-size: 40%"
    end

    test "panel one flexes to fill and can shrink" do
      html = basic()
      assert html =~ "flex-1"
      assert html =~ "basis-0"
      assert html =~ "min-w-0"
    end

    test "controlled panel id carries the seeded flex-basis" do
      html = basic()
      assert html =~ ~s(id="rz-panel-2")
      assert html =~ "flex-basis: var(--pulsar-resizable-size)"
    end

    test "falls back to a default separator label when none is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Resizable.resizable id="nolabel">
          <:panel>A</:panel>
          <:panel>B</:panel>
        </Resizable.resizable>
        """)

      assert html =~ ~s(aria-label="Resize panel")
    end

    test "exposes orientation on the group for the hook" do
      assert basic() =~ ~s(data-orientation="horizontal")
      assert basic(%{extra: [orientation: "vertical"]}) =~ ~s(data-orientation="vertical")
    end

    test "announces the size as a percentage via aria-valuetext" do
      assert basic(%{extra: [default_size: 30]}) =~ ~s(aria-valuetext="30%")
    end
  end
end
