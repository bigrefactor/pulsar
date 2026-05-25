defmodule Pulsar.DevApp.Storybook.Components.Input do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Input

  def function, do: &Input.input/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(outline ghost solid),
        default: "solid",
        doc: "Visual style variant of the input"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the input"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the input"
      },
      %Attr{
        id: :type,
        type: :string,
        default: "text",
        doc: "Input type"
      },
      %Attr{
        id: :name,
        type: :string,
        default: nil,
        doc: "Input name"
      },
      %Attr{
        id: :value,
        type: :string,
        default: nil,
        doc: "Input value"
      },
      %Attr{
        id: :required,
        type: :boolean,
        default: false,
        doc: "Mark input as required"
      },
      %Attr{
        id: :disabled,
        type: :boolean,
        default: false,
        doc: "Disable the input"
      },
      %Attr{
        id: :readonly,
        type: :boolean,
        default: false,
        doc: "Make input read-only"
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

  def slots do
    [
      %Slot{id: :start_decorator, doc: "Leading decorator content (icons, text, buttons)"},
      %Slot{id: :end_decorator, doc: "Trailing decorator content (icons, text, buttons)"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default text input",
        attributes: %{name: "username", placeholder: "Enter username"}
      },
      %Variation{
        id: :outline_variant,
        description: "Outline variant",
        attributes: %{name: "email", type: "email", variant: "outline", placeholder: "you@example.com"}
      },
      %Variation{
        id: :ghost_variant,
        description: "Ghost variant",
        attributes: %{name: "search", type: "search", variant: "ghost", placeholder: "Search…"}
      },
      %Variation{
        id: :primary_color,
        description: "Primary color",
        attributes: %{name: "name", color: "primary", placeholder: "Full name"}
      },
      %Variation{
        id: :with_value,
        description: "Input with pre-filled value",
        attributes: %{name: "email", type: "email", value: "user@example.com"}
      },
      %Variation{
        id: :invalid_state,
        description: "Invalid/error state",
        attributes: %{name: "email", type: "email", invalid: true, value: "not-an-email"}
      },
      %Variation{
        id: :disabled_state,
        description: "Disabled input",
        attributes: %{name: "locked", disabled: true, value: "read only"}
      },
      %Variation{
        id: :size_lg,
        description: "Large size input",
        attributes: %{name: "search", size: "lg", placeholder: "Large search input"}
      }
    ]
  end
end
