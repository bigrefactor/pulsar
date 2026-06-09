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

  describe "resizable/1 sizing validation" do
    test "raises when min_size exceeds max_size" do
      assert_raise ArgumentError, ~r/min_size <= max_size/, fn ->
        basic(%{extra: [min_size: 60, max_size: 15]})
      end
    end

    test "raises when a size falls outside 0..100" do
      assert_raise ArgumentError, ~r/0 <= min_size/, fn ->
        basic(%{extra: [min_size: -5, max_size: 60]})
      end

      assert_raise ArgumentError, ~r/0 <= min_size/, fn ->
        basic(%{extra: [min_size: 15, max_size: 120]})
      end
    end

    test "raises when default_size is outside [min_size, max_size]" do
      assert_raise ArgumentError, ~r/default_size/, fn ->
        basic(%{extra: [min_size: 20, max_size: 60, default_size: 10]})
      end
    end

    test "raises when a panel's collapsed_size is outside 0..100" do
      assigns = %{}

      assert_raise ArgumentError, ~r/collapsed_size/, fn ->
        rendered_to_string(~H"""
        <Resizable.resizable id="rz">
          <:panel>A</:panel>
          <:panel label="B" collapsible collapsed_size={-1}>B</:panel>
        </Resizable.resizable>
        """)
      end
    end

    test "accepts a valid sizing configuration" do
      html = basic(%{extra: [min_size: 10, max_size: 90, default_size: 50]})
      assert html =~ ~s(aria-valuenow="50")
    end
  end

  defp with_panels(opts) do
    p1 = Keyword.get(opts, :p1, [])
    p2 = Keyword.get(opts, :p2, [])
    assigns = %{p1: p1, p2: p2}

    rendered_to_string(~H"""
    <Resizable.resizable id="rz">
      <:panel collapsible={@p1[:collapsible] || false}>A</:panel>
      <:panel label="Resize side panel" collapsible={@p2[:collapsible] || false}>B</:panel>
    </Resizable.resizable>
    """)
  end

  describe "resizable/1 collapse (per-panel, opt-in)" do
    test "renders no toggle when neither panel is collapsible" do
      refute with_panels([]) =~ "data-resizable-toggle"
    end

    test "marking the end panel collapsible renders one end toggle" do
      html = with_panels(p2: [collapsible: true])
      assert html =~ ~s(data-resizable-toggle="end")
      refute html =~ ~s(data-resizable-toggle="start")
      assert html =~ ~r/data-resizable-toggle="end"[^>]*aria-controls="rz-panel-2"/s
      assert html =~ ~r/data-resizable-toggle="end"[^>]*aria-label="Resize side panel"/s
    end

    test "panels without a collapsible attr default to non-collapsible" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Resizable.resizable id="rz">
          <:panel>A</:panel>
          <:panel label="B">B</:panel>
        </Resizable.resizable>
        """)

      refute html =~ "data-resizable-toggle"
      assert html =~ ~s(data-collapsible-start="false")
      assert html =~ ~s(data-collapsible-end="false")
    end

    test "marking both panels collapsible renders two toggles, one per side" do
      html = with_panels(p1: [collapsible: true], p2: [collapsible: true])
      assert html =~ ~s(data-resizable-toggle="start")
      assert html =~ ~s(data-resizable-toggle="end")
      assert html =~ ~r/data-resizable-toggle="start"[^>]*aria-controls="rz-panel-1"/s
      assert html =~ ~r/data-resizable-toggle="end"[^>]*aria-controls="rz-panel-2"/s
    end

    test "toggles are real focusable buttons (no negative tabindex)" do
      html = with_panels(p1: [collapsible: true], p2: [collapsible: true])
      refute html =~ ~r/data-resizable-toggle="start"[^>]*tabindex="-1"/s
      assert html =~ ~r/<button[^>]*data-resizable-toggle="start"/s
    end

    test "toggles start expanded" do
      html = with_panels(p2: [collapsible: true])
      assert html =~ ~r/data-resizable-toggle="end"[^>]*aria-expanded="true"/s
    end

    test "exposes per-panel collapse config to the hook" do
      html = with_panels(p1: [collapsible: true], p2: [collapsible: true])
      assert html =~ ~s(data-collapsible-start="true")
      assert html =~ ~s(data-collapsible-end="true")
      assert html =~ ~s(data-collapsed-start="0")
      assert html =~ ~s(data-collapsed-end="0")
    end

    test "per-panel collapsed_size is exposed to the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Resizable.resizable id="rz">
          <:panel collapsible collapsed_size={5}>A</:panel>
          <:panel label="B" collapsible collapsed_size={8}>B</:panel>
        </Resizable.resizable>
        """)

      assert html =~ ~s(data-collapsed-start="5")
      assert html =~ ~s(data-collapsed-end="8")
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
