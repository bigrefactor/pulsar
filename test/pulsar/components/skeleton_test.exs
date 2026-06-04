defmodule Pulsar.Components.SkeletonTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Skeleton

  describe "skeleton/1 kinds" do
    test "text (default) renders a pulsing placeholder bar with the field radius" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton />])

      assert html =~ "animate-pulse-subtle"
      assert html =~ "bg-surface-3"
      assert html =~ "h-4"
      assert html =~ "rounded-field"
    end

    test "circle renders with the full radius and the md box by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="circle" />])

      assert html =~ "rounded-full"
      assert html =~ "w-10 h-10"
      refute html =~ "rounded-field"
    end

    test "rect renders with the box radius and a default block height" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="rect" />])

      assert html =~ "rounded-box"
      assert html =~ "h-32"
    end
  end

  describe "skeleton/1 circle sizes" do
    test "size maps to avatar-matched box dimensions" do
      assigns = %{}

      assert rendered_to_string(~H[<Skeleton.skeleton kind="circle" size="xs" />]) =~ "w-6 h-6"
      assert rendered_to_string(~H[<Skeleton.skeleton kind="circle" size="lg" />]) =~ "w-12 h-12"
      assert rendered_to_string(~H[<Skeleton.skeleton kind="circle" size="2xl" />]) =~ "w-16 h-16"
    end
  end

  describe "skeleton/1 text lines" do
    test "a single line renders one bar with no flex container" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="text" lines={1} />])

      refute html =~ "flex-col"
    end

    test "multiple lines stack in a flex column with a gap" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="text" lines={3} />])

      assert html =~ "flex flex-col gap-2"
      # one bar per line
      assert length(String.split(html, "animate-pulse-subtle")) - 1 >= 3
    end

    test "the last line is shortened, the others fill the width" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="text" lines={3} />])

      assert html =~ "w-3/4"
      assert html =~ "w-full"
    end
  end

  describe "skeleton/1 animate_text" do
    test "renders the inner text and pulses its color, not a muted bar" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Skeleton.skeleton animate_text>AI is thinking…</Skeleton.skeleton>])

      assert html =~ "AI is thinking"
      assert html =~ "animate-pulse-subtle"
      assert html =~ "text-foreground"
      refute html =~ "bg-surface-3"
    end

    test "without a label the shimmer text is real content (not aria-hidden)" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Skeleton.skeleton animate_text>Loading…</Skeleton.skeleton>])

      refute html =~ ~s(aria-hidden)
    end
  end

  describe "skeleton/1 accessibility" do
    test "shapes are decorative (aria-hidden) by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton />])

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="status")
    end

    test "a label wraps the shapes in a polite loading status region" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton label="Loading profile" />])

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-busy="true")
      assert html =~ ~s(aria-label="Loading profile")
      # the inner shape stays decorative; the wrapper carries the announcement
      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "skeleton/1 customization" do
    test "user class is merged and overrides the default width" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton kind="text" class="w-20" />])

      assert html =~ "w-20"
      refute html =~ "w-full"
    end

    test "passes through global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Skeleton.skeleton id="s1" data-testid="skeleton" />])

      assert html =~ ~s(id="s1")
      assert html =~ ~s(data-testid="skeleton")
    end
  end
end
