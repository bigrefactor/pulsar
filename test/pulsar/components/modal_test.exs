defmodule Pulsar.Components.ModalTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Modal

  describe "modal/1 basic functionality" do
    test "renders a native dialog wired to the colocated hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m">Dialog body</Modal.modal>
        """)

      assert html =~ "<dialog"
      assert html =~ "Dialog body"
      assert html =~ ~s(id="m")
      assert html =~ "PulsarModal"
      assert html =~ ~s(data-state="closed")
    end

    test "auto-generates a dialog id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal>Body</Modal.modal>
        """)

      assert html =~ ~s(id="modal-)
    end
  end

  describe "modal/1 open/close JS commands" do
    test "open/1 and close/1 dispatch the modal events at the panel" do
      assert Modal.open("m") == JS.dispatch("pulsar:modal-open", to: "#m")
      assert Modal.close("m") == JS.dispatch("pulsar:modal-close", to: "#m")
    end

    test "open/2 and close/2 compose onto an existing JS pipeline" do
      base = JS.push("save")
      assert Modal.open(base, "m") == JS.dispatch(base, "pulsar:modal-open", to: "#m")
      assert Modal.close(base, "m") == JS.dispatch(base, "pulsar:modal-close", to: "#m")
    end
  end

  describe "modal/1 dismissable contract" do
    test "is dismissable by default with a labelled close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit">Body</Modal.modal>
        """)

      assert html =~ ~s(data-dismissable="true")
      assert html =~ ~s(aria-label="Close")
    end

    test "dismissable={false} locks the dialog and hides the close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Confirm" dismissable={false}>Body</Modal.modal>
        """)

      assert html =~ ~s(data-dismissable="false")
      refute html =~ ~s(aria-label="Close")
    end

    test "close_label is overridable for localization" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit" close_label="Fermer">Body</Modal.modal>
        """)

      assert html =~ ~s(aria-label="Fermer")
    end

    test "backdrop_close is true by default and toggles the data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit">Body</Modal.modal>
        """)

      assert html =~ ~s(data-backdrop-close="true")

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit" backdrop_close={false}>Body</Modal.modal>
        """)

      assert html =~ ~s(data-backdrop-close="false")
    end

    test "show_close_button={false} hides the close button but keeps the title heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Confirm" show_close_button={false}>Body</Modal.modal>
        """)

      refute html =~ ~s(aria-label="Close")
      assert html =~ ~s(id="m-title")
      assert html =~ "Confirm"
    end
  end

  describe "modal/1 title and description wiring" do
    test "title renders a heading and labels the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit user">Body</Modal.modal>
        """)

      assert html =~ ~s(id="m-title")
      assert html =~ "Edit user"
      assert html =~ ~s(aria-labelledby="m-title")
    end

    test "description slot is rendered and describes the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit user">
          <:description>Update the details below.</:description>
          Body
        </Modal.modal>
        """)

      assert html =~ ~s(id="m-desc")
      assert html =~ "Update the details below."
      assert html =~ ~s(aria-describedby="m-desc")
    end

    test "renders the description when there is no title and the dialog is non-dismissable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" dismissable={false}>
          <:description>Help text.</:description>
          Body
        </Modal.modal>
        """)

      assert html =~ ~s(id="m-desc")
      assert html =~ "Help text."
      assert html =~ ~s(aria-describedby="m-desc")
    end

    test "omits labelledby/describedby when neither title nor description is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m">Body</Modal.modal>
        """)

      refute html =~ "aria-labelledby"
      refute html =~ "aria-describedby"
    end
  end

  describe "modal/1 footer slot" do
    test "renders footer actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" title="Edit">
          Body
          <:footer>
            <button>Cancel</button>
            <button>Save</button>
          </:footer>
        </Modal.modal>
        """)

      assert html =~ "Cancel"
      assert html =~ "Save"
    end
  end

  describe "modal/1 variants, colors, sizes (mirrors Popover surface)" do
    test "elevated neutral default is a surface panel with the modal shadow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m">Body</Modal.modal>
        """)

      assert html =~ "bg-surface-1"
      assert html =~ "shadow-modal"
    end

    test "solid color uses a soft tint + border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" variant="solid" color="danger">Body</Modal.modal>
        """)

      assert html =~ "bg-danger/10"
      assert html =~ "border-danger/20"
    end

    test "outline color uses a colored border on a surface" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" variant="outline" color="primary">Body</Modal.modal>
        """)

      assert html =~ "border-primary"
    end

    test "size controls dialog width and padding" do
      cases = %{
        "sm" => {"max-w-sm", "p-5"},
        "md" => {"max-w-md", "p-6"},
        "lg" => {"max-w-lg", "p-6"},
        "xl" => {"max-w-2xl", "p-7"}
      }

      for {size, {width, pad}} <- cases do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Modal.modal id="m" size={@size}>Body</Modal.modal>
          """)

        assert html =~ width, "expected size=#{size} to render #{width}"
        assert html =~ pad, "expected size=#{size} to render #{pad}"
      end
    end

    test "carries the modal z-index layer and a dimmed backdrop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m">Body</Modal.modal>
        """)

      assert html =~ "z-modal"
      assert html =~ "backdrop:bg-foreground/50"
    end
  end

  describe "modal/1 callbacks and passthrough" do
    test "on_open / on_close are emitted as JS commands" do
      assigns = %{
        on_open: JS.dispatch("opened", to: "#x"),
        on_close: JS.dispatch("closed", to: "#x")
      }

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" on_open={@on_open} on_close={@on_close}>Body</Modal.modal>
        """)

      assert html =~ "data-on-open"
      assert html =~ "data-on-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end

    test "passes through aria attributes onto the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" aria-label="Settings">Body</Modal.modal>
        """)

      assert html =~ ~s(aria-label="Settings")
    end
  end

  describe "modal/1 customization (Twm merge)" do
    test "user class overrides the default surface (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" class="bg-foreground text-background">Body</Modal.modal>
        """)

      assert html =~ "bg-foreground"
      refute html =~ "bg-surface-1"
    end
  end

  describe "modal/1 panel_animation" do
    test "defaults to the scale-in entrance" do
      assigns = %{}
      html = rendered_to_string(~H|<Modal.modal id="m" title="T">body</Modal.modal>|)
      assert html =~ "animate-scale-in"
    end

    test "overriding panel_animation replaces the entrance utility" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Modal.modal id="m" title="T" panel_animation="animate-drawer-from-right">body</Modal.modal>|
        )

      assert html =~ "animate-drawer-from-right"
      refute html =~ "animate-scale-in"
    end
  end
end
