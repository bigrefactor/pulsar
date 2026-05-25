defmodule Pulsar.DevApp.Storybook.Components.Field do
  # NOTE: Field strictly requires Phoenix.HTML.FormField via the :field attr.
  # We use PSB's template/0 feature to wrap variations in a <.form> context
  # and pass the form field to each variation via <.psb-variation field={...}/>.
  # Every variation uses f[:demo] so labels auto-humanize to "Demo" unless
  # overridden by a <:label> slot.
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Field

  def function, do: &Field.field/1
  def render_source, do: :function

  # Wrap all variations in a Phoenix form so each gets a real FormField.
  def template do
    """
    <.form :let={f} for={%{}} as={:demo} class="space-y-4 w-full" psb-code-hidden>
      <.psb-variation field={f[:demo]}/>
    </.form>
    """
  end

  def attributes do
    [
      # :field is always injected by the story template — not listed here
      # to avoid PSB's required-attr validation requiring it in every variation.
      %Attr{
        id: :type,
        type: :string,
        values:
          ~w(text email password number tel url search date time datetime-local month week color file range select textarea checkbox radio switch),
        default: "text",
        doc: "Input type — determines which component to render"
      },
      %Attr{
        id: :variant,
        type: :string,
        default: "outline",
        doc: "Visual variant (outline, solid, ghost)"
      },
      %Attr{
        id: :color,
        type: :string,
        default: "neutral",
        doc: "Color theme"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Input size"
      },
      %Attr{
        id: :placeholder,
        type: :string,
        default: nil,
        doc: "Placeholder text"
      },
      %Attr{
        id: :required,
        type: :boolean,
        default: false,
        doc: "Mark field as required"
      },
      %Attr{
        id: :disabled,
        type: :boolean,
        default: false,
        doc: "Disable the field"
      },
      %Attr{
        id: :readonly,
        type: :boolean,
        default: false,
        doc: "Make field read-only"
      },
      %Attr{
        id: :options,
        type: :list,
        default: nil,
        doc: "Options for select/radio (list or keyword list)"
      },
      %Attr{
        id: :rows,
        type: :integer,
        default: 4,
        doc: "Number of rows for textarea"
      },
      %Attr{
        id: :show_errors,
        type: :atom,
        values: [:touched, :always, :never],
        default: :touched,
        doc: "When to show errors: :touched (default), :always, :never"
      },
      %Attr{
        id: :prompt,
        type: :string,
        default: nil,
        doc: "Prompt option for select"
      },
      %Attr{
        id: :checked,
        type: :boolean,
        default: nil,
        doc: "Checked state (checkbox/switch)"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for field wrapper"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :label, doc: "Custom label content (auto-generated from field name if not provided)"},
      %Slot{id: :description, doc: "Help text displayed below the label"},
      %Slot{id: :start_decorator, doc: "Leading decorator (passed to Input component)"},
      %Slot{id: :end_decorator, doc: "Trailing decorator (passed to Input component)"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :text_input,
        description: "Text input field",
        attributes: %{type: "text"},
        slots: ["<:label>Full Name</:label>", "<:description>Your legal full name</:description>"]
      },
      %Variation{
        id: :email_input,
        description: "Email input field",
        attributes: %{type: "email"},
        slots: ["<:label>Email Address</:label>"]
      },
      %Variation{
        id: :textarea_input,
        description: "Textarea field",
        attributes: %{type: "textarea", rows: 3},
        slots: ["<:label>Bio</:label>", "<:description>Tell us about yourself</:description>"]
      },
      %Variation{
        id: :select_input,
        description: "Select field with options",
        attributes: %{
          type: "select",
          options: [{"Option One", "1"}, {"Option Two", "2"}, {"Option Three", "3"}]
        },
        slots: ["<:label>Choose Option</:label>"]
      },
      %Variation{
        id: :checkbox_input,
        description: "Checkbox field",
        attributes: %{type: "checkbox"},
        slots: ["<:label>Accept Terms</:label>"]
      },
      %Variation{
        id: :switch_input,
        description: "Switch field",
        attributes: %{type: "switch"},
        slots: ["<:label>Enable Notifications</:label>"]
      },
      %Variation{
        id: :required_field,
        description: "Required text field",
        attributes: %{type: "text", required: true},
        slots: ["<:label>Required Field</:label>"]
      },
      %Variation{
        id: :disabled_field,
        description: "Disabled field",
        attributes: %{type: "text", disabled: true},
        slots: ["<:label>Disabled Field</:label>"]
      }
    ]
  end
end
