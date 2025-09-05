defmodule Pulsar.Components.ListTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.List

  describe "list/1 basic functionality" do
    test "renders basic list with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:item title="Name">John Doe</:item>
          <:item title="Email">john@example.com</:item>
        </List.list>
        """)

      assert html =~ ~s(<dl)
      assert html =~ ~s(dl-list)
      assert html =~ ~s(<dt)
      assert html =~ ~s(<dd)
      assert html =~ "Name"
      assert html =~ "John Doe"
      assert html =~ "Email"
      assert html =~ "john@example.com"
    end

    test "renders with semantic HTML structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:item title="Status">Active</:item>
        </List.list>
        """)

      # Should use proper definition list structure
      assert html =~ ~s(<dl)
      assert html =~ ~s(<dt)
      assert html =~ ~s(<dd)
      assert html =~ "Status"
      assert html =~ "Active"
    end

    test "renders item content correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:item title="Complex Content">
            <span class="font-bold">Bold Text</span>
            <em>Italic Text</em>
          </:item>
        </List.list>
        """)

      assert html =~ "Complex Content"
      assert html =~ ~s(<span class="font-bold">Bold Text</span>)
      assert html =~ ~s(<em>Italic Text</em>)
    end
  end

  describe "list variants" do
    test "renders ghost variant (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="ghost">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      # Ghost should have minimal styling - no border or background on container
      refute html =~ ~s(border)
      refute html =~ ~s(bg-)
      assert html =~ ~s(dl-list)
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="outline">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(border)
      assert html =~ ~s(rounded-lg)
      assert html =~ ~s(bg-background)
    end

    test "renders solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="solid">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(rounded-lg)
      assert html =~ ~s(bg-muted)
      assert html =~ ~s(border-border)
    end
  end

  describe "list colors" do
    test "renders primary color with ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="ghost" color="primary">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-primary)
      assert html =~ ~s(dark:text-dark-primary)
    end

    test "renders primary color with outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="outline" color="primary">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(border-primary)
      assert html =~ ~s(dark:border-dark-primary)
      assert html =~ ~s(text-primary)
      assert html =~ ~s(hover:bg-primary/5)
    end

    test "renders primary color with solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list variant="solid" color="primary">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(bg-primary/5)
      assert html =~ ~s(border-primary/20)
      assert html =~ ~s(text-primary)
    end

    test "renders danger color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list color="danger">
          <:item title="Error">Something went wrong</:item>
        </List.list>
        """)

      assert html =~ ~s(text-danger)
      assert html =~ ~s(dark:text-dark-danger)
    end

    test "renders success color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list color="success">
          <:item title="Status">All good</:item>
        </List.list>
        """)

      assert html =~ ~s(text-success)
      assert html =~ ~s(dark:text-dark-success)
    end
  end

  describe "list sizes" do
    test "renders xs size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list size="xs">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-xs)
      assert html =~ ~s(py-3 px-2)
      assert html =~ ~s(gap-2)
    end

    test "renders sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list size="sm">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-sm)
      assert html =~ ~s(py-4 px-3)
      assert html =~ ~s(gap-3)
    end

    test "renders md size (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list size="md">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-base)
      assert html =~ ~s(py-6 px-4)
      assert html =~ ~s(gap-4)
    end

    test "renders lg size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list size="lg">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-lg)
      assert html =~ ~s(py-8 px-6)
      assert html =~ ~s(gap-6)
      assert html =~ ~s(font-semibold)
    end

    test "renders xl size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list size="xl">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(text-xl)
      assert html =~ ~s(py-10 px-8)
      assert html =~ ~s(gap-8)
      assert html =~ ~s(font-semibold)
    end
  end

  describe "list features" do
    test "renders striped rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list striped={true}>
          <:item title="Item 1">Content 1</:item>
          <:item title="Item 2">Content 2</:item>
          <:item title="Item 3">Content 3</:item>
        </List.list>
        """)

      # Should stripe even-indexed items (index 1, 3, etc.)
      assert html =~ ~s(bg-muted/30)
    end

    test "renders dividers between items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list dividers={true}>
          <:item title="Item 1">Content 1</:item>
          <:item title="Item 2">Content 2</:item>
        </List.list>
        """)

      assert html =~ ~s(border-t)
      assert html =~ ~s(border-border)
    end
  end

  describe "custom classes and attributes" do
    test "applies custom class to container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list class="my-custom-class">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(my-custom-class)
    end

    test "applies custom class to individual items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:item title="Title" class="item-custom-class">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(item-custom-class)
    end

    test "passes through global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list id="my-list" data-testid="test-list">
          <:item title="Title">Content</:item>
        </List.list>
        """)

      assert html =~ ~s(id="my-list")
      assert html =~ ~s(data-testid="test-list")
    end
  end

  describe "combination tests" do
    test "renders all features together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list
          variant="outline"
          color="primary"
          size="lg"
          striped={true}
          dividers={true}
          class="custom-list"
        >
          <:item title="First Item">First Content</:item>
          <:item title="Second Item">Second Content</:item>
          <:item title="Third Item">Third Content</:item>
        </List.list>
        """)

      # Check variant
      assert html =~ ~s(border)
      assert html =~ ~s(rounded-lg)

      # Check color
      assert html =~ ~s(border-primary)
      assert html =~ ~s(text-primary)

      # Check size
      assert html =~ ~s(text-lg)
      assert html =~ ~s(py-8 px-6)

      # Check features
      # striped
      assert html =~ ~s(bg-muted/20)
      # dividers
      assert html =~ ~s(border-t)

      # Check custom class
      assert html =~ ~s(custom-list)
    end

    test "works with complex content including other components" do
      assigns = %{status: "active"}

      html =
        rendered_to_string(~H"""
        <List.list variant="solid" color="success">
          <:item title="Status">
            <span class={"badge badge-#{@status}"}>
              {String.upcase(@status)}
            </span>
          </:item>
          <:item title="Actions">
            <button class="btn">Edit</button>
            <button class="btn">Delete</button>
          </:item>
        </List.list>
        """)

      assert html =~ ~s(bg-success/5)
      assert html =~ ~s(text-success)
      assert html =~ "Status"
      assert html =~ ~s(<span class="badge badge-active">)
      assert html =~ "ACTIVE"
      assert html =~ "Actions"
      assert html =~ ~s(<button class="btn">Edit</button>)
    end
  end

  describe "edge cases" do
    test "handles empty content gracefully" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:item title="Empty"></:item>
          <:item title="Also Empty"></:item>
        </List.list>
        """)

      assert html =~ "Empty"
      assert html =~ "Also Empty"
      # Should still render proper structure
      assert html =~ ~s(<dt)
      assert html =~ ~s(<dd)
    end

    test "handles no items with default message" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list></List.list>
        """)

      # Should render dl with default empty message
      assert html =~ ~s(<dl)
      assert html =~ ~s(</dl>)
      assert html =~ "No items to display"
      refute html =~ ~s(<dt)
      refute html =~ ~s(<dd)
    end

    test "handles no items with custom empty slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list>
          <:empty>
            <div class="custom-empty">
              Custom empty message
            </div>
          </:empty>
        </List.list>
        """)

      # Should render dl with custom empty content
      assert html =~ ~s(<dl)
      assert html =~ ~s(</dl>)
      assert html =~ "Custom empty message"
      assert html =~ "custom-empty"
      refute html =~ "No items to display"
      refute html =~ ~s(<dt)
      refute html =~ ~s(<dd)
    end

    test "handles single item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <List.list striped={true} dividers={true}>
          <:item title="Only Item">Only Content</:item>
        </List.list>
        """)

      assert html =~ "Only Item"
      assert html =~ "Only Content"
      # Single item shouldn't have dividers or striping
      refute html =~ ~s(border-t)
      refute html =~ ~s(bg-muted/30)
    end
  end
end
