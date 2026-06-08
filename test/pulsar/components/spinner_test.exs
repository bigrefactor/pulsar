defmodule Pulsar.Components.SpinnerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Spinner

  describe "spinner/1 defaults" do
    test "renders a ring spinner with a status role and a visually-hidden label" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner />])

      assert html =~ ~s(role="status")
      assert html =~ ~s(<svg)
      assert html =~ "animate-spin"
      assert html =~ ~s(class="sr-only")
      assert html =~ "Loading"
    end

    test "the visual element is hidden from assistive tech" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner />])

      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "spinner/1 variants" do
    test "dots variant renders three dot elements" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner variant="dots" />])

      assert html =~ "pulsar-spinner-dots"
      assert length(Regex.scan(~r/bg-current/, html)) == 3
    end

    test "bars variant renders four bar elements" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner variant="bars" />])

      assert html =~ "pulsar-spinner-bars"
      assert length(Regex.scan(~r/bg-current/, html)) == 4
    end
  end

  describe "spinner/1 sizes" do
    test "ring md size (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner size="md" />])

      assert html =~ "h-5 w-5"
    end

    test "ring xs size" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner size="xs" />])

      assert html =~ "h-3 w-3"
    end

    test "ring xl size" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner size="xl" />])

      assert html =~ "h-8 w-8"
    end
  end

  describe "spinner/1 colors" do
    test "primary color applies a semantic text token" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner color="primary" />])

      assert html =~ "text-primary"
    end

    test "current color (default) inherits and adds no text color token" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner />])

      refute html =~ "text-primary"
      refute html =~ "text-success"
    end
  end

  describe "spinner/1 accessibility" do
    test "custom label is announced" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner label="Saving changes" />])

      assert html =~ "Saving changes"
    end

    test "decorative hides the spinner and omits the status role and label" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner decorative />])

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="status")
      refute html =~ ~s(class="sr-only")
    end
  end

  describe "spinner/1 customization" do
    test "accepts custom CSS classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner class="custom-class" />])

      assert html =~ "custom-class"
    end

    test "accepts global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Spinner.spinner id="my-spinner" data-testid="spin" />])

      assert html =~ ~s(id="my-spinner")
      assert html =~ ~s(data-testid="spin")
    end
  end
end
