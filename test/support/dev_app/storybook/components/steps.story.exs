defmodule Pulsar.DevApp.Storybook.Components.Steps do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Steps

  def function, do: &Steps.steps/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "How completed/current markers are drawn"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Accent for completed/current steps and connectors"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Marker and text scale"
      },
      %Attr{
        id: :orientation,
        type: :string,
        values: ~w(horizontal vertical),
        default: "horizontal",
        doc: "horizontal = marker above label; vertical = marker left of label"
      },
      %Attr{
        id: :marker,
        type: :string,
        values: ~w(number dot),
        default: "number",
        doc: "Marker glyph style"
      },
      %Attr{
        id: :connector,
        type: :string,
        values: ~w(solid dashed),
        default: "solid",
        doc: "Connector line style"
      },
      %Attr{
        id: :current,
        type: :integer,
        default: 1,
        doc: "1-based index of the current step"
      }
    ]
  end

  def slots do
    [%Slot{id: :step, required: true, doc: "A single step"}]
  end

  def variations do
    steps = [
      ~s|<:step label="Cart" description="3 items"></:step>|,
      ~s|<:step label="Shipping"></:step>|,
      ~s|<:step label="Payment"></:step>|,
      ~s|<:step label="Review"></:step>|
    ]

    [
      %Variation{
        id: :default,
        description: "Step 2 of 4",
        attributes: %{current: 2, aria_label: "Checkout progress"},
        slots: steps
      },
      %Variation{
        id: :completed,
        description: "All steps complete",
        attributes: %{current: 4, color: "success", aria_label: "Completed checkout"},
        slots: steps
      },
      %Variation{
        id: :error,
        description: "Failed payment",
        attributes: %{current: 3, aria_label: "Checkout with error"},
        slots: [
          ~s|<:step label="Cart" description="3 items"></:step>|,
          ~s|<:step label="Shipping"></:step>|,
          ~s|<:step label="Payment" state="error"></:step>|,
          ~s|<:step label="Review"></:step>|
        ]
      },
      %Variation{
        id: :vertical,
        description: "Vertical onboarding",
        attributes: %{current: 2, orientation: "vertical", aria_label: "Onboarding"},
        slots: [
          ~s|<:step label="Create account" description="Email & password"></:step>|,
          ~s|<:step label="Invite your team" description="Add teammates"></:step>|,
          ~s|<:step label="Connect a repo" description="GitHub or GitLab"></:step>|
        ]
      }
    ]
  end
end
