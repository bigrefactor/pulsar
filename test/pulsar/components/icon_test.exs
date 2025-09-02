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

    test "renders solid variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" variant="solid" />])

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
      assert html =~ ~s(text-primary dark:text-dark-primary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="current" />])
      assert html =~ ~s(text-current)
    end

    test "accepts custom classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" class="custom-class" />])

      assert html =~ ~s(custom-class)
    end
  end

  describe "icon/1 heroicon variants" do
    test "renders outline variant (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-star" />])
      assert html =~ ~s(hero-star)
      refute html =~ ~s(hero-star-solid)
    end

    test "renders solid variant with suffix" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-star" variant="solid" />])
      assert html =~ ~s(hero-star-solid)
    end

    test "renders mini variant with suffix" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-star" variant="mini" />])
      assert html =~ ~s(hero-star-mini)
    end

    test "renders micro variant with suffix" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-star" variant="micro" />])
      assert html =~ ~s(hero-star-micro)
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
      assert html =~ ~s(text-neutral dark:text-dark-neutral)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="primary" />])
      assert html =~ ~s(text-primary dark:text-dark-primary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="secondary" />])
      assert html =~ ~s(text-secondary dark:text-dark-secondary)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="success" />])
      assert html =~ ~s(text-success dark:text-dark-success)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="danger" />])
      assert html =~ ~s(text-danger dark:text-dark-danger)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="warning" />])
      assert html =~ ~s(text-warning dark:text-dark-warning)

      html = rendered_to_string(~H[<Icon.icon name="hero-check" color="info" />])
      assert html =~ ~s(text-info dark:text-dark-info)
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

    test "prioritizes aria_label over aria-label in rest" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Icon.icon name="hero-check" aria_label="Primary Label" aria-label="Secondary Label" />])

      # Component uses aria_label attr to compute accessibility
      assert html =~ ~s(aria-label="Primary Label")
      assert html =~ ~s(role="img")
      # Rest attributes pass through, so both labels will be present
      assert html =~ ~s(aria-label="Secondary Label")
    end
  end

  describe "icon/1 class merging with TailwindMerge" do
    test "user classes override component defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Icon.icon name="hero-check" size="md" class="w-10 h-10 text-red-500" />])

      # TailwindMerge should resolve conflicts - user classes win
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

    test "passes through rest attributes without filtering" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H[<Icon.icon name="hero-check" aria_label="Test" aria-label="Filtered" aria-hidden="false" title="Tooltip" />]
        )

      # Component uses aria_label for accessibility computation
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Test")
      # Rest attributes pass through unfiltered
      assert html =~ ~s(aria-label="Filtered")
      assert html =~ ~s(aria-hidden="false")
      assert html =~ ~s(title="Tooltip")
    end
  end
end
