defmodule Pulsar.Components.IconTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Icon

  describe "icon/1 basic functionality" do
    test "renders basic heroicon with defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" />])

      assert html =~ ~s(hero-check w-5 h-5 text-current)
    end

    test "renders solid icon by full name" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check-solid" />])

      assert html =~ ~s(hero-check-solid w-5 h-5 text-current)
    end

    test "renders different sizes" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="xs" />])
      assert html =~ ~s(w-3 h-3)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="xl" />])
      assert html =~ ~s(w-8 h-8)
    end

    test "renders different colors" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="primary" />])
      assert html =~ ~s(text-primary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="current" />])
      assert html =~ ~s(text-current)
    end

    test "accepts custom classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" class="custom-class" />])

      assert html =~ ~s(custom-class)
    end
  end

  describe "icon/1 heroicon names" do
    test "renders the full heroicon class verbatim" do
      assigns = %{}

      assert rendered_to_string(~H[<Icon.icon name="hero-star" />]) =~ "hero-star"
      assert rendered_to_string(~H[<Icon.icon name="hero-star-solid" />]) =~ "hero-star-solid"
      assert rendered_to_string(~H[<Icon.icon name="hero-star-mini" />]) =~ "hero-star-mini"
      assert rendered_to_string(~H[<Icon.icon name="hero-star-micro" />]) =~ "hero-star-micro"
    end

    test "does not append a variant suffix to the name" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-star" />])
      assert html =~ ~s(hero-star)
      refute html =~ ~s(hero-star-solid)
    end

    test "passes through non-hero icon names unchanged" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="lucide-check" />])
      assert html =~ ~s(lucide-check)
      refute html =~ ~s(lucide-check-solid)
    end
  end

  describe "icon/1 size classes" do
    test "renders all size variants correctly" do
      assigns = %{}

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="xs" />])
      assert html =~ ~s(w-3 h-3)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="sm" />])
      assert html =~ ~s(w-4 h-4)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="md" />])
      assert html =~ ~s(w-5 h-5)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="lg" />])
      assert html =~ ~s(w-6 h-6)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="xl" />])
      assert html =~ ~s(w-8 h-8)
    end
  end

  describe "icon/1 color classes" do
    test "renders all semantic color variants with dark mode support" do
      assigns = %{}

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="current" />])
      assert html =~ ~s(text-current)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="neutral" />])
      assert html =~ ~s(text-neutral)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="primary" />])
      assert html =~ ~s(text-primary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="secondary" />])
      assert html =~ ~s(text-secondary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="success" />])
      assert html =~ ~s(text-success)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="danger" />])
      assert html =~ ~s(text-danger)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="warning" />])
      assert html =~ ~s(text-warning)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="info" />])
      assert html =~ ~s(text-info)
    end
  end

  describe "icon/1 accessibility" do
    test "renders decorative icon by default with aria-hidden" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" />])

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="img")
      refute html =~ ~s(aria-label)
    end

    test "renders informative icon with aria_label" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-exclamation-triangle" aria_label="Warning" />])

      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Warning")
      refute html =~ ~s(aria-hidden)
    end

    test "supports aria-label in rest attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-info" aria-label="Information" />])

      # Note: aria-label in rest attributes goes through to the element
      # but doesn't trigger our informative icon logic (aria_label attr does that)
      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(aria-label="Information")
      refute html =~ ~s(role="img")
    end

    test "respects user-provided aria-hidden in rest" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" aria-hidden="false" />])

      assert html =~ ~s(aria-hidden="false")
      refute html =~ ~s(role="img")
    end

    test "aria_label attribute controls aria-label in output" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Icon.icon name="hero-check" aria_label="Primary Label" />])

      # aria_label drives semantics and final aria-label value
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Primary Label")
    end
  end

  describe "icon/1 class merging with Twm" do
    test "user classes override component defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="md" class="w-10 h-10 text-red-500" />])

      # Twm should resolve conflicts - user classes win
      assert html =~ ~s(w-10 h-10)
      assert html =~ ~s(text-red-500)
      # Component defaults should be overridden
      refute html =~ ~s(w-5 h-5)
      refute html =~ ~s(text-current)
    end

    test "non-conflicting classes are preserved" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" class="rotate-45 opacity-50" />])

      # Component classes should remain
      assert html =~ ~s(hero-check)
      assert html =~ ~s(w-5 h-5)
      assert html =~ ~s(text-current)
      # User classes should be added
      assert html =~ ~s(rotate-45)
      assert html =~ ~s(opacity-50)
    end
  end

  describe "icon/1 rest attributes" do
    test "passes through additional HTML attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" id="my-icon" data-testid="icon" />])

      assert html =~ ~s(id="my-icon")
      assert html =~ ~s(data-testid="icon")
    end

    test "passes through non-conflicting rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Icon.icon name="hero-check" aria_label="Test" title="Tooltip" data-testid="icon" />])

      # aria_label drives semantics
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Test")
      # Non-conflicting attributes pass through
      assert html =~ ~s(title="Tooltip")
      assert html =~ ~s(data-testid="icon")
    end
  end
end
