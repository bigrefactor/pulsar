defmodule Pulsar.Components.FlashTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Flash

  describe "flash/1 basic functionality" do
    test "renders flash with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Test message</Flash.flash>
        """)

      assert html =~ ~s(<div)
      assert html =~ "Test message"
      # Default variant (solid) with default color (neutral)
      assert html =~ "bg-neutral"
      # Default size (md)
      assert html =~ "p-3"
      # Default role
      assert html =~ ~s(role="status")
      # Dismissible by default
      assert html =~ ~s(<button)
      assert html =~ ~s(aria-label="Dismiss")
    end

    test "flash base uses explicit opacity/transform transition, not transition-all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Saved</Flash.flash>
        """)

      assert html =~ "transition-[opacity,transform]"
      refute html =~ "transition-all"
    end

    test "renders with custom color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash color="success">Success message</Flash.flash>
        """)

      assert html =~ "bg-success"
      assert html =~ "Success message"
    end

    test "renders with custom variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash variant="outline" color="danger">Error message</Flash.flash>
        """)

      assert html =~ "border-danger"
      assert html =~ "text-danger"
      assert html =~ "Error message"
    end

    test "renders ghost variant with different colors" do
      assigns = %{}

      # Test ghost variant with primary color
      html_primary =
        rendered_to_string(~H"""
        <Flash.flash variant="ghost" color="primary">Primary ghost</Flash.flash>
        """)

      assert html_primary =~ "text-primary"
      assert html_primary =~ "bg-primary/10"

      # Test ghost variant with warning color
      html_warning =
        rendered_to_string(~H"""
        <Flash.flash variant="ghost" color="warning">Warning ghost</Flash.flash>
        """)

      assert html_warning =~ "text-warning"
      assert html_warning =~ "bg-warning/10"
    end

    test "renders with custom size" do
      assigns = %{}

      html_sm =
        rendered_to_string(~H"""
        <Flash.flash size="sm">Small flash</Flash.flash>
        """)

      # Small size class
      assert html_sm =~ "p-2"

      html_lg =
        rendered_to_string(~H"""
        <Flash.flash size="lg">Large flash</Flash.flash>
        """)

      # Large size class
      assert html_lg =~ "p-4"
      assert html_lg =~ "text-base"
    end
  end

  describe "flash/1 dismissible functionality" do
    test "shows dismiss button by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Dismissible flash</Flash.flash>
        """)

      assert html =~ ~s(<button)
      assert html =~ ~s(type="button")
      assert html =~ ~s(aria-label="Dismiss")
      assert html =~ "phx-click"
    end

    test "hides dismiss button when dismissible=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash dismissible={false}>Non-dismissible flash</Flash.flash>
        """)

      refute html =~ ~s(<button)
      refute html =~ ~s(aria-label="Dismiss")
    end

    test "uses a custom dismiss_label for the close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash dismiss_label="Cerrar">Localized flash</Flash.flash>
        """)

      assert html =~ ~s(aria-label="Cerrar")
      refute html =~ ~s(aria-label="Dismiss")
    end

    test "encodes the on_dismiss JS into data-on-dismiss" do
      assigns = %{on_dismiss: JS.push("remove_flash", value: %{key: "error"})}

      html =
        rendered_to_string(~H"""
        <Flash.flash on_dismiss={@on_dismiss}>Flash with event</Flash.flash>
        """)

      # The hook runs this via liveSocket.execJS on dismiss.
      assert html =~ ~s(data-on-dismiss=)
      assert html =~ "remove_flash"
    end

    test "close button is at least 24x24 to meet WCAG 2.5.8 at every size" do
      for size <- ~w(sm md lg) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Flash.flash size={@size}>Sized flash</Flash.flash>
          """)

        assert html =~ ~r/<button(?=[^>]*\baria-label="Dismiss")(?=[^>]*\bh-6 w-6\b)[^>]*>/,
               "close button should carry h-6 w-6 (24x24 WCAG 2.5.8 floor) at size=#{size}"
      end
    end

    test "close button uses focus-visible (not focus) so mouse clicks don't leave a ring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Focus test</Flash.flash>
        """)

      assert html =~ "focus-visible:ring-2"
      refute html =~ ~r/\bfocus:ring-2\b/
    end

    test "close button SVG has explicit h-full w-full sizing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Sizing test</Flash.flash>
        """)

      assert html =~ ~s(<svg class="h-full w-full")
    end
  end

  describe "flash/1 auto-dismiss functionality" do
    test "includes auto-dismiss data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash auto_dismiss={true} dismiss_after={3000}>Auto-dismiss flash</Flash.flash>
        """)

      assert html =~ ~s(data-auto-dismiss="true")
      assert html =~ ~s(data-dismiss-after="3000")
    end

    test "disables auto-dismiss when auto_dismiss=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash auto_dismiss={false}>Manual flash</Flash.flash>
        """)

      assert html =~ ~s(data-auto-dismiss="false")
    end

    test "auto_dismiss defaults to true for role=status" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash role="status">Status flash</Flash.flash>
        """)

      assert html =~ ~s(data-auto-dismiss="true")
    end

    test "auto_dismiss defaults to false for role=alert (WCAG 2.2.1)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash role="alert">Urgent message</Flash.flash>
        """)

      assert html =~ ~s(data-auto-dismiss="false")
    end

    test "explicit auto_dismiss=true on role=alert is respected" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash role="alert" auto_dismiss={true}>Urgent but timed</Flash.flash>
        """)

      assert html =~ ~s(data-auto-dismiss="true")
    end
  end

  describe "flash/1 accessibility" do
    test "includes proper ARIA attributes by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Accessible flash</Flash.flash>
        """)

      assert html =~ ~s(role="status")
      # Default live="auto" with role="status" should result in "polite"
      assert html =~ ~s(aria-live="polite")
    end

    test "does not double-ring on close button focus" do
      # Container must not carry a focus-within ring — only the close button
      # gets a focus-visible ring. Otherwise both render concentrically.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Single ring</Flash.flash>
        """)

      refute html =~ "focus-within:ring"
    end

    test "uses alert role for urgent messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash role="alert" live="assertive">Urgent flash</Flash.flash>
        """)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(aria-live="assertive")
    end

    test "automatically sets aria-live based on role when using auto" do
      assigns = %{}

      # Alert role should get assertive aria-live automatically
      html =
        rendered_to_string(~H"""
        <Flash.flash role="alert" live="auto">Auto alert</Flash.flash>
        """)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(aria-live="assertive")

      # Status role should get polite aria-live automatically
      html =
        rendered_to_string(~H"""
        <Flash.flash role="status" live="auto">Auto status</Flash.flash>
        """)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
    end

    test "includes phx-hook for JavaScript functionality" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Hooked flash</Flash.flash>
        """)

      assert html =~ ~s(PulsarFlash)
    end

    test "includes phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Flash with hook</Flash.flash>
        """)

      # Check for phx-hook attribute instead of script content
      assert html =~ ~s(phx-hook="Pulsar.Components.Flash.PulsarFlash")
    end
  end

  describe "flash/1 icon functionality" do
    test "renders with start icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>
          <:start_icon>
            <svg class="icon">...</svg>
          </:start_icon>
          Flash with icon
        </Flash.flash>
        """)

      assert html =~ ~s(<svg class="icon">...</svg>)
      assert html =~ "Flash with icon"
      # Icon should be wrapped in sized container
      # Default md size
      assert html =~ "h-5 w-5"
    end

    test "renders without icon container when no icon provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Flash without icon</Flash.flash>
        """)

      # Should not have an icon container div, but close button still has h-5 w-5
      refute html =~ ~s(<div class="h-5 w-5")
      assert html =~ "Flash without icon"
    end

    test "icon size adapts to flash size" do
      assigns = %{}

      html_sm =
        rendered_to_string(~H"""
        <Flash.flash size="sm">
          <:start_icon>
            <svg>icon</svg>
          </:start_icon>
          Small flash
        </Flash.flash>
        """)

      # Small icon size
      assert html_sm =~ "h-4 w-4"

      html_lg =
        rendered_to_string(~H"""
        <Flash.flash size="lg">
          <:start_icon>
            <svg>icon</svg>
          </:start_icon>
          Large flash
        </Flash.flash>
        """)

      # Large icon size
      assert html_lg =~ "h-6 w-6"
    end
  end

  describe "flash/1 custom attributes" do
    test "passes through custom HTML attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash class="custom-class" data-testid="flash">Custom flash</Flash.flash>
        """)

      assert html =~ ~s(class=")
      assert html =~ "custom-class"
      assert html =~ ~s(data-testid="flash")
    end

    test "merges custom classes with component classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash class="mt-4 custom-bg">Flash with custom classes</Flash.flash>
        """)

      # Should contain both component classes and custom classes
      assert html =~ "mt-4"
      assert html =~ "custom-bg"
      # Should still have base component classes
      assert html =~ "font-medium"
      assert html =~ "shadow-dropdown"
    end

    test "generates unique IDs when not provided" do
      assigns = %{}

      html1 =
        rendered_to_string(~H"""
        <Flash.flash>Flash 1</Flash.flash>
        """)

      html2 =
        rendered_to_string(~H"""
        <Flash.flash>Flash 2</Flash.flash>
        """)

      # Check that IDs are present and unique
      assert html1 =~ ~r/id="flash-\d+"/
      assert html2 =~ ~r/id="flash-\d+"/

      # Extract the actual ID values
      [[_, id1]] = Regex.scan(~r/id="(flash-\d+)"/, html1)
      [[_, id2]] = Regex.scan(~r/id="(flash-\d+)"/, html2)

      assert id1 != id2
      assert String.starts_with?(id1, "flash-")
      assert String.starts_with?(id2, "flash-")
    end

    test "uses provided ID" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash id="custom-flash-id">Flash with custom ID</Flash.flash>
        """)

      assert html =~ ~s(id="custom-flash-id")
    end
  end

  describe "flash/1 all variant and color combinations" do
    test "renders all solid variant colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="solid" color={@color}>Solid {@color}</Flash.flash>
          """)

        assert html =~ "bg-#{color}"
        assert html =~ "text-#{color}-foreground"
      end
    end

    test "renders all outline variant colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="outline" color={@color}>Outline {@color}</Flash.flash>
          """)

        assert html =~ "border-#{color}"
        # Neutral uses text-foreground, others use text-{color}
        if color == "neutral" do
          assert html =~ "text-foreground"
        else
          assert html =~ "text-#{color}"
        end
      end
    end

    test "renders all ghost variant colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="ghost" color={@color}>Ghost {@color}</Flash.flash>
          """)

        # Ghost uses different pattern for neutral vs other colors
        if color == "neutral" do
          assert html =~ "text-foreground"
          assert html =~ "bg-surface-1"
        else
          assert html =~ "text-#{color}"
          assert html =~ "bg-#{color}/10"
        end
      end
    end
  end

  describe "flash/1 data attribute validation" do
    test "includes validated dismiss_after in data attributes" do
      assigns = %{}

      # Test normal value
      html_normal =
        rendered_to_string(~H"""
        <Flash.flash dismiss_after={3000}>Normal timeout</Flash.flash>
        """)

      assert html_normal =~ ~s(data-dismiss-after="3000")

      # Very large value: rendered as given; the JS hook clamps to 60000 at runtime
      html_large =
        rendered_to_string(~H"""
        <Flash.flash dismiss_after={120_000}>Large timeout</Flash.flash>
        """)

      assert html_large =~ ~s(data-dismiss-after="120000")

      # Very small value: rendered as given; the JS hook falls back to 5000 at runtime
      html_small =
        rendered_to_string(~H"""
        <Flash.flash dismiss_after={50}>Small timeout</Flash.flash>
        """)

      assert html_small =~ ~s(data-dismiss-after="50")
    end

    test "includes auto_dismiss boolean in data attributes" do
      assigns = %{}

      # Test enabled (default)
      html_enabled =
        rendered_to_string(~H"""
        <Flash.flash auto_dismiss={true}>Auto dismiss enabled</Flash.flash>
        """)

      assert html_enabled =~ ~s(data-auto-dismiss="true")

      # Test disabled
      html_disabled =
        rendered_to_string(~H"""
        <Flash.flash auto_dismiss={false}>Auto dismiss disabled</Flash.flash>
        """)

      assert html_disabled =~ ~s(data-auto-dismiss="false")
    end

    test "encodes a custom on_dismiss JS command" do
      assigns = %{on_dismiss: JS.push("custom_dismiss")}

      html =
        rendered_to_string(~H"""
        <Flash.flash on_dismiss={@on_dismiss}>Custom dismiss event</Flash.flash>
        """)

      assert html =~ ~s(data-on-dismiss=)
      assert html =~ "custom_dismiss"
    end
  end

  describe "flash/1 JavaScript hook integration" do
    test "includes correct phx-hook attribute for JavaScript functionality" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Hooked flash</Flash.flash>
        """)

      # Should use colocated hook notation (expanded to full module name)
      assert html =~ ~s(phx-hook="Pulsar.Components.Flash.PulsarFlash")
    end

    test "includes all required data attributes for JavaScript hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash
          auto_dismiss={true}
          dismiss_after={5000}
          on_dismiss={JS.push("handle_dismiss")}
        >
          Complete flash
        </Flash.flash>
        """)

      # All JavaScript hook data attributes should be present
      assert html =~ ~s(data-auto-dismiss="true")
      assert html =~ ~s(data-dismiss-after="5000")
      assert html =~ ~s(data-on-dismiss=)
      assert html =~ "handle_dismiss"
    end

    test "defaults on_dismiss to an empty JS command" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Flash without dismiss handler</Flash.flash>
        """)

      # The empty %JS{} default encodes to "[]"; the hook treats it as
      # "no callback" and removes the flash from the DOM instead.
      assert html =~ ~s(data-on-dismiss="[]")
      assert html =~ "Flash without dismiss handler"
    end
  end
end
