defmodule Pulsar.Components.ProgressTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Progress

  describe "progress/1 linear determinate" do
    test "renders a progressbar with aria value attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={62} label="Uploading" />])

      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-valuenow="62")
      assert html =~ ~s(aria-label="Uploading")
    end

    test "fill width reflects the percentage via inline style" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={62} />])

      assert html =~ "width: 62%"
      assert html =~ "bg-primary"
    end

    test "scales value against a custom max" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={3} max={10} />])

      assert html =~ ~s(aria-valuemax="10")
      assert html =~ ~s(aria-valuenow="3")
      assert html =~ "width: 30%"
    end

    test "clamps out-of-range values" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={250} max={100} />])

      assert html =~ "width: 100%"
      assert html =~ ~s(aria-valuenow="100")
    end
  end

  describe "progress/1 label and value text" do
    test "shows the label and the computed percentage, with the value hidden from AT" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={62} label="Uploading" show_value />])

      assert html =~ "Uploading"
      # the visible percentage is aria-hidden so the role's own announcement isn't duplicated
      assert html =~ ~r/aria-hidden="true"[^>]*>\s*62%\s*</
    end

    test "omits value text when show_value is false" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={62} />])

      # the value span carries tabular-nums; its absence means no visible percentage
      refute html =~ ~r/aria-hidden="true"[^>]*>\s*62%\s*</
    end
  end

  describe "progress/1 indeterminate (linear)" do
    test "omits aria-valuenow and uses a pulsing fill" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress label="Loading" />])

      assert html =~ ~s(role="progressbar")
      refute html =~ "aria-valuenow"
      assert html =~ "animate-pulse"
    end
  end

  describe "progress/1 radial" do
    test "renders an svg ring with a dasharray and dashoffset for the arc" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress shape="radial" value={100} />])

      assert html =~ "<svg"
      assert html =~ ~s(role="progressbar")
      assert html =~ "stroke-dasharray"
      # full progress closes the arc (offset 0)
      assert html =~ ~s(stroke-dashoffset="0.0")
    end

    test "shows centered percentage when show_value is set" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress shape="radial" value={62} show_value />])

      assert html =~ "62%"
      # the centered value overlay carries text-foreground for readable contrast
      assert html =~ ~r/absolute inset-0[^"]*text-foreground/
    end
  end

  describe "progress/1 colors and sizes" do
    test "applies the semantic fill color" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={50} color="success" />])

      assert html =~ "bg-success"
    end

    test "applies the linear size class" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={50} size="xl" />])

      assert html =~ "h-4"
    end
  end

  describe "progress/1 customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={50} class="custom-class" />])

      assert html =~ "custom-class"
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Progress.progress value={50} id="up" data-testid="p" />])

      assert html =~ ~s(id="up")
      assert html =~ ~s(data-testid="p")
    end
  end
end
