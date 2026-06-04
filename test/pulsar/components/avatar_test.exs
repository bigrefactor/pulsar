defmodule Pulsar.Components.AvatarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Avatar

  describe "avatar/1 fallback chain" do
    test "renders an <img> when src is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Avatar.avatar src="/jane.png" name="Jane Doe" />])

      assert html =~ ~s(<img)
      assert html =~ ~s(src="/jane.png")
      assert html =~ ~s(object-cover)
    end

    test "renders initials when no src but a name is given" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])

      refute html =~ ~s(<img)
      assert html =~ "JD"
      assert html =~ ~s(bg-muted)
    end

    test "renders a user icon when neither src nor name is given" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar />])

      refute html =~ ~s(<img)
      assert html =~ "hero-user-solid"
      assert html =~ ~s(aria-hidden="true")
    end

    test "blank src falls through to the initials" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar src="" name="Jane Doe" />])

      refute html =~ ~s(<img)
      assert html =~ "JD"
    end
  end

  describe "avatar/1 initials reduction" do
    test "two first-and-last initials from a multi-word name" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])
      assert html =~ ">JD<"
    end

    test "a single long word reduces to one initial" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Pulsar" />])
      assert html =~ ">P<"
    end

    test "a pre-made two-character string is used as-is (uppercased)" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="jd" />])
      assert html =~ ">JD<"
    end

    test "first and last words across three-word names" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Acme Corp Inc" />])
      assert html =~ ">AI<"
    end

    test "lowercase names are uppercased" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="jane doe" />])
      assert html =~ ">JD<"
    end
  end

  describe "avatar/1 accessible name (alt || name)" do
    test "img alt defaults to name" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar src="/jane.png" name="Jane Doe" />])
      assert html =~ ~s(alt="Jane Doe")
    end

    test "alt overrides name on the image" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Avatar.avatar src="/j.png" name="Jane Doe" alt="Profile photo" />])

      assert html =~ ~s(alt="Profile photo")
      refute html =~ ~s(alt="Jane Doe")
    end

    test "explicit empty alt makes the image decorative" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar src="/d.png" name="Jane Doe" alt="" />])
      assert html =~ ~s(alt="")
    end

    test "fallback initials expose the name via role=img + aria-label" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])

      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Jane Doe")
    end

    test "the image wrapper does not duplicate the accessible name" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar src="/jane.png" name="Jane Doe" />])

      # The native <img alt> is the single source of the name — the wrapper
      # must not also carry role="img"/aria-label.
      refute html =~ ~s(role="img")
      refute html =~ ~s(aria-label="Jane Doe")
    end

    test "an unnamed decorative avatar emits no empty aria-label" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar />])

      refute html =~ ~s(aria-label=)
      refute html =~ ~s(role="img")
    end
  end

  describe "avatar/1 variants" do
    test "solid (default) fills with bg-muted" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])
      assert html =~ ~s(bg-muted)
    end

    test "outline draws a border on an unfilled surface" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" variant="outline" />])

      assert html =~ ~s(border)
      assert html =~ ~s(border-border)
      assert html =~ ~s(bg-background)
    end
  end

  describe "avatar/1 sizes" do
    test "md is the default size" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])
      assert html =~ ~s(w-10 h-10)
    end

    test "xs size" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" size="xs" />])
      assert html =~ ~s(w-6 h-6)
    end

    test "2xl size" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" size="2xl" />])
      assert html =~ ~s(w-16 h-16)
    end
  end

  describe "avatar/1 shape token" do
    test "uses the themeable rounded-avatar radius token" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])
      assert html =~ ~s(rounded-avatar)
    end
  end

  describe "avatar/1 navigation" do
    test "renders a link when navigate is provided" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" navigate="/users/1" />])

      assert html =~ ~s(<a)
      assert html =~ ~s(href="/users/1")
    end

    test "renders a link when href is provided" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" href="/users/1" />])

      assert html =~ ~s(<a)
      assert html =~ ~s(href="/users/1")
    end

    test "a linked fallback avatar is named via aria-label" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" navigate="/users/1" />])

      assert html =~ ~s(aria-label="Jane Doe")
    end

    test "a linked avatar has a visible focus ring" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" navigate="/users/1" />])

      assert html =~ "focus-visible:ring-2"
    end

    test "a non-interactive avatar is not a link" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" />])

      refute html =~ ~s(<a)
    end
  end

  describe "avatar/1 customization" do
    test "user class is merged and wins over defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Avatar.avatar name="Jane Doe" class="ring-4" />])
      assert html =~ ~s(ring-4)
    end

    test "passes through global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Avatar.avatar name="Jane Doe" id="u1" data-testid="avatar" />])

      assert html =~ ~s(id="u1")
      assert html =~ ~s(data-testid="avatar")
    end
  end

  describe "avatar_group/1" do
    test "lays out item avatars with overlap and ring separation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group>
          <:item><Avatar.avatar name="Ann Lee" /></:item>
          <:item><Avatar.avatar name="Bob Roy" /></:item>
        </Avatar.avatar_group>
        """)

      assert html =~ "-space-x-2"
      assert html =~ "ring-background"
      assert html =~ ">AL<"
      assert html =~ ">BR<"
    end

    test "renders a +N overflow counter when items exceed max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group max={2}>
          <:item><Avatar.avatar name="Ann Lee" /></:item>
          <:item><Avatar.avatar name="Bob Roy" /></:item>
          <:item><Avatar.avatar name="Cy Ng" /></:item>
          <:item><Avatar.avatar name="Di Fox" /></:item>
        </Avatar.avatar_group>
        """)

      assert html =~ ">AL<"
      assert html =~ ">BR<"
      assert html =~ "+2"
    end

    test "renders all items when under max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group max={5}>
          <:item><Avatar.avatar name="Ann Lee" /></:item>
          <:item><Avatar.avatar name="Bob Roy" /></:item>
        </Avatar.avatar_group>
        """)

      refute html =~ "+"
      assert html =~ ">AL<"
      assert html =~ ">BR<"
    end

    test "the overflow count runs through format_count" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group max={1} format_count={fn n -> "#{n} more" end}>
          <:item><Avatar.avatar name="Ann Lee" /></:item>
          <:item><Avatar.avatar name="Bob Roy" /></:item>
          <:item><Avatar.avatar name="Cy Ng" /></:item>
        </Avatar.avatar_group>
        """)

      assert html =~ "2 more"
    end

    test "passes through global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group data-testid="stack">
          <:item><Avatar.avatar name="Ann Lee" /></:item>
        </Avatar.avatar_group>
        """)

      assert html =~ ~s(data-testid="stack")
    end
  end
end
