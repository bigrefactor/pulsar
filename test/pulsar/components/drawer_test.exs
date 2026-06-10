defmodule Pulsar.Components.DrawerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Drawer
  alias Pulsar.Components.Modal

  describe "drawer/1 basic structure" do
    test "renders a native dialog through the modal primitive" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d">Body</Drawer.drawer>|)
      assert html =~ "<dialog"
      assert html =~ ~s(id="d")
      assert html =~ "Body"
    end

    test "wires the title as the accessible name" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" title="Filters">Body</Drawer.drawer>|)
      assert html =~ ~s(aria-labelledby="d-title")
      assert html =~ "Filters"
    end

    test "forwards description and footer slots only when present" do
      assigns = %{}

      with_slots =
        rendered_to_string(~H"""
        <Drawer.drawer id="d" title="T">
          <:description>Help text</:description>
          Body
          <:footer>Footer row</:footer>
        </Drawer.drawer>
        """)

      assert with_slots =~ "Help text"
      assert with_slots =~ ~s(aria-describedby="d-desc")
      assert with_slots =~ "Footer row"

      without =
        rendered_to_string(~H|<Drawer.drawer id="d" title="T">Body</Drawer.drawer>|)

      refute without =~ "aria-describedby"
    end
  end

  describe "drawer/1 side geometry + animation" do
    test "right (default) anchors to the end edge and slides from the right" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d">Body</Drawer.drawer>|)
      assert html =~ "ms-auto"
      assert html =~ "rounded-s-box"
      assert html =~ "h-dvh"
      assert html =~ "animate-drawer-from-right"
      refute html =~ "animate-scale-in"
    end

    test "left anchors to the start edge and slides from the left" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" side="left">Body</Drawer.drawer>|)
      assert html =~ "me-auto"
      assert html =~ "rounded-e-box"
      assert html =~ "animate-drawer-from-left"
    end

    test "top anchors to the top, fills width, and slides from the top" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" side="top">Body</Drawer.drawer>|)
      assert html =~ "mb-auto"
      assert html =~ "max-w-none"
      assert html =~ "rounded-b-box"
      assert html =~ "animate-drawer-from-top"
    end

    test "bottom anchors to the bottom and slides from the bottom" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" side="bottom">Body</Drawer.drawer>|)
      assert html =~ "mt-auto"
      assert html =~ "rounded-t-box"
      assert html =~ "animate-drawer-from-bottom"
    end
  end

  describe "drawer/1 size semantics" do
    test "left/right size sets the width via the modal max-w scale" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" side="right" size="sm">Body</Drawer.drawer>|)
      assert html =~ "max-w-sm"
      refute html =~ "vh]"
    end

    test "top/bottom size sets the height and clears the max-width cap" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" side="bottom" size="lg">Body</Drawer.drawer>|)
      assert html =~ "max-h-[60vh]"
      assert html =~ "max-w-none"
    end
  end

  describe "drawer/1 dismissal passthrough" do
    test "forwards dismissable to the modal" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Drawer.drawer id="d" dismissable={false}>Body</Drawer.drawer>|)

      assert html =~ ~s(data-dismissable="false")
    end
  end

  describe "drawer/1 passthrough" do
    test "passes the color/variant surface through to the modal panel" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Drawer.drawer id="d" variant="solid" color="primary">Body</Drawer.drawer>|)

      assert html =~ "bg-primary/10"
    end

    test "a caller class is merged last and wins" do
      assigns = %{}
      html = rendered_to_string(~H|<Drawer.drawer id="d" class="bg-surface-2">Body</Drawer.drawer>|)
      assert html =~ "bg-surface-2"
    end
  end

  describe "drawer/1 open/close helpers" do
    test "delegate to the modal open/close events" do
      assert Drawer.open("d") == Modal.open("d")
      assert Drawer.close("d") == Modal.close("d")
    end
  end
end
