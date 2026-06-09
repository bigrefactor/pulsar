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

  describe "resizable/1 collapse (opt-in)" do
    test "renders no toggle by default" do
      refute basic() =~ "data-resizable-toggle"
    end

    test "renders an accessible chevron toggle when collapsible" do
      html = basic(%{extra: [collapsible: true]})
      assert html =~ "data-resizable-toggle"
      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(aria-controls="rz-panel-2")
      # The toggle is named for the panel it controls.
      assert html =~ ~r/data-resizable-toggle[^>]*aria-label="Resize side panel"/s
    end

    test "exposes collapse config to the hook when collapsible" do
      html = basic(%{extra: [collapsible: true, collapsed_size: 0]})
      assert html =~ ~s(data-collapsible="true")
      assert html =~ ~s(data-collapsed-size="0")
    end

    test "toggle is not a tab stop (the separator already is)" do
      html = basic(%{extra: [collapsible: true]})
      assert html =~ ~r/data-resizable-toggle[^>]*tabindex="-1"/s
    end
  end

  describe "resizable/1 hook wiring" do
    test "attaches the colocated hook via a static literal" do
      assert basic() =~ "PulsarResizable"
    end

    test "exposes drag config to the hook as data attributes" do
      html = basic(%{extra: [min_size: 10, max_size: 70, default_size: 25]})
      assert html =~ ~s(data-min="10")
      assert html =~ ~s(data-max="70")
      assert html =~ ~s(data-default="25")
      assert html =~ ~s(data-orientation="horizontal")
    end

    test "handle disables native touch gestures so touch-drag resizes" do
      assert basic() =~ "touch-none"
    end

    test "controlled panel starts un-animated (instant drag)" do
      assert basic() =~ ~s(data-animating="false")
    end
  end
end
