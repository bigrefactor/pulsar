defmodule Pulsar.Components.ButtonTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias Pulsar.Components.Button

  describe "button/1" do
    test "renders button with default props" do
      assigns = %{}
      html = rendered_to_string(~H"""
        <Button.button>Click me</Button.button>
      """)
      
      assert html =~ ~s(<button)
      assert html =~ "Click me"
      assert html =~ "bg-primary-500"  # Default variant
      assert html =~ "h-10"            # Default size
    end

    test "renders with custom variant" do
      assigns = %{}
      html = rendered_to_string(~H"""
        <Button.button variant="success">Success</Button.button>
      """)
      
      assert html =~ "bg-success-500"
      assert html =~ "Success"
    end

    test "renders with custom size" do
      html = render_component(&Button.button/1, %{size: "lg"}, do: "Large")
      
      assert html =~ "h-12"  # Large size class
      assert html =~ "Large"
    end

    test "passes through Stellar button props" do
      html = render_component(&Button.button/1, %{
        loading: true,
        disabled: true,
        type: "submit"
      }, do: "Submit")
      
      assert html =~ ~s(type="submit")
      assert html =~ ~s(disabled)
      assert html =~ "Submit"
    end

    test "merges custom classes with component classes" do
      html = render_component(&Button.button/1, %{
        variant: "primary",
        class: "w-full custom-class"
      }, do: "Full width")
      
      # Should contain both component classes and custom classes
      assert html =~ "bg-primary-500"    # Component class
      assert html =~ "w-full"            # Custom class
      assert html =~ "custom-class"      # Custom class
    end

    test "renders all available variants" do
      variants = ~w(primary secondary success error warning ghost outline link)
      
      for variant <- variants do
        html = render_component(&Button.button/1, %{variant: variant}, do: "Test")
        
        # Each variant should have its specific styling
        case variant do
          "primary" -> assert html =~ "bg-primary-500"
          "secondary" -> assert html =~ "bg-secondary-500"
          "success" -> assert html =~ "bg-success-500"
          "error" -> assert html =~ "bg-error-500"
          "warning" -> assert html =~ "bg-warning-500"
          "ghost" -> assert html =~ "hover:bg-gray-100"
          "outline" -> assert html =~ "border-2"
          "link" -> assert html =~ "underline-offset-4"
        end
      end
    end

    test "renders all available sizes" do
      sizes = ~w(sm md lg icon)
      
      for size <- sizes do
        html = render_component(&Button.button/1, %{size: size}, do: "Test")
        
        # Each size should have its specific height
        case size do
          "sm" -> assert html =~ "h-8"
          "md" -> assert html =~ "h-10"
          "lg" -> assert html =~ "h-12"
          "icon" -> assert html =~ "w-10"
        end
      end
    end

    test "renders with navigation props" do
      html = render_component(&Button.button/1, %{
        navigate: "/dashboard"
      }, do: "Dashboard")
      
      # Should render as an anchor tag when navigation is provided
      assert html =~ ~s(<a)
      assert html =~ "Dashboard"
    end

    test "includes accessibility attributes" do
      html = render_component(&Button.button/1, %{
        controls: "menu-1",
        expanded: true,
        pressed: true
      }, do: "Menu")
      
      assert html =~ ~s(aria-controls="menu-1")
      assert html =~ ~s(aria-expanded="true") 
      assert html =~ ~s(aria-pressed="true")
    end

    test "passes through global attributes" do
      html = render_component(&Button.button/1, %{
        "phx-click": "save",
        "data-testid": "save-button"
      }, do: "Save")
      
      assert html =~ ~s(phx-click="save")
      assert html =~ ~s(data-testid="save-button")
    end
  end

  describe "accessibility" do
    test "includes proper ARIA attributes for interactive elements" do
      html = render_component(&Button.button/1, %{
        loading: true,
        disabled: false
      }, do: "Loading")
      
      # Should include data attributes for styling
      assert html =~ ~s(data-loading="true")
      assert html =~ ~s(data-disabled="false")
    end

    test "includes focus ring classes" do
      html = render_component(&Button.button/1, %{}, do: "Focus test")
      
      assert html =~ "focus-visible:outline-none"
      assert html =~ "focus-visible:ring-2"
      assert html =~ "focus-visible:ring-ring"
    end
  end

  describe "styling" do
    test "includes base button classes" do
      html = render_component(&Button.button/1, %{}, do: "Base")
      
      # Should include common base classes
      assert html =~ "inline-flex"
      assert html =~ "items-center"
      assert html =~ "justify-center"
      assert html =~ "font-medium"
      assert html =~ "transition-colors"
    end

    test "includes proper rounded classes for sizes" do
      html_sm = render_component(&Button.button/1, %{size: "sm"}, do: "Small")
      html_md = render_component(&Button.button/1, %{size: "md"}, do: "Medium")
      html_lg = render_component(&Button.button/1, %{size: "lg"}, do: "Large")
      
      assert html_sm =~ "rounded-md"
      assert html_md =~ "rounded-lg"
      assert html_lg =~ "rounded-lg"
    end
  end
end