defmodule Pulsar.Components.BreadcrumbTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Breadcrumb

  defp three_crumbs(assigns) do
    ~H"""
    <Breadcrumb.breadcrumb {assigns}>
      <:item navigate="/home">Home</:item>
      <:item navigate="/products">Products</:item>
      <:item>Edit Product</:item>
    </Breadcrumb.breadcrumb>
    """
  end

  describe "breadcrumb/1 structure & ARIA" do
    test "renders a nav landmark labelled Breadcrumb wrapping an ordered list" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs />])

      assert html =~ ~s(<nav)
      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(<ol)
      assert html =~ ~s(data-component="breadcrumb")
    end

    test "last item is the current page: aria-current, bold, not a link" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs />])

      assert html =~ ~s(aria-current="page")
      assert html =~ "font-medium"
      assert html =~ "Edit Product"
      refute html =~ ~s(href="/edit-product")
    end

    test "non-final items with a nav prop render as links" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs />])

      assert html =~ ~s(href="/home")
      assert html =~ ~s(href="/products")
      assert html =~ "Home"
      assert html =~ "Products"
    end

    test "supports navigate, patch and href on items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/n">Nav</:item>
          <:item patch="/p">Patch</:item>
          <:item href="/h">Href</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(href="/n")
      assert html =~ ~s(href="/p")
      assert html =~ ~s(href="/h")
    end

    test "a non-final item with no nav prop renders as plain text, not a link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item>Plain</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "Plain"
      refute html =~ ~s(<a)
    end

    test "raises when an item combines multiple navigation props" do
      assigns = %{}

      assert_raise ArgumentError, ~r/Breadcrumb can only have one navigation prop/, fn ->
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/home" href="/conflict">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)
      end
    end

    test "raise message lists all conflicting props" do
      assigns = %{}

      assert_raise ArgumentError, ~r/:navigate, :patch, :href/, fn ->
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/home" patch="/p" href="/h">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)
      end
    end
  end

  describe "breadcrumb/1 separators" do
    test "default separator is a decorative chevron, one fewer than items" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs />])

      assert html =~ "hero-chevron-right"
      assert length(Regex.scan(~r/hero-chevron-right/, html)) == 2
      assert html =~ ~s(aria-hidden="true")
    end

    test "custom separator slot replaces the chevron" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:separator>/</:separator>
          <:item navigate="/home">Home</:item>
          <:item>Docs</:item>
        </Breadcrumb.breadcrumb>
        """)

      refute html =~ "hero-chevron-right"
      assert html =~ "/"
    end
  end

  describe "breadcrumb/1 overflow" do
    test "no max_items renders every crumb (no ellipsis)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/a">A</:item>
          <:item navigate="/b">B</:item>
          <:item navigate="/c">C</:item>
          <:item navigate="/d">D</:item>
          <:item>E</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "A"
      assert html =~ "B"
      assert html =~ "C"
      assert html =~ "D"
      assert html =~ "E"
      refute html =~ "…"
    end

    test "max_items collapses the middle into a static aria-hidden ellipsis" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb max_items={4}>
          <:item navigate="/a">First</:item>
          <:item navigate="/b">Hidden1</:item>
          <:item navigate="/c">Hidden2</:item>
          <:item navigate="/d">Kept</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "…"
      assert html =~ "First"
      assert html =~ "Kept"
      assert html =~ "Current"
      refute html =~ "Hidden1"
      refute html =~ "Hidden2"
    end

    test "items_before_collapse and items_after_collapse control what is kept" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb max_items={4} items_before_collapse={2} items_after_collapse={0}>
          <:item navigate="/a">A</:item>
          <:item navigate="/b">B</:item>
          <:item navigate="/c">Hidden</:item>
          <:item navigate="/d">D</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "A"
      assert html =~ "B"
      assert html =~ "…"
      assert html =~ "Current"
      assert html =~ ~s(aria-current="page")
      refute html =~ "Hidden"
    end

    test "raises when keep counts cannot fit inside max_items" do
      assigns = %{}

      assert_raise ArgumentError, ~r/cannot honor items_before_collapse/, fn ->
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb max_items={4} items_before_collapse={2} items_after_collapse={2}>
          <:item navigate="/a">A</:item>
          <:item navigate="/b">B</:item>
          <:item navigate="/c">C</:item>
          <:item navigate="/d">D</:item>
          <:item navigate="/e">E</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)
      end
    end

    test "raises on negative keep counts" do
      assigns = %{}

      assert_raise ArgumentError, ~r/must be non-negative/, fn ->
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb max_items={4} items_before_collapse={-1}>
          <:item navigate="/a">A</:item>
          <:item navigate="/b">B</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)
      end
    end

    test "no validation when max_items is unset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb items_before_collapse={2} items_after_collapse={2}>
          <:item navigate="/a">A</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "A"
      refute html =~ "…"
    end
  end

  describe "breadcrumb/1 styling" do
    test "size scales the list text" do
      assigns = %{}
      assert rendered_to_string(~H[<.three_crumbs size="xs" />]) =~ "text-xs"
      assert rendered_to_string(~H[<.three_crumbs size="xl" />]) =~ "text-lg"
    end

    test "accepts custom classes via Twm merge" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs class="mt-8" />])
      assert html =~ "mt-8"
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs id="bc1" data-testid="bc" />])
      assert html =~ ~s(id="bc1")
      assert html =~ ~s(data-testid="bc")
    end

    test "aria_label is overridable" do
      assigns = %{}
      html = rendered_to_string(~H[<.three_crumbs aria_label="You are here" />])
      assert html =~ ~s(aria-label="You are here")
    end
  end
end
