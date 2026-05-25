defmodule Pulsar.DevApp.Storybook.Components.FlashGroup do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.FlashGroup

  def function, do: &FlashGroup.flash_group/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :flash,
        type: :map,
        required: true,
        doc: "Flash messages map from Phoenix.Flash"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant applied to all flashes in group"
      },
      %Attr{
        id: :position,
        type: :string,
        values: ~w(top-right top-center top-left bottom-right bottom-center bottom-left),
        default: "top-right",
        doc: "Screen position for the flash group"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(sm md lg),
        default: "md",
        doc: "Size applied to all flashes in group"
      },
      %Attr{
        id: :dismissible,
        type: :boolean,
        default: true,
        doc: "Show close buttons on all flashes"
      },
      %Attr{
        id: :auto_dismiss,
        type: :boolean,
        default: true,
        doc: "Enable auto-dismiss for all flashes in group"
      },
      %Attr{
        id: :max_items,
        type: :integer,
        default: 5,
        doc: "Maximum number of flashes to display"
      },
      %Attr{
        id: :stagger_delay,
        type: :integer,
        default: 100,
        doc: "Milliseconds between staggered flash animations (0 to disable)"
      },
      %Attr{
        id: :dismiss_after,
        type: :integer,
        default: 5000,
        doc: "Default dismiss timeout in milliseconds"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the container"
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty flash group (no messages)",
        attributes: %{
          flash: %{}
        }
      },
      %Variation{
        id: :single_info,
        description: "Single info flash message",
        attributes: %{
          flash: %{"info" => "Profile updated successfully."},
          auto_dismiss: false
        }
      },
      %Variation{
        id: :single_error,
        description: "Single error flash message",
        attributes: %{
          flash: %{"error" => "Something went wrong."},
          auto_dismiss: false
        }
      },
      %Variation{
        id: :multiple_messages,
        description: "Multiple flash messages together",
        attributes: %{
          flash: %{
            "info" => "Settings saved.",
            "error" => "Email delivery failed."
          },
          auto_dismiss: false
        }
      },
      %Variation{
        id: :outline_variant,
        description: "Outline variant",
        attributes: %{
          flash: %{"info" => "Sync complete."},
          variant: "outline",
          auto_dismiss: false
        }
      },
      %Variation{
        id: :top_center_position,
        description: "Centered at top",
        attributes: %{
          flash: %{"info" => "Changes autosaved."},
          position: "top-center",
          auto_dismiss: false
        }
      },
      %Variation{
        id: :auto_dismiss_default,
        description: "Default auto-dismiss behavior (dismisses after 5 seconds)",
        attributes: %{
          flash: %{"info" => "This message will auto-dismiss in 5 seconds."}
        }
      }
    ]
  end
end
