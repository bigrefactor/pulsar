defmodule Pulsar.DevApp.Storybook.Components.AlertDialog do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.AlertDialog

  def function, do: &AlertDialog.alert_dialog/1
  def render_source, do: :function

  # Render each variation "in use": clicking the trigger opens the dialog as a real
  # focus-trapped modal (showModal + backdrop). The dialog auto-generates its id, so
  # the wrapper dispatches the open event to the dialog within it via
  # `{:inner, "dialog"}` (PSB doesn't substitute :variation_id into component attrs).
  def template do
    """
    <div class="flex min-h-48 items-center justify-center p-8" psb-code-hidden>
      <div
        phx-click={Phoenix.LiveView.JS.dispatch("pulsar:modal-open", to: {:inner, "dialog"})}
        class="inline-block"
      >
        <button
          type="button"
          class="rounded-field bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-ring"
        >
          Open dialog
        </button>
        <.psb-variation/>
      </div>
    </div>
    """
  end

  def attributes do
    [
      %Attr{
        id: :title,
        type: :string,
        default: nil,
        doc: "The question; wired as the dialog's accessible name"
      },
      %Attr{
        id: :confirm_label,
        type: :string,
        default: "Confirm",
        doc: "Confirm button text"
      },
      %Attr{
        id: :cancel_label,
        type: :string,
        default: "Cancel",
        doc: "Cancel button text"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "elevated",
        doc: "Visual style of the dialog surface"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "danger",
        doc: "Semantic color: tints the panel and colors the Confirm button"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(sm md lg xl),
        default: "md",
        doc: "Max width and interior padding"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the dialog"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, required: true, doc: "The alert message; announced as aria-describedby"}
    ]
  end

  def variations do
    body = "This permanently deletes the record and can't be undone."

    [
      %Variation{
        id: :default,
        description: "Destructive confirm — danger by default",
        attributes: %{title: "Delete account?", confirm_label: "Delete"},
        slots: [body]
      },
      %Variation{
        id: :important_not_destructive,
        description: "Important but non-destructive confirm (primary panel + Confirm button)",
        attributes: %{
          title: "Publish now?",
          variant: "solid",
          color: "primary",
          confirm_label: "Publish"
        },
        slots: ["The post becomes visible to everyone immediately."]
      },
      %Variation{
        id: :outline_danger,
        description: "Outline danger surface",
        attributes: %{
          title: "Delete project?",
          variant: "outline",
          color: "danger",
          confirm_label: "Delete"
        },
        slots: [body]
      },
      %Variation{
        id: :large,
        description: "Large dialog",
        attributes: %{title: "Remove all members?", size: "xl", confirm_label: "Remove all"},
        slots: [body]
      }
    ]
  end
end
