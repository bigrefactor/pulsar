defmodule Pulsar.Components.BadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
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

    test "badge base uses the fast color-transition motion tokens" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge>Motion</Badge.badge>])

      assert html =~ ~s(transition-colors)
      assert html =~ ~s(duration-fast)
      assert html =~ ~s(ease-standard)
      refute html =~ ~s(duration-normal)
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

  describe "badge element type" do
    test "renders a div when as={:div}" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge as={:div}>Token</Badge.badge>])

      assert html =~ ~s(<div)
      refute html =~ ~s(<span)
    end

    test "as={:div} keeps the badge styling" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge as={:div} color="primary">Token</Badge.badge>])

      assert html =~ ~s(inline-flex items-center)
      assert html =~ ~s(bg-primary text-primary-foreground)
      assert html =~ ~s(text-sm px-2.5 py-0.5)
    end
  end

  describe "badge focus indicator" do
    test "rings the focused control rather than the whole badge" do
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

      assert html =~ "[&amp;&gt;button]:focus-visible:ring-2"
      assert html =~ "[&amp;&gt;button]:focus-visible:ring-current"
      refute html =~ "focus-within:ring-2"
    end

    test "gives an interactive control in the label region a ≥24px target (WCAG 2.5.8)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge size="xs">
          <button type="button">Status: Published</button>
        </Badge.badge>
        """)

      assert html =~ "[&amp;&gt;button]:min-h-6"
      assert html =~ "[&amp;&gt;button]:min-w-6"
      assert html =~ "[&amp;&gt;button]:focus-visible:ring-2"
    end
  end

  describe "badge remove control" do
    test "renders no remove control by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Badge.badge>Plain</Badge.badge>])

      refute html =~ ~s(<button)
    end

    test "renders a labeled remove control when on_remove is set" do
      assigns = %{on_remove: JS.push("remove_tag", value: %{id: 7})}

      html =
        rendered_to_string(~H[<Badge.badge on_remove={@on_remove} remove_label="Remove tag Draft">Draft</Badge.badge>])

      assert html =~ ~s(<button)
      assert html =~ ~s(type="button")
      assert html =~ ~s(aria-label="Remove tag Draft")
      assert html =~ "remove_tag"
    end

    test "renders the remove control after the end addon" do
      assigns = %{on_remove: JS.push("remove_tag")}

      html =
        rendered_to_string(~H"""
        <Badge.badge on_remove={@on_remove} remove_label="Remove tag Draft">
          Draft
          <:end_addon>
            <span>ADDON</span>
          </:end_addon>
        </Badge.badge>
        """)

      assert html =~ "ADDON"

      addon_at = :binary.match(html, "ADDON") |> elem(0)
      remove_at = :binary.match(html, ~s(aria-label="Remove tag Draft")) |> elem(0)
      assert addon_at < remove_at
    end

    test "raises when on_remove is set without remove_label" do
      assigns = %{on_remove: JS.push("remove_tag")}

      assert_raise ArgumentError, ~r/on_remove.*remove_label/s, fn ->
        rendered_to_string(~H[<Badge.badge on_remove={@on_remove}>Draft</Badge.badge>])
      end
    end

    test "raises when on_remove is set with a blank remove_label" do
      for remove_label <- ["", "   "] do
        assigns = %{on_remove: JS.push("remove_tag"), remove_label: remove_label}

        assert_raise ArgumentError, ~r/on_remove.*remove_label/s, fn ->
          rendered_to_string(~H[<Badge.badge on_remove={@on_remove} remove_label={@remove_label}>Draft</Badge.badge>])
        end
      end
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
