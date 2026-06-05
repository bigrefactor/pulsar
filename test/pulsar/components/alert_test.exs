defmodule Pulsar.Components.AlertTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Alert

  describe "alert/1 defaults" do
    test "renders ghost info with an auto information-circle icon" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="Saved." />])

      assert html =~ "Saved."
      assert html =~ "hero-information-circle"
      assert html =~ "bg-info/10"
      assert html =~ "text-info"
      assert html =~ ~s(aria-hidden="true")
    end

    test "is full-width by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="Saved." />])
      assert html =~ "w-full"
    end
  end

  describe "alert/1 variants" do
    test "solid uses a filled background" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert variant="solid" color="success" description="Ok" />])
      assert html =~ "bg-success"
      assert html =~ "text-success-foreground"
    end

    test "outline uses a border on the page background" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert variant="outline" color="danger" description="No" />])
      assert html =~ "border-danger"
      assert html =~ "bg-background"
    end

    test "ghost uses a tinted background" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert variant="ghost" color="warning" description="Hmm" />])
      assert html =~ "bg-warning/10"
      assert html =~ "text-warning"
    end
  end

  describe "alert/1 colors and auto icon" do
    test "success maps to check-circle" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert color="success" description="x" />])
      assert html =~ "hero-check-circle"
    end

    test "danger maps to x-circle" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert color="danger" description="x" />])
      assert html =~ "hero-x-circle"
    end

    test "warning maps to exclamation-triangle" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert color="warning" description="x" />])
      assert html =~ "hero-exclamation-triangle"
    end
  end

  describe "alert/1 sizes" do
    test "sm applies its container padding" do
      assigns = %{}
      assert rendered_to_string(~H[<Alert.alert size="sm" description="x" />]) =~ "p-2"
    end

    test "md applies its container padding" do
      assigns = %{}
      assert rendered_to_string(~H[<Alert.alert size="md" description="x" />]) =~ "p-3"
    end

    test "lg applies its container padding" do
      assigns = %{}
      assert rendered_to_string(~H[<Alert.alert size="lg" description="x" />]) =~ "p-4"
    end
  end

  describe "alert/1 title and description" do
    test "renders a semibold title above the description" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert title="Heads up" description="Trial ends soon." />])
      assert html =~ "Heads up"
      assert html =~ "font-semibold"
      assert html =~ "Trial ends soon."
    end

    test "falls back to inner_block when no description is given" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert title="Note">Body <a href="/x">link</a></Alert.alert>])
      assert html =~ "Body"
      assert html =~ ~s(<a href="/x">link</a>)
    end

    test "description attr wins over inner_block" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="Attr body">Slot body</Alert.alert>])
      assert html =~ "Attr body"
      refute html =~ "Slot body"
    end
  end

  describe "alert/1 icon override" do
    test "icon attr overrides the auto glyph" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert color="info" icon="hero-bell" description="x" />])
      assert html =~ "hero-bell"
      refute html =~ "hero-information-circle"
    end

    test "icon={false} renders no icon" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert icon={false} description="x" />])
      refute html =~ "hero-"
    end
  end

  describe "alert/1 custom classes" do
    test "Twm merges and lets custom classes override" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert class="p-8" description="x" />])
      assert html =~ "p-8"
      refute html =~ "p-3"
    end
  end

  describe "alert/1 dismiss" do
    test "is not dismissible by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="x" />])
      refute html =~ "<button"
    end

    test "dismissible renders a labelled close button wired to hide itself" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert id="a1" dismissible description="x" />])
      assert html =~ "<button"
      assert html =~ ~s(type="button")
      assert html =~ ~s(aria-label="Dismiss")
      assert html =~ ~s(aria-controls="a1")
      assert html =~ "hero-x-mark"
      assert html =~ "phx-click"
      assert html =~ "#a1"
    end

    test "dismiss_label overrides the close button label" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert dismissible dismiss_label="Close" description="x" />])
      assert html =~ ~s(aria-label="Close")
    end
  end

  describe "alert/1 actions" do
    test "renders the actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Alert.alert description="x">
  <:actions><button>Renew</button></:actions>
</Alert.alert>])

      assert html =~ "Renew"
    end

    test "no actions wrapper is rendered without the slot" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="x" />])
      refute html =~ ~s(flex shrink-0 items-center gap-2)
    end
  end

  describe "alert/1 role" do
    test "has no role by default" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert description="x" />])
      refute html =~ ~s(role=)
    end

    test "applies an explicit role" do
      assigns = %{}
      html = rendered_to_string(~H[<Alert.alert role="alert" description="x" />])
      assert html =~ ~s(role="alert")
    end
  end
end
