defmodule Pulsar.Components.BadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Badge

  describe "badge/1 basic functionality" do
    test "renders basic badge with defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge>New</Badge.badge>])

      assert html =~ ~s(<span)
      assert html =~ "New"
      assert html =~ ~s(bg-neutral)
      assert html =~ ~s(text-sm px-2.5 py-0.5)
    end

    test "renders badge content correctly" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge>Phoenix Framework</Badge.badge>])

      assert html =~ "Phoenix Framework"
    end
  end

  describe "badge variants" do
    test "renders solid variant (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge variant="solid">Solid</Badge.badge>])

      assert html =~ ~s(rounded-field)
      assert html =~ ~s(bg-neutral)
    end

    test "renders outline variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge variant="outline">Outline</Badge.badge>])

      assert html =~ ~s(border)
      assert html =~ ~s(border-border)
      assert html =~ ~s(bg-background)
    end

    test "renders ghost variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge variant="ghost">Ghost</Badge.badge>])

      assert html =~ ~s(rounded-field)
      assert html =~ ~s(hover:bg-neutral/10)
    end
  end

  describe "badge colors" do
    test "renders primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge color="primary">Primary</Badge.badge>])

      assert html =~ ~s(bg-primary text-primary-foreground)
    end

    test "renders danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge color="danger">Error</Badge.badge>])

      assert html =~ ~s(bg-danger text-danger-foreground)
    end

    test "renders success color" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge color="success">Success</Badge.badge>])

      assert html =~ ~s(bg-success text-success-foreground)
    end
  end

  describe "badge sizes" do
    test "renders xs size" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge size="xs">XS</Badge.badge>])

      assert html =~ ~s(text-xs px-2 py-0.5)
    end

    test "renders sm size" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge size="sm">SM</Badge.badge>])

      assert html =~ ~s(text-sm px-2 py-0.5)
    end

    test "renders md size (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge size="md">MD</Badge.badge>])

      assert html =~ ~s(text-sm px-2.5 py-0.5)
    end

    test "renders lg size" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge size="lg">LG</Badge.badge>])

      assert html =~ ~s(text-base px-3 py-1)
    end

    test "renders xl size" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge size="xl">XL</Badge.badge>])

      assert html =~ ~s(text-lg px-3.5 py-1)
    end
  end

  describe "badge addons" do
    test "does not render addons by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge>No addons</Badge.badge>])

      assert html =~ "No addons"
      refute html =~ ~s(<button)
    end

    test "renders start addon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>
          <:start_addon>
            <span class="icon">★</span>
          </:start_addon>
          Featured
        </Badge.badge>
        """)

      assert html =~ ~s(<span class="icon">★</span>)
      assert html =~ "Featured"
    end

    test "renders end addon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>
          Content
          <:end_addon>
            <button type="button">Remove</button>
          </:end_addon>
        </Badge.badge>
        """)

      assert html =~ "Content"
      assert html =~ ~s(<button type="button">Remove</button>)
    end

    test "renders both start and end addons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>
          <:start_addon>
            <span>Start</span>
          </:start_addon>
          Middle
          <:end_addon>
            <span>End</span>
          </:end_addon>
        </Badge.badge>
        """)

      assert html =~ ~s(<span>Start</span>)
      assert html =~ "Middle"
      assert html =~ ~s(<span>End</span>)
    end

    test "gives an interactive addon control a ≥24px target (WCAG 2.5.8)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge size="xs">
          Content
          <:end_addon>
            <button type="button">Remove</button>
          </:end_addon>
        </Badge.badge>
        """)

      # The addon wrapper sizes interactive direct children up to 24px.
      # (`&`/`>` are HTML-escaped in the rendered attribute value.)
      assert html =~ "[&amp;&gt;button]:min-h-6"
      assert html =~ "[&amp;&gt;button]:min-w-6"
      assert html =~ "[&amp;&gt;a]:min-h-6"
    end
  end

  describe "badge customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge class="custom-class">Custom</Badge.badge>])

      assert html =~ ~s(custom-class)
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge id="my-badge" data-testid="badge">Global</Badge.badge>])

      assert html =~ ~s(id="my-badge")
      assert html =~ ~s(data-testid="badge")
    end
  end

  describe "variant and color combinations" do
    test "outline variant with primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge variant="outline" color="primary">Outlined</Badge.badge>])

      assert html =~ ~s(border-primary)
      assert html =~ ~s(text-primary)
      assert html =~ ~s(bg-background)
    end

    test "ghost variant with danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge variant="ghost" color="danger">Ghost Danger</Badge.badge>])

      assert html =~ ~s(text-danger)
      assert html =~ ~s(hover:bg-danger/10)
    end
  end
end
