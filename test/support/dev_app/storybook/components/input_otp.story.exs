defmodule Pulsar.DevApp.Storybook.Components.InputOtp do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.InputOtp

  def function, do: &InputOtp.input_otp/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(outline solid ghost),
        default: "outline",
        doc: "Visual style of the slots"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Active-slot focus accent"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Slot size"
      },
      %Attr{
        id: :length,
        type: :integer,
        default: 6,
        doc: "Number of code characters"
      },
      %Attr{
        id: :mode,
        type: :string,
        values: ~w(numeric alphanumeric),
        default: "numeric",
        doc: "Allowed character set"
      },
      %Attr{
        id: :mask,
        type: :boolean,
        default: false,
        doc: "Mask entered characters as dots"
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
        id: :outline,
        description: "Outline (default)",
        attributes: %{id: "sb-otp-outline", length: 6}
      },
      %Variation{
        id: :solid,
        description: "Solid",
        attributes: %{id: "sb-otp-solid", variant: "solid", length: 6}
      },
      %Variation{
        id: :ghost,
        description: "Ghost (underline)",
        attributes: %{id: "sb-otp-ghost", variant: "ghost", length: 6}
      },
      %Variation{
        id: :primary_color,
        description: "Primary accent",
        attributes: %{id: "sb-otp-primary", color: "primary", length: 6}
      },
      %Variation{
        id: :grouped,
        description: "Grouped 3-3",
        attributes: %{id: "sb-otp-grouped", length: 6, groups: [3, 3]}
      },
      %Variation{
        id: :masked,
        description: "Masked PIN",
        attributes: %{id: "sb-otp-masked", length: 4, mask: true}
      },
      %Variation{
        id: :alphanumeric,
        description: "Alphanumeric",
        attributes: %{id: "sb-otp-alpha", length: 6, mode: "alphanumeric"}
      }
    ]
  end
end
