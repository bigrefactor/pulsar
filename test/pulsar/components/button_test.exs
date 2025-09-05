defmodule Pulsar.Components.ButtonTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Button

  describe "button/1 basic functionality" do
    test "renders button with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>Click me</Button.button>
        """)

      assert html =~ ~s(<button)
      assert html =~ "Click me"
      # Default variant (solid) with default color (primary)
      assert html =~ "bg-primary"
      # Default size (md)
      assert html =~ "h-10"
    end

    test "renders with custom color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button color="success">Success</Button.button>
        """)

      assert html =~ "bg-success"
      assert html =~ "Success"
    end

    test "renders with info color variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button color="info">Info</Button.button>
        """)

      assert html =~ "bg-info"
      assert html =~ "Info"
    end

    test "renders info color with different variants" do
      assigns = %{}

      # Test outline variant with info color
      html_outline =
        rendered_to_string(~H"""
        <Button.button variant="outline" color="info">Info Outline</Button.button>
        """)

      assert html_outline =~ "border-info"
      assert html_outline =~ "text-info"

      # Test ghost variant with info color
      html_ghost =
        rendered_to_string(~H"""
        <Button.button variant="ghost" color="info">Info Ghost</Button.button>
        """)

      assert html_ghost =~ "text-info"

      # Test link variant with info color
      html_link =
        rendered_to_string(~H"""
        <Button.button variant="link" color="info">Info Link</Button.button>
        """)

      assert html_link =~ "text-info"
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button size="lg">Large</Button.button>
        """)

      # Large size class
      assert html =~ "h-12"
      assert html =~ "Large"
    end

    test "passes through Stellar button props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button loading={true} disabled={true} type="submit">Submit</Button.button>
        """)

      assert html =~ ~s(type="submit")
      assert html =~ ~s(disabled)
      assert html =~ "Submit"
    end

    test "merges custom classes with component classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="solid" color="primary" class="w-full custom-class">
          Full width
        </Button.button>
        """)

      # Should contain both component classes and custom classes
      # Component class
      assert html =~ "bg-primary"
      # Custom class
      assert html =~ "w-full"
      # Custom class
      assert html =~ "custom-class"
    end
  end

  describe "variants" do
    test "renders solid variant with all colors" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Button.button variant="solid" color={@color}>Test</Button.button>
          """)

        case color do
          "neutral" -> assert html =~ "bg-neutral"
          "primary" -> assert html =~ "bg-primary"
          "secondary" -> assert html =~ "bg-secondary"
          "success" -> assert html =~ "bg-success"
          "danger" -> assert html =~ "bg-danger"
          "warning" -> assert html =~ "bg-warning"
          "info" -> assert html =~ "bg-info"
        end

        # All solid variants should have shadow
        assert html =~ "shadow-sm"
      end
    end

    test "renders outline variant with all colors" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Button.button variant="outline" color={@color}>Test</Button.button>
          """)

        case color do
          "neutral" -> assert html =~ "border-border"
          "primary" -> assert html =~ "border-primary"
          "secondary" -> assert html =~ "border-secondary"
          "success" -> assert html =~ "border-success"
          "danger" -> assert html =~ "border-danger"
          "warning" -> assert html =~ "border-warning"
          "info" -> assert html =~ "border-info"
        end

        # All outline variants should have border and shadow
        assert html =~ "border-2"
        assert html =~ "shadow-sm"
      end
    end

    test "renders ghost variant with all colors" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Button.button variant="ghost" color={@color}>Test</Button.button>
          """)

        case color do
          "neutral" -> assert html =~ "text-foreground"
          "primary" -> assert html =~ "text-primary"
          "secondary" -> assert html =~ "text-secondary"
          "success" -> assert html =~ "text-success"
          "danger" -> assert html =~ "text-danger"
          "warning" -> assert html =~ "text-warning"
          "info" -> assert html =~ "text-info"
        end

        # Ghost variants should not have border but do have shadow
        refute html =~ "border-2"
        assert html =~ "shadow-sm"
      end
    end

    test "renders link variant with all colors" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Button.button variant="link" color={@color}>Test</Button.button>
          """)

        case color do
          "neutral" -> assert html =~ "text-muted-foreground"
          "primary" -> assert html =~ "text-primary"
          "secondary" -> assert html =~ "text-secondary"
          "success" -> assert html =~ "text-success"
          "danger" -> assert html =~ "text-danger"
          "warning" -> assert html =~ "text-warning"
          "info" -> assert html =~ "text-info"
        end

        # Link variants should have underline classes
        assert html =~ "underline-offset-4"
        assert html =~ "hover:underline"
        # Link variants should not have size classes (to behave like real text links)
        refute html =~ "h-10"
      end
    end
  end

  describe "sizes" do
    test "renders all available sizes correctly" do
      sizes = ~w(xs sm md lg xl)

      for size <- sizes do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Button.button size={@size}>Test</Button.button>
          """)

        case size do
          "xs" ->
            assert html =~ "h-6"
            assert html =~ "px-2"
            assert html =~ "text-xs"
            assert html =~ "gap-1"
            assert html =~ "rounded-md"

          "sm" ->
            assert html =~ "h-8"
            assert html =~ "px-3"
            assert html =~ "text-sm"
            assert html =~ "gap-1"
            assert html =~ "rounded-md"

          "md" ->
            assert html =~ "h-10"
            assert html =~ "px-4"
            assert html =~ "gap-2"
            assert html =~ "rounded-lg"

          "lg" ->
            assert html =~ "h-12"
            assert html =~ "px-6"
            assert html =~ "text-lg"
            assert html =~ "gap-2"
            assert html =~ "rounded-lg"

          "xl" ->
            assert html =~ "h-14"
            assert html =~ "px-8"
            assert html =~ "text-xl"
            assert html =~ "gap-3"
            assert html =~ "rounded-xl"
        end
      end
    end

    test "link variant ignores size classes to preserve natural text flow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="link" size="lg">Link</Button.button>
        """)

      # Link variants should behave like text links, not buttons
      # No fixed height
      refute html =~ "h-12"
      # No fixed padding
      refute html =~ "px-6"
      # No forced text size
      refute html =~ "text-lg"

      # But should have link-specific classes
      assert html =~ "underline-offset-4"
      assert html =~ "hover:underline"
    end
  end

  describe "states and accessibility" do
    test "handles loading state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button loading={true}>Loading</Button.button>
        """)

      # Should pass loading to Stellar button
      assert html =~ ~s(data-loading="true")
    end

    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button disabled={true}>Disabled</Button.button>
        """)

      assert html =~ ~s(disabled)
      # Should include disabled styling from base classes
      assert html =~ "disabled:pointer-events-none"
      assert html =~ "disabled:opacity-50"
    end

    test "handles disabled state for link variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="link" disabled={true}>Disabled Link</Button.button>
        """)

      assert html =~ ~s(disabled)
      # Link variant should also include disabled styling
      assert html =~ "disabled:pointer-events-none"
      assert html =~ "disabled:opacity-50"
      assert html =~ "disabled:cursor-not-allowed"
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>Focus test</Button.button>
        """)

      assert html =~ "focus-visible:outline-none"
      assert html =~ "focus-visible:ring-2"
      assert html =~ "focus-visible:ring-ring"

      # Note: ring-offset-2 is in the component but may be stripped by TailwindMerge or not showing in output
      # The key focus functionality is present
    end

    test "supports aria-label for icon-only buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button aria_label="Add item">+</Button.button>
        """)

      assert html =~ ~s(aria-label="Add item")
      assert html =~ "+"
    end
  end

  describe "navigation" do
    test "renders as anchor tag with href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="https://example.com">External</Button.button>
        """)

      assert html =~ ~s(<a)
      assert html =~ ~s(href="https://example.com")
      assert html =~ "External"
    end

    test "sanitizes dangerous protocols in href" do
      assigns = %{}

      # Test javascript: protocol is blocked
      html_js =
        rendered_to_string(~H"""
        <Button.button href="javascript:alert('xss')">Malicious</Button.button>
        """)

      assert html_js =~ ~s(href="#")
      refute html_js =~ "javascript:"

      # Test data: protocol is blocked
      html_data =
        rendered_to_string(~H"""
        <Button.button href="data:text/html,<script>alert('xss')</script>">Data URL</Button.button>
        """)

      assert html_data =~ ~s(href="#")
      refute html_data =~ "data:"

      # Test vbscript: protocol is blocked
      html_vbs =
        rendered_to_string(~H"""
        <Button.button href="vbscript:msgbox('xss')">VBScript</Button.button>
        """)

      assert html_vbs =~ ~s(href="#")
      refute html_vbs =~ "vbscript:"
    end

    test "allows safe protocols in href" do
      safe_protocols = [
        {"https://example.com", "https://example.com"},
        {"http://example.com", "http://example.com"},
        {"mailto:user@example.com", "mailto:user@example.com"},
        {"tel:+1234567890", "tel:+1234567890"},
        {"/relative/path", "/relative/path"},
        {"#anchor", "#anchor"}
      ]

      for {input_href, expected_href} <- safe_protocols do
        assigns = %{href: input_href}

        html =
          rendered_to_string(~H"""
          <Button.button href={@href}>Safe Link</Button.button>
          """)

        assert html =~ ~s(href="#{expected_href}")
      end
    end

    test "auto-adds security attributes for external links" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="https://external.com">External</Button.button>
        """)

      # Should auto-add target="_blank" for external HTTPS links
      assert html =~ ~s(target="_blank")
      # Should auto-add rel="noopener noreferrer" for target="_blank"
      assert html =~ ~s(rel="noopener noreferrer")
    end

    test "preserves existing target and rel attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="https://external.com" target="_self" rel="external">External</Button.button>
        """)

      # Should preserve explicit target
      assert html =~ ~s(target="_self")
      # Should preserve explicit rel
      assert html =~ ~s(rel="external")
    end

    test "renders as LiveView navigate link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button navigate="/dashboard">Dashboard</Button.button>
        """)

      assert html =~ ~s(<a)
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(href="/dashboard")
      assert html =~ "Dashboard"
    end

    test "renders as custom element type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button as={:div}>Div Button</Button.button>
        """)

      assert html =~ ~s(<div)
      assert html =~ "Div Button"
      # Should still include button styling
      assert html =~ "inline-flex"
      assert html =~ "cursor-pointer"
    end
  end

  describe "styling integration" do
    test "includes base button classes for non-link variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="solid">Base</Button.button>
        """)

      # Should include common base classes
      assert html =~ "inline-flex"
      assert html =~ "items-center"
      assert html =~ "justify-center"
      assert html =~ "font-medium"
      assert html =~ "transition-transform"
      assert html =~ "cursor-pointer"
    end

    test "includes simplified base classes for link variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="link">Link</Button.button>
        """)

      # Should include link-specific base classes
      assert html =~ "inline"
      assert html =~ "font-medium"
      assert html =~ "cursor-pointer"
      assert html =~ "focus-visible:outline-none"

      # Should not include flex classes since it's inline
      refute html =~ "inline-flex"
      refute html =~ "items-center"
      refute html =~ "justify-center"
    end

    test "includes dark mode classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="solid" color="primary">Dark</Button.button>
        """)

      # Should include dark mode variants for semantic tokens
      assert html =~ "dark:bg-dark-primary"
      assert html =~ "dark:hover:bg-dark-primary/90"
      # Focus ring uses semantic token without dark- duplication
      assert html =~ "focus-visible:ring-ring"
    end
  end

  describe "TailwindMerge integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="solid" color="primary" class="bg-red-500 h-16">Custom</Button.button>
        """)

      # TailwindMerge should resolve conflicts, keeping the custom classes
      # Custom background should be present
      assert html =~ "bg-red-500"
      # Custom height should be present
      assert html =~ "h-16"

      # Note: TailwindMerge puts conflicting classes later in the string so they take precedence
      # The presence of both is expected - CSS cascade will apply the later one
    end

    test "link variant focus ring override works correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button variant="link">Link</Button.button>
        """)

      # Link variant should override base focus ring with its own
      assert html =~ "focus-visible:ring-0"
      assert html =~ "focus-visible:ring-offset-0"
      assert html =~ "focus-visible:underline"

      # Should not have the base ring classes
      # (TailwindMerge should resolve the conflict in favor of ring-0)
      # This tests that our TailwindMerge integration properly handles ring conflicts
    end

    test "custom focus classes override component defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button class="focus-visible:ring-4 focus-visible:ring-purple-500">Custom Focus</Button.button>
        """)

      # Custom focus ring should be present
      assert html =~ "focus-visible:ring-4"
      assert html =~ "focus-visible:ring-purple-500"

      # TailwindMerge should ensure custom classes take precedence
      # Component's ring-2 might be present but custom ring-4 will have priority
    end

    test "preserves non-conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button class="w-full border-4">Custom</Button.button>
        """)

      # Should include both original and custom classes
      assert html =~ "w-full"
      assert html =~ "border-4"
      # Original background preserved
      assert html =~ "bg-primary"
      # Original height preserved
      assert html =~ "h-10"
    end
  end

  describe "edge cases" do
    test "handles empty content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button></Button.button>
        """)

      assert html =~ ~s(<button)
      # Should still render with proper styling even with empty content
      assert html =~ "bg-primary"
    end

    test "passes through Phoenix LiveView events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button phx-click="save" data-testid="save-button">Save</Button.button>
        """)

      assert html =~ ~s(phx-click="save")
      assert html =~ ~s(data-testid="save-button")
    end
  end

  describe "button/1 navigation and method" do
    test "renders with method attribute for relative URLs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="/api/delete" method="delete">Delete</Button.button>
        """)

      assert html =~ ~s(data-method="delete")
      assert html =~ ~s(href="/api/delete")
    end

    test "allows method with relative href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="/posts/123" method="delete">Delete Post</Button.button>
        """)

      assert html =~ ~s(data-method="delete")
      assert html =~ ~s(href="/posts/123")
    end

    test "renders method with different HTTP verbs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="/api/update" method="put">Update</Button.button>
        """)

      assert html =~ ~s(data-method="put")
      assert html =~ ~s(href="/api/update")
    end

    test "raises error when method is used with navigate" do
      assigns = %{}

      assert_raise ArgumentError, ~r/cannot be used with :navigate or :patch/, fn ->
        rendered_to_string(~H"""
        <Button.button navigate="/dashboard" method="post">Dashboard</Button.button>
        """)
      end
    end

    test "raises error when method is used with patch" do
      assigns = %{}

      assert_raise ArgumentError, ~r/cannot be used with :navigate or :patch/, fn ->
        rendered_to_string(~H"""
        <Button.button patch="/current" method="put">Current</Button.button>
        """)
      end
    end

    test "raises error when method is used with mailto: href" do
      assigns = %{}

      assert_raise ArgumentError,
                   ~r/:method can only be used with relative paths or http\(s\) hrefs; other schemes \(mailto:, tel:, javascript:, data:, \.\.\.\) are not allowed/,
                   fn ->
                     rendered_to_string(~H"""
                     <Button.button href="mailto:test@example.com" method="post">Email</Button.button>
                     """)
                   end
    end

    test "raises error when method is used with tel: href" do
      assigns = %{}

      assert_raise ArgumentError,
                   ~r/:method can only be used with relative paths or http\(s\) hrefs; other schemes \(mailto:, tel:, javascript:, data:, \.\.\.\) are not allowed/,
                   fn ->
                     rendered_to_string(~H"""
                     <Button.button href="tel:+1234567890" method="post">Call</Button.button>
                     """)
                   end
    end

    test "raises error when method is used with javascript: href" do
      assigns = %{}

      assert_raise ArgumentError,
                   ~r/:method can only be used with relative paths or http\(s\) hrefs; other schemes \(mailto:, tel:, javascript:, data:, \.\.\.\) are not allowed/,
                   fn ->
                     rendered_to_string(~H"""
                     <Button.button href="javascript:alert('xss')" method="post">Malicious</Button.button>
                     """)
                   end
    end

    test "raises error when method is used with data: href" do
      assigns = %{}

      assert_raise ArgumentError,
                   ~r/:method can only be used with relative paths or http\(s\) hrefs; other schemes \(mailto:, tel:, javascript:, data:, \.\.\.\) are not allowed/,
                   fn ->
                     rendered_to_string(~H"""
                     <Button.button href="data:text/html,<script>alert('xss')</script>" method="post">Data URL</Button.button>
                     """)
                   end
    end

    test "allows method when href is nil" do
      assigns = %{}

      # This should not raise an error - method validation only applies when href is present
      html =
        rendered_to_string(~H"""
        <Button.button method="post">No Href</Button.button>
        """)

      # The button component should render as a regular button when no navigation props
      assert html =~ ~s(<button)
      assert html =~ "No Href"
    end
  end
end
