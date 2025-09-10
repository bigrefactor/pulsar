defmodule Pulsar.Components.FlashTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

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

    test "includes dismiss event in phx-click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash on_dismiss="remove_flash" flash_key="error">Flash with event</Flash.flash>
        """)

      assert html =~ ~s(phx-click=)
      # Should contain the JS.push event
      assert html =~ "remove_flash"
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

    test "includes flash key in data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash flash_key="error">Flash with key</Flash.flash>
        """)

      assert html =~ ~s(data-flash-key="error")
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
      assert html =~ ~s(aria-live="polite")
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

    test "includes phx-hook for JavaScript functionality" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Hooked flash</Flash.flash>
        """)

      assert html =~ ~s(PulsarFlash)
    end

    test "includes ColocatedHook script" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash>Flash with hook</Flash.flash>
        """)

      assert html =~ ~s(<script)
      assert html =~ ~s(name=".PulsarFlash")
      assert html =~ "export default"
      assert html =~ "mounted()"
      assert html =~ "IntersectionObserver"
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

      refute html =~ "h-5 w-5"
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

  describe "flash/1 dark mode support" do
    test "includes dark mode classes for all variants" do
      assigns = %{}

      # Solid variant
      html_solid =
        rendered_to_string(~H"""
        <Flash.flash variant="solid" color="primary">Solid flash</Flash.flash>
        """)

      assert html_solid =~ "dark:bg-dark-primary"
      assert html_solid =~ "dark:text-dark-primary-foreground"

      # Outline variant
      html_outline =
        rendered_to_string(~H"""
        <Flash.flash variant="outline" color="success">Outline flash</Flash.flash>
        """)

      assert html_outline =~ "dark:border-dark-success"
      assert html_outline =~ "dark:text-dark-success"

      # Ghost variant
      html_ghost =
        rendered_to_string(~H"""
        <Flash.flash variant="ghost" color="warning">Ghost flash</Flash.flash>
        """)

      assert html_ghost =~ "dark:text-dark-warning"
      assert html_ghost =~ "dark:bg-dark-warning/10"
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
      assert html =~ "shadow-md"
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

      # Extract IDs from HTML
      [id1] = Regex.run(~r/id="([^"]+)"/, html1, capture: :all_but_first)
      [id2] = Regex.run(~r/id="([^"]+)"/, html2, capture: :all_but_first)

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
        assigns = %{}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="solid" color={color}>Solid {color}</Flash.flash>
          """)

        assert html =~ "bg-#{color}"
        assert html =~ "text-#{color}-foreground"
        assert html =~ "dark:bg-dark-#{color}"
        assert html =~ "dark:text-dark-#{color}-foreground"
      end
    end

    test "renders all outline variant colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="outline" color={color}>Outline {color}</Flash.flash>
          """)

        assert html =~ "border-#{color}"
        assert html =~ "text-#{color}"
        assert html =~ "dark:border-dark-#{color}"
        assert html =~ "dark:text-dark-#{color}"
      end
    end

    test "renders all ghost variant colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{}

        html =
          rendered_to_string(~H"""
          <Flash.flash variant="ghost" color={color}>Ghost {color}</Flash.flash>
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
end
