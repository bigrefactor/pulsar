defmodule Pulsar.Components.AlertDialogTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.AlertDialog
  alias Pulsar.Components.Modal

  describe "alert_dialog/1 basic functionality" do
    test "renders a native dialog with the alertdialog role and the message" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?">
          This can't be undone.
        </AlertDialog.alert_dialog>
        """)

      assert html =~ "<dialog"
      assert html =~ ~s(role="alertdialog")
      assert html =~ "This can't be undone."
      assert html =~ "PulsarModal"
    end

    test "auto-generates a dialog id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog title="Delete?">Body</AlertDialog.alert_dialog>
        """)

      assert html =~ ~s(id="alert-dialog-)
    end
  end

  describe "alert_dialog/1 accessibility wiring" do
    test "title labels the dialog and the message is the description target" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete account?">
          Permanent and irreversible.
        </AlertDialog.alert_dialog>
        """)

      assert html =~ ~s(aria-labelledby="a-title")
      assert html =~ "Delete account?"
      assert html =~ ~s(aria-describedby="a-message")
      assert html =~ ~s(id="a-message")
    end

    test "focus lands on Cancel so an accidental Enter can't confirm" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?">Body</AlertDialog.alert_dialog>
        """)

      assert html =~ "autofocus"
    end
  end

  describe "alert_dialog/1 constrained dismissal" do
    test "Escape works but backdrop click and the close button are removed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?">Body</AlertDialog.alert_dialog>
        """)

      # Escape stays enabled (dismissable), backdrop dismissal is off…
      assert html =~ ~s(data-dismissable="true")
      assert html =~ ~s(data-backdrop-close="false")
      # …and there is no corner close (X) button.
      refute html =~ ~s(aria-label="Close")
    end
  end

  describe "alert_dialog/1 confirm/cancel footer" do
    test "renders Cancel and Confirm with their labels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?">Body</AlertDialog.alert_dialog>
        """)

      assert html =~ "Cancel"
      assert html =~ "Confirm"
    end

    test "labels are overridable for localization" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog
          id="a"
          title="Delete?"
          cancel_label="Annuler"
          confirm_label="Supprimer"
        >
          Body
        </AlertDialog.alert_dialog>
        """)

      assert html =~ "Annuler"
      assert html =~ "Supprimer"
    end

    test "the destructive command rides only on Confirm, which then closes" do
      assigns = %{on_confirm: JS.push("delete_it")}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?" on_confirm={@on_confirm}>
          Body
        </AlertDialog.alert_dialog>
        """)

      # The confirm command is present (Confirm runs it) and both controls close
      # the dialog via the modal close event.
      assert html =~ "delete_it"
      assert html =~ "pulsar:modal-close"
    end

    test "color defaults to danger and drives the Confirm button" do
      assigns = %{}

      danger =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Delete?">Body</AlertDialog.alert_dialog>
        """)

      assert danger =~ "bg-danger"

      primary =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Publish?" color="primary">
          Body
        </AlertDialog.alert_dialog>
        """)

      assert primary =~ "bg-primary"
    end
  end

  describe "alert_dialog/1 surface passthrough" do
    test "a single color tints the panel and the Confirm button together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AlertDialog.alert_dialog id="a" title="Publish?" variant="solid" color="primary" size="lg">
          Body
        </AlertDialog.alert_dialog>
        """)

      # Panel tint (Modal solid surface) and the Confirm button share the color…
      assert html =~ "bg-primary/10"
      assert html =~ "bg-primary"
      # …and size passes through to the panel.
      assert html =~ "max-w-lg"
    end
  end

  describe "alert_dialog/1 open/close JS commands" do
    test "delegate to the underlying modal events" do
      assert AlertDialog.open("a") == Modal.open("a")
      assert AlertDialog.close("a") == Modal.close("a")

      base = JS.push("save")
      assert AlertDialog.open(base, "a") == Modal.open(base, "a")
      assert AlertDialog.close(base, "a") == Modal.close(base, "a")
    end
  end
end
