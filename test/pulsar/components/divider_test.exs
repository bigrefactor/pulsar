defmodule Pulsar.Components.DividerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Divider

  describe "divider/1 basic functionality" do
    test "renders basic horizontal divider with defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider />])

      assert html =~ ~s(<hr)
      assert html =~ ~s(border-t-2)
      assert html =~ ~s(my-6)
      assert html =~ ~s(border-border dark:border-dark-border)
      assert html =~ ~s(border-solid)
      assert html =~ ~s(w-full)
    end

    test "renders hr element for simple divider" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider />])

      assert html =~ ~s(<hr)
    end
  end

  describe "divider variants" do
    test "renders solid variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="solid" />])

      assert html =~ ~s(border-neutral dark:border-dark-neutral)
    end

    test "renders outline variant (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="outline" />])

      assert html =~ ~s(border-border dark:border-dark-border)
    end

    test "renders ghost variant" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="ghost" />])

      assert html =~ ~s(border-border/30 dark:border-dark-border/30)
    end
  end

  describe "divider colors" do
    test "renders neutral color (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider color="neutral" />])

      assert html =~ ~s(border-border dark:border-dark-border)
    end

    test "renders primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider color="primary" variant="solid" />])

      assert html =~ ~s(border-primary dark:border-dark-primary)
    end

    test "renders danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider color="danger" variant="solid" />])

      assert html =~ ~s(border-danger dark:border-dark-danger)
    end

    test "renders success color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider color="success" variant="solid" />])

      assert html =~ ~s(border-success dark:border-dark-success)
    end
  end

  describe "divider sizes" do
    test "renders xs size" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider size="xs" />])

      assert html =~ ~s(border-t)
      assert html =~ ~s(my-2)
    end

    test "renders sm size" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider size="sm" />])

      assert html =~ ~s(border-t)
      assert html =~ ~s(my-4)
    end

    test "renders md size (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider size="md" />])

      assert html =~ ~s(border-t-2)
      assert html =~ ~s(my-6)
    end

    test "renders lg size" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider size="lg" />])

      assert html =~ ~s(border-t-4)
      assert html =~ ~s(my-8)
    end

    test "renders xl size" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider size="xl" />])

      assert html =~ ~s(border-t-8)
      assert html =~ ~s(my-10)
    end
  end

  describe "divider orientations" do
    test "renders horizontal orientation (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider />])

      assert html =~ ~s(border-t)
      assert html =~ ~s(my-6)
      assert html =~ ~s(w-full)
    end

    test "renders vertical orientation" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider orientation="vertical" />])

      assert html =~ ~s(border-l-2)
      assert html =~ ~s(mx-6)
      assert html =~ ~s(h-full)
    end

    test "vertical orientation with different sizes" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider orientation="vertical" size="sm" />])

      assert html =~ ~s(border-l)
      assert html =~ ~s(mx-4)
    end
  end

  describe "divider line styles" do
    test "renders solid style (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider style="solid" />])

      assert html =~ ~s(border-solid)
    end

    test "renders dashed style" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider style="dashed" />])

      assert html =~ ~s(border-dashed)
    end

    test "renders dotted style" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider style="dotted" />])

      assert html =~ ~s(border-dotted)
    end
  end

  describe "labeled dividers" do
    test "renders labeled divider with text" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider>OR</Divider.divider>])

      assert html =~ ~s(<div)
      assert html =~ "OR"
      assert html =~ ~s(role="separator")
      refute html =~ ~s(<hr)
    end

    test "labeled divider has flex container for horizontal" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider>Section</Divider.divider>])

      assert html =~ ~s(flex items-center w-full)
      assert html =~ "Section"
    end

    test "labeled divider has proper structure" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider>Label</Divider.divider>])

      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(flex-1)
      assert html =~ ~s(whitespace-nowrap)
    end

    test "labeled divider with custom content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Divider.divider>
          <span class="font-bold">Section 2</span>
        </Divider.divider>
        """)

      assert html =~ ~s(<span class="font-bold">Section 2</span>)
    end

    test "labeled divider inherits colors" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider color="primary" variant="solid">Title</Divider.divider>])

      assert html =~ ~s(text-primary dark:text-dark-primary)
      assert html =~ ~s(border-primary dark:border-dark-primary)
    end

    test "labeled divider with vertical orientation" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider orientation="vertical">Label</Divider.divider>])

      assert html =~ ~s(flex flex-col items-center h-full)
      assert html =~ "Label"
    end
  end

  describe "divider customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider class="my-custom-class" />])

      assert html =~ ~s(my-custom-class)
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider id="my-divider" data-testid="divider" />])

      assert html =~ ~s(id="my-divider")
      assert html =~ ~s(data-testid="divider")
    end

    test "custom classes work with labeled dividers" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider class="my-custom-spacing">Label</Divider.divider>])

      assert html =~ ~s(my-custom-spacing)
      assert html =~ "Label"
    end
  end

  describe "variant and color combinations" do
    test "solid variant with primary color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="solid" color="primary" />])

      assert html =~ ~s(border-primary dark:border-dark-primary)
    end

    test "outline variant with danger color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="outline" color="danger" />])

      assert html =~ ~s(border-danger/60 dark:border-dark-danger/60)
    end

    test "ghost variant with success color" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider variant="ghost" color="success" />])

      assert html =~ ~s(border-success/30 dark:border-dark-success/30)
    end
  end

  describe "complex combinations" do
    test "labeled divider with dashed style and custom color" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H[<Divider.divider style="dashed" color="primary" variant="solid">Section</Divider.divider>]
        )

      assert html =~ ~s(border-dashed)
      assert html =~ ~s(border-primary dark:border-dark-primary)
      assert html =~ "Section"
    end

    test "vertical divider with custom size and style" do
      assigns = %{}
      html = rendered_to_string(~H[<Divider.divider orientation="vertical" size="lg" style="dotted" />])

      assert html =~ ~s(border-l-4)
      assert html =~ ~s(mx-8)
      assert html =~ ~s(border-dotted)
    end

    test "labeled divider with all customizations" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H[<Divider.divider variant="solid" color="primary" size="lg" style="dashed">Custom</Divider.divider>]
        )

      assert html =~ ~s(border-dashed)
      assert html =~ ~s(text-lg mx-4)
      assert html =~ ~s(border-primary dark:border-dark-primary)
      assert html =~ "Custom"
    end
  end
end
