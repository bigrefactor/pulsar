defmodule Pulsar.Components.PopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Popover

  describe "popover/1 basic functionality" do
    test "renders a trigger and a native popover panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop">
          <:trigger><button>Open</button></:trigger>
          Panel body
        </Popover.popover>
        """)

      assert html =~ "Open"
      assert html =~ "Panel body"
      assert html =~ ~s(id="pop")
      # native popover panel + colocated hook
      assert html =~ ~s(popover="auto")
      assert html =~ "PulsarPopover"
    end

    test "auto-generates a panel id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover>
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ ~s(id="popover-)
    end
  end

  describe "popover/1 positioning contract (data-*)" do
    test "defaults placement and offset, exposes closed state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ ~s(data-placement="bottom-start")
      assert html =~ ~s(data-offset="8")
      assert html =~ ~s(data-state="closed")
    end

    test "placement and offset are configurable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" placement="top-end" offset={12}>
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ ~s(data-placement="top-end")
      assert html =~ ~s(data-offset="12")
    end
  end

  describe "popover/1 variants, colors, sizes (mirrors Card)" do
    test "elevated neutral default is a surface panel with a shadow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "bg-surface-1"
      assert html =~ "shadow-dropdown"
    end

    test "solid color uses a soft tint + border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" variant="solid" color="danger">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "bg-danger/10"
      assert html =~ "border-danger/20"
    end

    test "outline color uses a colored border on a surface" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" variant="outline" color="primary">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "border-primary"
    end

    test "size controls panel padding" do
      cases = %{"xs" => "p-2", "sm" => "p-3", "md" => "p-4", "lg" => "p-5", "xl" => "p-6"}

      for {size, pad} <- cases do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Popover.popover id="pop" size={@size}>
            <:trigger><button>Open</button></:trigger>
            Body
          </Popover.popover>
          """)

        assert html =~ pad, "expected size=#{size} to render #{pad}"
      end
    end

    test "carries the popover z-index layer and a min width floor" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "z-popover"
      assert html =~ "min-w-48"
    end
  end

  describe "popover/1 callbacks and passthrough" do
    test "on_open / on_close are emitted as JS commands" do
      assigns = %{
        on_open: JS.dispatch("opened", to: "#x"),
        on_close: JS.dispatch("closed", to: "#x")
      }

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" on_open={@on_open} on_close={@on_close}>
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "data-on-open"
      assert html =~ "data-on-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end

    test "passes through role and aria attributes onto the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" role="dialog" aria-label="Filters">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-label="Filters")
    end
  end

  describe "popover/1 customization (Twm merge)" do
    test "user class overrides the default surface (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="pop" class="bg-foreground text-background">
          <:trigger><button>Open</button></:trigger>
          Body
        </Popover.popover>
        """)

      assert html =~ "bg-foreground"
      refute html =~ "bg-surface-1"
    end
  end
end
