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
end
