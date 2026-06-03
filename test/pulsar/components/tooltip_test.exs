defmodule Pulsar.Components.TooltipTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Tooltip

  describe "tooltip/1 basic functionality" do
    test "renders a trigger and a tooltip panel opened on hover/focus" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip">
          <:trigger><button>Help</button></:trigger>
          More info
        </Tooltip.tooltip>
        """)

      assert html =~ "Help"
      assert html =~ "More info"
      assert html =~ ~s(id="tip")
      # Composes Popover in hover/manual mode with the tooltip role.
      assert html =~ ~s(popover="manual")
      assert html =~ ~s(data-trigger="hover")
      assert html =~ ~s(role="tooltip")
      assert html =~ "PulsarPopover"
    end

    test "auto-generates a panel id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip>
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(id="tooltip-)
    end
  end

  describe "tooltip/1 positioning contract" do
    test "defaults to a top placement and an offset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-placement="top")
      assert html =~ ~s(data-offset="8")
    end

    test "placement and offset are configurable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip" placement="right-start" offset={12}>
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-placement="right-start")
      assert html =~ ~s(data-offset="12")
    end
  end

  describe "tooltip/1 surface colors" do
    test "neutral default is an opaque solid surface sized to its content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ "bg-neutral"
      assert html =~ "text-neutral-foreground"
      # Sizes to content, not the popover min-width floor.
      refute html =~ "min-w-48"
    end

    test "each color pairs an opaque fill with its readable foreground" do
      cases = ~w(primary secondary success danger warning info)

      for color <- cases do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Tooltip.tooltip id="tip" color={@color}>
            <:trigger><button>Help</button></:trigger>
            Body
          </Tooltip.tooltip>
          """)

        assert html =~ "bg-#{color}", "expected color=#{color} to render bg-#{color}"
        assert html =~ "text-#{color}-foreground"
      end
    end

    test "size controls panel padding" do
      cases = %{"xs" => "p-2", "sm" => "p-3", "md" => "p-4", "lg" => "p-5", "xl" => "p-6"}

      for {size, pad} <- cases do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Tooltip.tooltip id="tip" size={@size}>
            <:trigger><button>Help</button></:trigger>
            Body
          </Tooltip.tooltip>
          """)

        assert html =~ pad, "expected size=#{size} to render #{pad}"
      end
    end

    test "carries the popover z-index layer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ "z-popover"
    end
  end

  describe "tooltip/1 arrow" do
    test "renders a caret by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-part="arrow")
      assert html =~ "rotate-45"
      # The caret is decorative; it must not be announced.
      assert html =~ ~s(aria-hidden="true")
    end

    test "can be disabled with arrow={false}" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip" arrow={false}>
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      refute html =~ ~s(data-part="arrow")
    end
  end

  describe "tooltip/1 callbacks and passthrough" do
    test "on_open / on_close are emitted as JS commands" do
      assigns = %{
        on_open: JS.dispatch("opened", to: "#x"),
        on_close: JS.dispatch("closed", to: "#x")
      }

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip" on_open={@on_open} on_close={@on_close}>
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ "data-on-open"
      assert html =~ "data-on-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end

    test "passes through aria attributes onto the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip" aria-label="Extra help">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(aria-label="Extra help")
    end
  end

  describe "tooltip/1 customization (Twm merge)" do
    test "user class overrides the default surface (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="tip" class="bg-foreground text-background">
          <:trigger><button>Help</button></:trigger>
          Body
        </Tooltip.tooltip>
        """)

      assert html =~ "bg-foreground"
      refute html =~ "bg-neutral"
    end
  end
end
