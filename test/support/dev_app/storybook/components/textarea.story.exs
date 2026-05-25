defmodule Pulsar.DevApp.Storybook.Components.Textarea do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Textarea

  def function, do: &Textarea.textarea/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant of the textarea"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the textarea"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the textarea"
      },
      %Attr{
        id: :name,
        type: :string,
        default: nil,
        doc: "Textarea name"
      },
      %Attr{
        id: :value,
        type: :string,
        default: nil,
        doc: "Textarea value"
      },
      %Attr{
        id: :rows,
        type: :integer,
        default: 4,
        doc: "Number of visible text lines"
      },
      %Attr{
        id: :placeholder,
        type: :string,
        default: nil,
        doc: "Placeholder text"
      },
      %Attr{
        id: :maxlength,
        type: :integer,
        default: nil,
        doc: "Maximum number of characters allowed"
      },
      %Attr{
        id: :show_character_count,
        type: :boolean,
        default: false,
        doc: "Enable character counting display"
      },
      %Attr{
        id: :auto_resize,
        type: :boolean,
        default: false,
        doc: "Enable automatic height adjustment"
      },
      %Attr{
        id: :required,
        type: :boolean,
        default: false,
        doc: "Mark textarea as required"
      },
      %Attr{
        id: :disabled,
        type: :boolean,
        default: false,
        doc: "Disable the textarea"
      },
      %Attr{
        id: :readonly,
        type: :boolean,
        default: false,
        doc: "Make textarea read-only"
      },
      %Attr{
        id: :invalid,
        type: :boolean,
        default: nil,
        doc: "Force invalid state"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes"
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default textarea",
        attributes: %{name: "bio", placeholder: "Tell us about yourself…"}
      },
      %Variation{
        id: :with_value,
        description: "Textarea with pre-filled content",
        attributes: %{
          name: "description",
          value: "This is some pre-filled content for the textarea."
        }
      },
      %Variation{
        id: :outline_variant,
        description: "Outline variant",
        attributes: %{name: "notes", variant: "outline", placeholder: "Add notes…"}
      },
      %Variation{
        id: :with_character_count,
        description: "Textarea with character count",
        attributes: %{
          name: "tweet",
          maxlength: 280,
          show_character_count: true,
          placeholder: "What's happening?",
          rows: 3
        }
      },
      %Variation{
        id: :primary_color,
        description: "Primary colored textarea",
        attributes: %{name: "feedback", color: "primary", placeholder: "Share your feedback…"}
      },
      %Variation{
        id: :disabled_state,
        description: "Disabled textarea",
        attributes: %{name: "readonly_field", disabled: true, value: "This content cannot be edited."}
      },
      %Variation{
        id: :invalid_state,
        description: "Invalid/error state",
        attributes: %{name: "required_notes", invalid: true, placeholder: "This field is required"}
      },
      %Variation{
        id: :large_rows,
        description: "Tall textarea with more rows",
        attributes: %{name: "long_text", rows: 8, placeholder: "Write a longer message…"}
      }
    ]
  end
end
