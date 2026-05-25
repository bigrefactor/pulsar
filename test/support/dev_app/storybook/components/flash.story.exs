defmodule Pulsar.DevApp.Storybook.Components.Flash do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Flash

  def function, do: &Flash.flash/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant of the flash"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the flash"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(sm md lg),
        default: "md",
        doc: "Size of the flash notification"
      },
      %Attr{
        id: :dismissible,
        type: :boolean,
        default: true,
        doc: "Show close button for manual dismissal"
      },
      %Attr{
        id: :auto_dismiss,
        type: :boolean,
        default: true,
        doc: "Automatically dismiss after timeout"
      },
      %Attr{
        id: :dismiss_after,
        type: :integer,
        default: 5000,
        doc: "Milliseconds before auto-dismiss"
      },
      %Attr{
        id: :role,
        type: :string,
        values: ~w(alert status),
        default: "status",
        doc: "ARIA role"
      },
      %Attr{
        id: :flash_key,
        type: :string,
        default: nil,
        doc: "Phoenix.Flash key to read from"
      },
      %Attr{
        id: :live,
        type: :string,
        values: ~w(polite assertive off auto),
        default: "polite",
        doc: "ARIA live region behavior (auto-determined from role if not specified)"
      },
      %Attr{
        id: :id,
        type: :string,
        default: nil,
        doc: "Flash ID"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, doc: "Flash message content"},
      %Slot{id: :start_icon, doc: "Icon shown at the start of the flash message"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :success,
        description: "Success flash notification",
        attributes: %{
          id: "flash-success",
          color: "success",
          auto_dismiss: false
        },
        slots: ["Changes saved successfully!"]
      },
      %Variation{
        id: :danger,
        description: "Danger/error flash notification",
        attributes: %{
          id: "flash-danger",
          color: "danger",
          role: "alert",
          auto_dismiss: false
        },
        slots: ["Something went wrong. Please try again."]
      },
      %Variation{
        id: :warning,
        description: "Warning flash notification",
        attributes: %{
          id: "flash-warning",
          color: "warning",
          auto_dismiss: false
        },
        slots: ["Your session expires in 5 minutes."]
      },
      %Variation{
        id: :info,
        description: "Info flash notification",
        attributes: %{
          id: "flash-info",
          color: "info",
          auto_dismiss: false
        },
        slots: ["A new version is available."]
      },
      %Variation{
        id: :outline_success,
        description: "Outline variant success",
        attributes: %{
          id: "flash-outline",
          variant: "outline",
          color: "success",
          auto_dismiss: false
        },
        slots: ["Profile updated."]
      },
      %Variation{
        id: :ghost_neutral,
        description: "Ghost variant neutral",
        attributes: %{
          id: "flash-ghost",
          variant: "ghost",
          color: "neutral",
          auto_dismiss: false
        },
        slots: ["Background sync complete."]
      },
      %Variation{
        id: :non_dismissible,
        description: "Non-dismissible flash",
        attributes: %{
          id: "flash-sticky",
          color: "warning",
          dismissible: false,
          auto_dismiss: false
        },
        slots: ["Maintenance window: Saturday 2–4 AM UTC."]
      }
    ]
  end
end
