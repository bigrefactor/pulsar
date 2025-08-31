defmodule Pulsar.Components.LinkTest do
  use ExUnit.Case, async: true
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias Pulsar.Components.Link

  describe "Link.a/1 basic functionality" do
    test "renders link with default props (solid variant, primary color)" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Test Link</Link.a>")
      
      assert html =~ ~s(href="/test")
      assert html =~ "Test Link"
      assert html =~ "text-primary"
      assert html =~ "no-underline"
      refute html =~ ~s(target="_blank")
    end

    test "renders with custom href" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/profile'>Profile</Link.a>")
      
      assert html =~ ~s(href="/profile")
      assert html =~ "Profile"
    end

    test "accepts inner_block content" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Custom Content</Link.a>")
      
      assert html =~ "Custom Content"
    end
  end

  describe "Link.a/1 variants" do
    test "renders solid variant (default)" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Link</Link.a>")
      
      assert html =~ "no-underline"
      refute html =~ "hover:underline"
      refute html =~ ~r/\s+underline(\s|")/  # Check for standalone "underline" class (not "no-underline")
    end

    test "renders ghost variant with hover border" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' variant='ghost'>Link</Link.a>")
      
      assert html =~ "no-underline"
      assert html =~ "hover:border-b-2"
      assert html =~ "hover:border-current"
    end

    test "renders outline variant with permanent border" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' variant='outline'>Link</Link.a>")
      
      assert html =~ "border-b-2"
      assert html =~ "border-current"  
      assert html =~ "no-underline"  # Still has no-underline, plus border
    end
  end

  describe "Link.a/1 colors" do
    test "renders primary color (default)" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Link</Link.a>")
      
      assert html =~ "text-primary"
      assert html =~ "hover:text-primary/80"
      assert html =~ "dark:text-dark-primary"
    end

    test "renders secondary color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='secondary'>Link</Link.a>")
      
      assert html =~ "text-secondary"
      assert html =~ "hover:text-secondary/80"
      assert html =~ "dark:text-dark-secondary"
    end

    test "renders muted color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='muted'>Link</Link.a>")
      
      assert html =~ "text-muted-foreground"
      assert html =~ "hover:text-muted-foreground/70"
      assert html =~ "dark:text-dark-muted-foreground"
    end

    test "renders danger color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='danger'>Link</Link.a>")
      
      assert html =~ "text-danger"
      assert html =~ "hover:text-danger/80"
      assert html =~ "dark:text-dark-danger"
    end

    test "renders success color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='success'>Link</Link.a>")
      
      assert html =~ "text-success"
      assert html =~ "hover:text-success/80"
    end

    test "renders warning color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='warning'>Link</Link.a>")
      
      assert html =~ "text-warning"
      assert html =~ "hover:text-warning/80"
    end

    test "renders info color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='info'>Link</Link.a>")
      
      assert html =~ "text-info"
      assert html =~ "hover:text-info/80"
    end

    test "renders inherit color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' color='inherit'>Link</Link.a>")
      
      assert html =~ "text-inherit"
      refute html =~ "hover:"
    end
  end

  describe "Link.a/1 sizes" do
    test "renders inherit size (default)" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Link</Link.a>")
      
      refute html =~ "text-xs"
      refute html =~ "text-sm"
      refute html =~ "text-base"
      refute html =~ "text-lg"
      refute html =~ "text-xl"
    end

    test "renders explicit sizes" do
      sizes = [
        {"xs", "text-xs"},
        {"sm", "text-sm"},
        {"md", "text-base"},
        {"lg", "text-lg"},
        {"xl", "text-xl"}
      ]

      for {size, expected_class} <- sizes do
        assigns = %{size: size}
        html = rendered_to_string(~H"<Link.a href='/test' size={@size}>Link</Link.a>")
        assert html =~ expected_class, "Expected #{expected_class} for size #{size}"
      end
    end
  end

  describe "Link.a/1 external links (automatic detection)" do
    test "treats internal paths as internal" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/internal'>Internal</Link.a>")
      
      assert html =~ ~s(href="/internal")
      # Should not have data-external attribute for internal links
      refute html =~ ~s(data-external="true")
    end
  end

  describe "Link.a/1 Phoenix navigation" do
    test "renders with navigate attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a navigate='/dashboard'>Dashboard</Link.a>")
      
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(data-phx-link-state="push")
      assert html =~ ~s(href="/dashboard")
    end

    test "renders with patch attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a patch='/current'>Current</Link.a>")
      
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(data-phx-link-state="push")
      assert html =~ ~s(href="/current")
    end

    test "renders with replace flag" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a navigate='/dashboard' replace>Dashboard</Link.a>")
      
      assert html =~ ~s(data-phx-link-state="replace")
    end

    test "renders with method attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/delete' method='delete'>Delete</Link.a>")
      
      assert html =~ ~s(data-method="delete")
    end
  end

  describe "Link.a/1 icons" do
    test "renders start_icon slot" do
      assigns = %{}
      html = rendered_to_string(~H"""
      <Link.a href='/test'>
        <:start_icon>📝</:start_icon>
        With Icon
      </Link.a>
      """)
      
      assert html =~ "📝"
      assert html =~ "With Icon"
      assert html =~ "inline-flex items-center"
    end

    test "renders end_icon slot" do
      assigns = %{}
      html = rendered_to_string(~H"""
      <Link.a href='/test'>
        With Icon
        <:end_icon>📝</:end_icon>
      </Link.a>
      """)
      
      assert html =~ "📝"
      assert html =~ "With Icon"
      assert html =~ "inline-flex items-center"
    end

    test "renders both start and end icons" do
      assigns = %{}
      html = rendered_to_string(~H"""
      <Link.a href='/test'>
        <:start_icon>📝</:start_icon>
        Both Icons
        <:end_icon>→</:end_icon>
      </Link.a>
      """)
      
      assert html =~ "📝"
      assert html =~ "→"
      assert html =~ "Both Icons"
    end
  end

  describe "Link.a/1 accessibility" do
    test "includes focus ring classes" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Link</Link.a>")
      
      assert html =~ "focus-visible:outline-none"
      assert html =~ "focus-visible:ring-2"
      assert html =~ "dark:focus-visible:ring-dark-ring/50"
    end

    test "supports aria-label attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' aria_label='Go to profile'>Profile</Link.a>")
      
      assert html =~ ~s(aria-label="Go to profile")
    end

    test "supports aria-describedby attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' aria_describedby='help-text'>Link</Link.a>")
      
      assert html =~ ~s(aria-describedby="help-text")
    end

    test "supports aria-current attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' aria_current='page'>Current</Link.a>")
      
      assert html =~ ~s(aria-current="page")
    end
  end

  describe "Link.a/1 custom styling" do
    test "merges custom classes correctly" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' class='custom-class font-bold'>Link</Link.a>")
      
      assert html =~ "custom-class"
      assert html =~ "font-bold"
      assert html =~ "text-primary"  # Default color should still be present
    end

    test "supports id attribute" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' id='my-link'>Link</Link.a>")
      
      assert html =~ ~s(id="my-link")
    end

    test "passes through rest attributes" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' data-test='link-test'>Link</Link.a>")
      
      assert html =~ ~s(data-test="link-test")
    end
  end

  describe "Link.a/1 variant and color combinations" do
    test "solid primary (default) - no underline, primary color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test'>Link</Link.a>")
      
      assert html =~ "text-primary"
      assert html =~ "no-underline"
    end

    test "ghost muted - hover border, muted color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' variant='ghost' color='muted'>Link</Link.a>")
      
      assert html =~ "text-muted-foreground"
      assert html =~ "hover:border-b-2"
    end

    test "outline danger - always bordered, danger color" do
      assigns = %{}
      html = rendered_to_string(~H"<Link.a href='/test' variant='outline' color='danger'>Link</Link.a>")
      
      assert html =~ "text-danger"
      assert html =~ "border-b-2"
    end
  end
end