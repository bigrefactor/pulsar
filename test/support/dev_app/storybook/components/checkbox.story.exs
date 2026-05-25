defmodule Pulsar.DevApp.Storybook.Components.Checkbox do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Checkbox

  def function, do: &Checkbox.checkbox/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :card,
        type: :boolean,
        default: false,
        doc: "Render as a clickable card layout"
      },
      %Attr{
        id: :hide_checkbox,
        type: :boolean,
        default: false,
        doc: "Hide the checkbox input (useful for card-only selection interfaces)"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant (applies to card when card=true)"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Color scheme of the checkbox"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the checkbox"
      },
      %Attr{
        id: :name,
        type: :string,
        default: nil,
        doc: "Checkbox name"
      },
      %Attr{
        id: :value,
        type: :string,
        default: "true",
        doc: "Value when checkbox is checked"
      },
      %Attr{
        id: :checked,
        type: :boolean,
        default: false,
        doc: "Checkbox checked state"
      },
      %Attr{
        id: :indeterminate,
        type: :boolean,
        default: false,
        doc: "Tri-state checkbox support"
      },
      %Attr{
        id: :required,
        type: :boolean,
        default: false,
        doc: "Mark checkbox as required"
      },
      %Attr{
        id: :disabled,
        type: :boolean,
        default: false,
        doc: "Disable the checkbox"
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
      %Slot{id: :inner_block, doc: "Main content for card variant"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default unchecked checkbox",
        attributes: %{name: "accept"}
      },
      %Variation{
        id: :checked,
        description: "Checked checkbox",
        attributes: %{name: "accept", checked: true}
      },
      %Variation{
        id: :primary_color,
        description: "Primary colored checkbox",
        attributes: %{name: "newsletter", color: "primary", checked: true}
      },
      %Variation{
        id: :indeterminate,
        description: "Indeterminate tri-state",
        attributes: %{name: "select_all", indeterminate: true, color: "primary"}
      },
      %Variation{
        id: :disabled,
        description: "Disabled checkbox",
        attributes: %{name: "disabled_option", disabled: true}
      },
      %Variation{
        id: :invalid,
        description: "Invalid/error state",
        attributes: %{name: "required_field", invalid: true}
      },
      %Variation{
        id: :size_lg,
        description: "Large checkbox",
        attributes: %{name: "large_option", size: "lg", color: "primary"}
      }
    ]
  end
end
