defmodule Pulsar.DevApp.Storybook.Components.Select do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Select

  def function, do: &Select.select/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost),
        default: "solid",
        doc: "Visual style variant of the select"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the select"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Size of the select"
      },
      %Attr{
        id: :name,
        type: :string,
        default: nil,
        doc: "Select name"
      },
      %Attr{
        id: :value,
        type: :any,
        default: nil,
        doc: "Selected value(s)"
      },
      %Attr{
        id: :options,
        type: :list,
        required: true,
        doc: "List of options in Phoenix format"
      },
      %Attr{
        id: :prompt,
        type: :string,
        default: nil,
        doc: "Prompt option text"
      },
      %Attr{
        id: :multiple,
        type: :boolean,
        default: false,
        doc: "Enable multi-select mode"
      },
      %Attr{
        id: :required,
        type: :boolean,
        default: false,
        doc: "Mark select as required"
      },
      %Attr{
        id: :disabled,
        type: :boolean,
        default: false,
        doc: "Disable the select"
      },
      %Attr{
        id: :invalid,
        type: :boolean,
        default: nil,
        doc: "Force invalid state"
      },
      %Attr{
        id: :auto_name_array,
        type: :boolean,
        default: true,
        doc: "Append [] to name when multiple=true"
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
        description: "Default select",
        attributes: %{
          id: "sb-select-country",
          name: "country",
          options: [{"United States", "us"}, {"Canada", "ca"}, {"Mexico", "mx"}]
        }
      },
      %Variation{
        id: :with_prompt,
        description: "Select with placeholder prompt",
        attributes: %{
          id: "sb-select-role",
          name: "role",
          prompt: "Choose a role…",
          options: [{"Admin", "admin"}, {"Editor", "editor"}, {"Viewer", "viewer"}]
        }
      },
      %Variation{
        id: :with_selected_value,
        description: "Select with pre-selected value",
        attributes: %{
          id: "sb-select-plan",
          name: "plan",
          value: "pro",
          options: [{"Starter", "starter"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]
        }
      },
      %Variation{
        id: :outline_variant,
        description: "Outline variant",
        attributes: %{
          id: "sb-select-category",
          name: "category",
          variant: "outline",
          options: [{"Elixir", "elixir"}, {"Phoenix", "phoenix"}, {"LiveView", "liveview"}]
        }
      },
      %Variation{
        id: :primary_color,
        description: "Primary color select",
        attributes: %{
          id: "sb-select-priority",
          name: "priority",
          color: "primary",
          options: [{"High", "high"}, {"Medium", "medium"}, {"Low", "low"}]
        }
      },
      %Variation{
        id: :disabled_state,
        description: "Disabled select",
        attributes: %{
          id: "sb-select-locked",
          name: "locked",
          disabled: true,
          value: "pro",
          options: [{"Starter", "starter"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]
        }
      },
      %Variation{
        id: :invalid_state,
        description: "Invalid/error state",
        attributes: %{
          id: "sb-select-required",
          name: "required_select",
          invalid: true,
          prompt: "Please select an option",
          options: [{"Option A", "a"}, {"Option B", "b"}]
        }
      },
      %Variation{
        id: :multiple,
        description: "Multi-select listbox (no chevron)",
        attributes: %{
          id: "sb-select-skills",
          name: "skills",
          multiple: true,
          options: [{"Elixir", "elixir"}, {"Phoenix", "phoenix"}, {"LiveView", "liveview"}]
        }
      },
      %Variation{
        id: :multiple_with_badges,
        description: "Multi-select with pre-selected removable badges",
        attributes: %{
          id: "sb-select-skills-badges",
          name: "skills_badges",
          multiple: true,
          value: ["elixir", "phoenix"],
          options: [{"Elixir", "elixir"}, {"Phoenix", "phoenix"}, {"LiveView", "liveview"}]
        }
      }
    ]
  end
end
