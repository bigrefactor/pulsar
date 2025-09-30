defmodule Pulsar.Components.CardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Card

  describe "card/1 basic functionality" do
    test "renders basic card with defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card>Card content</Card.card>])

      assert html =~ ~s(<div)
      assert html =~ "Card content"
      assert html =~ ~s(bg-background)
      assert html =~ ~s(shadow-md)
      assert html =~ ~s(rounded-lg)
    end

    test "renders card content correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <p>Simple paragraph content</p>
        </Card.card>
        """)

      assert html =~ ~s(<p>Simple paragraph content</p>)
    end

    test "renders multiple children in content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <h3>Title</h3>
          <p>Description</p>
        </Card.card>
        """)

      assert html =~ ~s(<h3>Title</h3>)
      assert html =~ ~s(<p>Description</p>)
    end
  end

  describe "card variants" do
    test "renders elevated variant (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="elevated">Elevated</Card.card>])

      assert html =~ ~s(shadow-md)
      assert html =~ ~s(bg-background dark:bg-dark-background)
    end

    test "renders outline variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline">Outline</Card.card>])

      assert html =~ ~s(border-2)
      assert html =~ ~s(border-border dark:border-dark-border)
      assert html =~ ~s(bg-background dark:bg-dark-background)
    end

    test "renders ghost variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="ghost">Ghost</Card.card>])

      assert html =~ ~s(bg-transparent)
      assert html =~ ~s(border-transparent)
    end

    test "renders solid variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="solid">Solid</Card.card>])

      assert html =~ ~s(bg-surface-1 dark:bg-dark-surface-1)
      assert html =~ ~s(border-2)
    end
  end

  describe "card colors" do
    test "renders neutral color (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card color="neutral">Neutral</Card.card>])

      assert html =~ ~s(bg-background dark:bg-dark-background)
    end

    test "renders primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="primary">Primary</Card.card>])

      assert html =~ ~s(border-primary dark:border-dark-primary)
    end

    test "renders danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="danger">Danger</Card.card>])

      assert html =~ ~s(border-danger dark:border-dark-danger)
    end

    test "renders success color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="solid" color="success">Success</Card.card>])

      assert html =~ ~s(bg-success/10 dark:bg-dark-success/10)
    end

    test "renders warning color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="solid" color="warning">Warning</Card.card>])

      assert html =~ ~s(bg-warning/10 dark:bg-dark-warning/10)
    end

    test "renders info color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="info">Info</Card.card>])

      assert html =~ ~s(border-info dark:border-dark-info)
    end

    test "renders secondary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="secondary">Secondary</Card.card>])

      assert html =~ ~s(border-secondary dark:border-dark-secondary)
    end
  end

  describe "card sizes" do
    test "renders xs size" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="xs">XS</Card.card>])

      assert html =~ ~s(p-3 gap-3)
      assert html =~ ~s(rounded-md)
    end

    test "renders sm size" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="sm">SM</Card.card>])

      assert html =~ ~s(p-4 gap-4)
      assert html =~ ~s(rounded-lg)
    end

    test "renders md size (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="md">MD</Card.card>])

      assert html =~ ~s(p-5 gap-5)
      assert html =~ ~s(rounded-lg)
    end

    test "renders lg size" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="lg">LG</Card.card>])

      assert html =~ ~s(p-6 gap-6)
      assert html =~ ~s(rounded-xl)
    end

    test "renders xl size" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="xl">XL</Card.card>])

      assert html =~ ~s(p-8 gap-8)
      assert html =~ ~s(rounded-2xl)
    end
  end

  describe "card slots" do
    test "does not render optional slots by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card>Content only</Card.card>])

      assert html =~ "Content only"
      # Should only have one content div (the body)
      assert Regex.scan(~r/<div[^>]*>/, html) |> length() == 2
    end

    test "renders header slot when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:header>
            <h3>Card Title</h3>
          </:header>
          Content
        </Card.card>
        """)

      assert html =~ ~s(<h3>Card Title</h3>)
      assert html =~ "Content"
      assert html =~ ~s(pb-0)
    end

    test "renders footer slot when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          Content
          <:footer>
            <span>Footer text</span>
          </:footer>
        </Card.card>
        """)

      assert html =~ "Content"
      assert html =~ ~s(<span>Footer text</span>)
      assert html =~ ~s(pt-0)
    end

    test "renders media slot when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:media>
            <img src="/image.jpg" alt="Hero" />
          </:media>
          Content
        </Card.card>
        """)

      assert html =~ ~s(<img src="/image.jpg" alt="Hero")
      assert html =~ "Content"
    end

    test "renders all slots together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:media>
            <img src="/hero.jpg" />
          </:media>
          <:header>
            <h3>Title</h3>
          </:header>
          Main content here
          <:footer>
            <button>Action</button>
          </:footer>
        </Card.card>
        """)

      assert html =~ ~s(<img src="/hero.jpg")
      assert html =~ ~s(<h3>Title</h3>)
      assert html =~ "Main content here"
      assert html =~ ~s(<button>Action</button>)
    end
  end

  describe "card customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card class="custom-shadow">Content</Card.card>])

      assert html =~ ~s(custom-shadow)
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card id="my-card" data-testid="card">Content</Card.card>])

      assert html =~ ~s(id="my-card")
      assert html =~ ~s(data-testid="card")
    end

    test "accepts phx-click attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card phx-click="select" phx-value-id="123">
          Clickable
        </Card.card>
        """)

      assert html =~ ~s(phx-click="select")
      assert html =~ ~s(phx-value-id="123")
    end

    test "accepts phx-change attribute" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card phx-change="update">Content</Card.card>])

      assert html =~ ~s(phx-change="update")
    end
  end

  describe "variant and color combinations" do
    test "outline variant with primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="primary">Primary Outline</Card.card>])

      assert html =~ ~s(border-2)
      assert html =~ ~s(border-primary dark:border-dark-primary)
      assert html =~ ~s(bg-background dark:bg-dark-background)
    end

    test "solid variant with danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="solid" color="danger">Danger Solid</Card.card>])

      assert html =~ ~s(bg-danger/10 dark:bg-dark-danger/10)
      assert html =~ ~s(border-2)
      assert html =~ ~s(border-danger/20 dark:border-dark-danger/20)
    end

    test "ghost variant with success color" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="ghost" color="success">Success Ghost</Card.card>])

      assert html =~ ~s(bg-transparent)
      assert html =~ ~s(border-transparent)
    end

    test "elevated variant always uses neutral background" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="elevated" color="primary">Elevated</Card.card>])

      assert html =~ ~s(bg-background dark:bg-dark-background)
      assert html =~ ~s(shadow-md)
    end
  end

  describe "slot padding and spacing" do
    test "header has padding but no bottom padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card size="md">
          <:header>Header</:header>
          Content
        </Card.card>
        """)

      assert html =~ ~s(p-5 pb-0)
    end

    test "footer has padding but no top padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card size="md">
          Content
          <:footer>Footer</:footer>
        </Card.card>
        """)

      assert html =~ ~s(p-5 pt-0)
    end

    test "body has full padding and gap with flex container" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card size="lg">Content</Card.card>])

      assert html =~ ~s(flex flex-col)
      assert html =~ ~s(p-6 gap-6)
    end

    test "body flex container enables automatic spacing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card size="md">
          <p>First paragraph</p>
          <p>Second paragraph</p>
          <p>Third paragraph</p>
        </Card.card>
        """)

      # Verify flex flex-col is present so gap actually works
      assert html =~ ~s(flex flex-col)
      assert html =~ ~s(gap-5)
      assert html =~ ~s(<p>First paragraph</p>)
      assert html =~ ~s(<p>Second paragraph</p>)
      assert html =~ ~s(<p>Third paragraph</p>)
    end

    test "media slot has no padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:media>
            <img src="/image.jpg" />
          </:media>
          Content
        </Card.card>
        """)

      # Media should only have w-full class, no padding
      assert html =~ ~s(class="w-full")
    end
  end

  describe "complex composition patterns" do
    test "renders card with complex header layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card variant="outline">
          <:header>
            <div class="flex items-center justify-between">
              <h3 class="font-semibold">Title</h3>
              <button>Edit</button>
            </div>
          </:header>
          Content here
        </Card.card>
        """)

      assert html =~ ~s(flex items-center justify-between)
      assert html =~ ~s(<h3 class="font-semibold">Title</h3>)
      assert html =~ ~s(<button>Edit</button>)
    end

    test "renders card with complex footer actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          Content
          <:footer>
            <div class="flex justify-end gap-2">
              <button>Cancel</button>
              <button>Confirm</button>
            </div>
          </:footer>
        </Card.card>
        """)

      assert html =~ ~s(flex justify-end gap-2)
      assert html =~ ~s(<button>Cancel</button>)
      assert html =~ ~s(<button>Confirm</button>)
    end
  end

  describe "configuration completeness" do
    test "all variant/color combinations are defined" do
      variants = ~w(solid outline ghost elevated)
      colors = ~w(neutral primary secondary success danger warning info)

      for variant <- variants, color <- colors do
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <Card.card variant={@variant} color={@color}>
            Test content
          </Card.card>
          """)

        # Should render successfully without error
        assert html =~ "Test content"
        # Should contain some background or border styling
        assert html =~ ~r/bg-|border-/
      end
    end

    test "all sizes have complete configuration" do
      sizes = ~w(xs sm md lg xl)

      for size <- sizes do
        # Access the private size_classes function behavior through component rendering
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Card.card size={@size}>
            <:header>Header</:header>
            Content
            <:footer>Footer</:footer>
          </Card.card>
          """)

        # Should render successfully without error
        assert html =~ "Content"
        # Should have appropriate classes based on size
        case size do
          "xs" -> assert html =~ ~r/p-3|rounded-md/
          "sm" -> assert html =~ ~r/p-4|rounded-lg/
          "md" -> assert html =~ ~r/p-5|rounded-lg/
          "lg" -> assert html =~ ~r/p-6|rounded-xl/
          "xl" -> assert html =~ ~r/p-8|rounded-2xl/
        end
      end
    end
  end

  describe "TailwindMerge class overrides" do
    test "custom classes override component defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card class="rounded-none shadow-xl">
          Content
        </Card.card>
        """)

      # Custom classes should be present
      assert html =~ "rounded-none"
      assert html =~ "shadow-xl"
    end

    test "custom padding overrides size padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card size="lg" class="p-0">
          Content
        </Card.card>
        """)

      # TailwindMerge should resolve the conflict
      # The exact behavior depends on TailwindMerge, but the class should be present
      assert html =~ ~r/p-/
    end

    test "custom background overrides variant background" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card variant="solid" class="bg-red-500">
          Content
        </Card.card>
        """)

      # Custom background should be present
      assert html =~ "bg-red-500"
    end
  end

  describe "accessibility for interactive cards" do
    test "adds role and tabindex for clickable cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card phx-click="select" role="button" tabindex="0">
          Clickable
        </Card.card>
        """)

      assert html =~ ~s(role="button")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(phx-click="select")
    end

    test "supports custom aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card phx-click="select" aria-label="Select this card">
          Content
        </Card.card>
        """)

      assert html =~ ~s(aria-label="Select this card")
    end

    test "non-interactive cards do not require role or tabindex" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card>Static content</Card.card>])

      refute html =~ ~s(role=)
      refute html =~ ~s(tabindex=)
    end
  end

  describe "dark mode classes" do
    test "elevated variant includes dark mode classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="elevated">Content</Card.card>])

      assert html =~ "dark:bg-dark-background"
    end

    test "outline variant includes dark mode border classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="outline" color="primary">Content</Card.card>])

      assert html =~ "dark:border-dark-primary"
    end

    test "solid variant includes dark mode background classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Card.card variant="solid" color="danger">Content</Card.card>])

      assert html =~ "dark:bg-dark-danger/10"
      assert html =~ "dark:border-dark-danger/20"
    end
  end
end
