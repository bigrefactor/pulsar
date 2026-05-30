defmodule Pulsar.Components.HeaderTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Header

  describe "header/1 basic functionality" do
    test "renders header with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>Simple Title</Header.header>
        """)

      assert html =~ ~s(<header)
      assert html =~ "Simple Title"
      assert html =~ ~s(<h1)
      # Default variant (ghost) with default color (neutral) - should have minimal styling
      assert html =~ ~s(data-component="header")
      # Default size (md)
      assert html =~ "text-2xl"
      assert html =~ "font-semibold"
    end

    test "renders with subtitle slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Main Title
          <:subtitle>This is a subtitle</:subtitle>
        </Header.header>
        """)

      assert html =~ "Main Title"
      assert html =~ "This is a subtitle"
      # Default subtitle size for md header
      assert html =~ "text-sm"
      assert html =~ "text-muted-foreground"
    end

    test "renders with actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Products
          <:actions>
            <button>Add Product</button>
            <button>Export</button>
          </:actions>
        </Header.header>
        """)

      assert html =~ "Products"
      assert html =~ "Add Product"
      assert html =~ "Export"
      assert html =~ "actions"
    end
  end

  describe "header/1 variants" do
    test "renders ghost variant (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header variant="ghost">Ghost Header</Header.header>
        """)

      assert html =~ "Ghost Header"
      # Ghost variant should have minimal styling
      refute html =~ "border-b"
      refute html =~ "bg-"
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header variant="outline">Outline Header</Header.header>
        """)

      assert html =~ "Outline Header"
      assert html =~ "border-b"
      assert html =~ "border-border-strong"
      assert html =~ "pb-4"
    end

    test "renders solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header variant="solid">Solid Header</Header.header>
        """)

      assert html =~ "Solid Header"
      assert html =~ "bg-neutral-100"
      assert html =~ "text-neutral-900"
      assert html =~ "p-6"
      assert html =~ "rounded-box"
    end
  end

  describe "header/1 colors" do
    test "renders with primary color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header color="primary" variant="solid">Primary Header</Header.header>
        """)

      assert html =~ "bg-primary-100"
      assert html =~ "text-primary-900"
    end

    test "renders with success color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header color="success" variant="outline">Success Header</Header.header>
        """)

      assert html =~ "border-border-strong"
      assert html =~ "text-success"
    end

    test "renders with danger color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header color="danger" variant="ghost">Danger Header</Header.header>
        """)

      assert html =~ "text-danger"
    end
  end

  describe "header/1 sizes" do
    test "renders with xs size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header size="xs">Small Header</Header.header>
        """)

      # Title size for xs
      assert html =~ "text-lg"
      assert html =~ "Small Header"
    end

    test "renders with sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header size="sm">Small Header</Header.header>
        """)

      # Title size for sm
      assert html =~ "text-xl"
    end

    test "renders with lg size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header size="lg">Large Header</Header.header>
        """)

      # Title size for lg
      assert html =~ "text-3xl"
    end

    test "renders with xl size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header size="xl">Extra Large Header</Header.header>
        """)

      # Title size for xl
      assert html =~ "text-4xl"
    end

    test "subtitle scales with header size" do
      assigns = %{}

      html_lg =
        rendered_to_string(~H"""
        <Header.header size="lg">
          Large Title
          <:subtitle>Large subtitle</:subtitle>
        </Header.header>
        """)

      html_xs =
        rendered_to_string(~H"""
        <Header.header size="xs">
          Small Title
          <:subtitle>Small subtitle</:subtitle>
        </Header.header>
        """)

      # lg should have base subtitle size
      assert html_lg =~ "text-base"
      # xs should have xs subtitle size
      assert html_xs =~ "text-xs"
    end
  end

  describe "header/1 breadcrumbs" do
    test "renders without breadcrumbs by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>No Breadcrumbs</Header.header>
        """)

      refute html =~ ~s(<nav)
      refute html =~ "hero-chevron-right"
    end

    test "renders breadcrumbs with navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Home</:breadcrumb>
          <:breadcrumb navigate="/products">Products</:breadcrumb>
          <:breadcrumb>Current Page</:breadcrumb>
          Current Page
        </Header.header>
        """)

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ "Home"
      assert html =~ "Products"
      assert html =~ "Current Page"
      assert html =~ "hero-chevron-right"
    end

    test "renders breadcrumb separators between items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Home</:breadcrumb>
          <:breadcrumb navigate="/products">Products</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)

      # Should have 2 separators for 3 breadcrumb items
      separators = Regex.scan(~r/hero-chevron-right/, html)
      assert length(separators) == 2
    end

    test "last breadcrumb is not a link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Home</:breadcrumb>
          <:breadcrumb>Current Page</:breadcrumb>
          Current Page
        </Header.header>
        """)

      # Should have one link (Home) and one span (Current Page)
      assert html =~ ~s(href="/home")
      assert html =~ ~s(aria-current="page")
      assert html =~ "font-medium"
    end

    test "supports different navigation types" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Navigate</:breadcrumb>
          <:breadcrumb patch="/patch">Patch</:breadcrumb>
          <:breadcrumb href="/href">Href</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)

      assert html =~ ~s(href="/home")
      assert html =~ ~s(href="/patch")
      assert html =~ ~s(href="/href")
      assert html =~ "Navigate"
      assert html =~ "Patch"
      assert html =~ "Href"
    end

    test "raises error when breadcrumb has multiple navigation props" do
      assigns = %{}

      assert_raise ArgumentError, ~r/Breadcrumb can only have one navigation prop/, fn ->
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home" href="/conflict">Conflicting Nav</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)
      end
    end

    test "raises error lists all conflicting props" do
      assigns = %{}

      assert_raise ArgumentError, ~r/:navigate, :patch, :href/, fn ->
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home" patch="/patch" href="/href">All Three</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)
      end
    end
  end

  describe "header/1 options" do
    test "renders with sticky positioning" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header sticky={true}>Sticky Header</Header.header>
        """)

      assert html =~ "sticky"
      assert html =~ "top-0"
      assert html =~ "z-docked"
      assert html =~ "bg-background"
    end

    test "applies size-appropriate scroll-margin on siblings so focus is not obscured" do
      for {size, n} <- [
            {"xs", 12},
            {"sm", 14},
            {"md", 16},
            {"lg", 20},
            {"xl", 24}
          ] do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Header.header sticky={true} size={@size}>Sticky Header</Header.header>
          """)

        assert html =~ "[&amp;~*]:scroll-mt-#{n}",
               "expected size=#{size} sticky header to include [&~*]:scroll-mt-#{n}"

        assert html =~ "[&amp;~*_*]:scroll-mt-#{n}",
               "expected size=#{size} sticky header to include [&~*_*]:scroll-mt-#{n}"
      end
    end

    test "no scroll-margin when sticky is disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header sticky={false} size="md">Non-sticky</Header.header>
        """)

      refute html =~ "scroll-mt"
    end

    test "renders with divider" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header divider={true}>Header with Divider</Header.header>
        """)

      assert html =~ ~s(<hr)
      assert html =~ "border-border-strong"
    end

    test "accepts custom classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header class="custom-header">Custom Classes</Header.header>
        """)

      assert html =~ "custom-header"
    end

    test "accepts global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header id="main-header" data-testid="header">Global Attrs</Header.header>
        """)

      assert html =~ ~s(id="main-header")
      assert html =~ ~s(data-testid="header")
    end

    test "renders with custom heading level" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header as="h2">Section Header</Header.header>
        """)

      assert html =~ ~s(<h2)
      assert html =~ "Section Header"
      # Should still have proper size classes
      assert html =~ "text-2xl"
      assert html =~ "font-semibold"
    end

    test "sticky with solid variant preserves background" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header sticky={true} variant="solid" color="primary">Sticky Solid</Header.header>
        """)

      # Should have sticky positioning
      assert html =~ "sticky"
      assert html =~ "top-0"
      assert html =~ "z-docked"
      # Variant background should win over sticky background due to Twm
      assert html =~ "bg-primary-100"
      refute html =~ "bg-background"
    end
  end

  describe "header/1 responsive layout" do
    test "has responsive flex classes for mobile/desktop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Responsive Header
          <:actions>
            <button>Action</button>
          </:actions>
        </Header.header>
        """)

      # Should have mobile-first flex-col and desktop flex-row
      assert html =~ "flex-col"
      assert html =~ "sm:flex-row"
      assert html =~ "sm:items-start"
      assert html =~ "sm:justify-between"
    end

    test "title section has proper flex properties" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>Title</Header.header>
        """)

      assert html =~ ~s(data-role="title")
      assert html =~ "flex-1"
      # Prevents text overflow
      assert html =~ "min-w-0"
    end

    test "actions section has flex-shrink-0" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Title
          <:actions>
            <button>Action</button>
          </:actions>
        </Header.header>
        """)

      assert html =~ "actions"
      assert html =~ "flex-shrink-0"
    end
  end

  describe "header/1 accessibility" do
    test "uses proper semantic HTML" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>Semantic Header</Header.header>
        """)

      assert html =~ ~s(<header)
      assert html =~ ~s(<h1)
      assert html =~ "Semantic Header"
    end

    test "breadcrumb navigation has proper ARIA" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Home</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)

      assert html =~ ~s(<nav)
      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(<ol)
      assert html =~ ~s(aria-current="page")
    end

    test "icons have proper accessibility attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          <:breadcrumb navigate="/home">Home</:breadcrumb>
          <:breadcrumb>Current</:breadcrumb>
          Current
        </Header.header>
        """)

      # Chevron icons should be decorative
      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "divider behavior" do
    test "divider shows with ghost and solid variants" do
      assigns = %{}

      ghost_html =
        rendered_to_string(~H"""
        <Header.header variant="ghost" divider={true}>
          Title
        </Header.header>
        """)

      solid_html =
        rendered_to_string(~H"""
        <Header.header variant="solid" divider={true}>
          Title
        </Header.header>
        """)

      assert ghost_html =~ "<hr"
      assert solid_html =~ "<hr"
    end

    test "divider does not show with outline variant to avoid double border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header variant="outline" divider={true}>
          Title
        </Header.header>
        """)

      # Outline variant already has border-b, so no hr should render
      refute html =~ "<hr"
      # But should still have the outline border
      assert html =~ "border-b"
    end
  end
end
