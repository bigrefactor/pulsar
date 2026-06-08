defmodule Pulsar.Components.StatusTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Status

  describe "status/1 colors" do
    test "default color is neutral" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status />])

      assert html =~ "bg-neutral"
      assert html =~ "rounded-full"
    end

    test "each semantic color applies its bg token" do
      for {color, token} <- [
            {"primary", "bg-primary"},
            {"secondary", "bg-secondary"},
            {"success", "bg-success"},
            {"danger", "bg-danger"},
            {"warning", "bg-warning"},
            {"info", "bg-info"}
          ] do
        assigns = %{color: color}
        html = rendered_to_string(~H[<Status.status color={@color} />])
        assert html =~ token, "expected #{color} to render #{token}"
      end
    end
  end

  describe "status/1 sizes" do
    test "default md size" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status />])
      assert html =~ "h-2.5 w-2.5"
    end

    test "xs and xl sizes" do
      assigns = %{}
      assert rendered_to_string(~H[<Status.status size="xs" />]) =~ "h-1.5 w-1.5"
      assert rendered_to_string(~H[<Status.status size="xl" />]) =~ "h-4 w-4"
    end
  end

  describe "status/1 ping" do
    test "ping renders an aria-hidden animated halo clone plus a static dot" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status ping color="danger" />])

      assert html =~ "animate-ping"
      assert html =~ "motion-reduce:hidden"
      assert length(Regex.scan(~r/bg-danger/, html)) == 2
      assert html =~ ~s(aria-hidden="true")
    end

    test "no ping → no halo" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status color="danger" />])

      refute html =~ "animate-ping"
    end
  end

  describe "status/1 accessibility" do
    test "no label → decorative (aria-hidden, no role)" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status color="success" />])

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="img")
      refute html =~ "aria-label"
    end

    test "label → meaningful (role=img + aria-label, not hidden)" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status color="success" label="Online" />])

      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Online")
      refute html =~ ~s(aria-hidden="true")
    end

    test "blank label is treated as decorative" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status label="   " />])

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="img")
    end
  end

  describe "status/1 customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status class="custom-class" />])
      assert html =~ "custom-class"
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Status.status id="s1" data-testid="dot" />])
      assert html =~ ~s(id="s1")
      assert html =~ ~s(data-testid="dot")
    end
  end

  describe "indicator/1" do
    test "renders decorated content and the placed item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Status.indicator>
          <:item><Status.status color="success" label="Online" /></:item>
          <span>Avatar</span>
        </Status.indicator>
        """)

      assert html =~ "Avatar"
      assert html =~ ~s(aria-label="Online")
      assert html =~ "absolute"
    end

    test "default placement is top-right" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Status.indicator>
          <:item><Status.status color="success" /></:item>
          <span>X</span>
        </Status.indicator>
        """)

      assert html =~ "top-0"
      assert html =~ "right-0"
    end

    test "bottom-left placement applies its position utilities" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Status.indicator placement="bottom-left">
          <:item><Status.status color="success" /></:item>
          <span>X</span>
        </Status.indicator>
        """)

      assert html =~ "bottom-0"
      assert html =~ "left-0"
    end

    test "separation ring is on by default and removable with ring={false}" do
      assigns = %{}

      with_ring =
        rendered_to_string(~H"""
        <Status.indicator>
          <:item><Status.status color="success" /></:item>
          <span>X</span>
        </Status.indicator>
        """)

      assert with_ring =~ "ring-background"

      without_ring =
        rendered_to_string(~H"""
        <Status.indicator ring={false}>
          <:item><Status.status color="success" /></:item>
          <span>X</span>
        </Status.indicator>
        """)

      refute without_ring =~ "ring-background"
    end
  end
end
