defmodule Pulsar.Components.RadioGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import Pulsar.Components.RadioGroup

  describe "radio_group/1 basic functionality" do
    test "renders radio group with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      assert html =~ ~s(role="radiogroup")
      assert html =~ ~s(name="plan")
      assert html =~ ~s(value="basic")
      # Check for layout classes
      assert html =~ "flex flex-col gap-3"
    end

    test "renders radio options with proper structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      assert html =~ ~s(type="radio")
      assert html =~ ~s(value="basic")
      assert html =~ ~s(value="pro")
      assert html =~ ~s(name="plan")
      assert html =~ "Basic Plan"
      assert html =~ "Pro Plan"
    end

    test "applies default styling classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Check for primary color classes in the radio input
      assert html =~ "checked:border-primary"
      assert html =~ "checked:bg-primary"
      # Check for default size classes
      assert html =~ "w-5 h-5"
      # Check for base classes
      assert html =~ "appearance-none"
      assert html =~ "rounded-full"
    end

    test "follows the motion contract across input, dot, label, and card" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Input: micro surface
      assert html =~ "transition-[color,background-color,border-color,box-shadow]"
      # Dot: indicator pop, now with ease-standard
      assert html =~ "before:transition-[transform,opacity]"
      assert html =~ "before:duration-fast"
      assert html =~ "before:ease-standard"
      # Label: text color
      assert html =~ "transition-colors"
      assert html =~ "duration-fast"
      refute html =~ "transition-all"
      refute html =~ "duration-normal"

      card =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card>
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      assert card =~ "transition-[color,background-color,border-color,box-shadow]"
      assert card =~ "duration-fast"
      refute card =~ "transition-all"
      refute card =~ "duration-normal"
    end
  end

  describe "radio_group/1 card style" do
    test "renders card style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card>
          <:option value="basic">
            <div>Basic Plan</div>
            <div>Description here</div>
          </:option>
        </.radio_group>
        """)

      # Card should be rendered as a label
      assert html =~ ~s(<label)
      assert html =~ "rounded-box border-2"
      assert html =~ "cursor-pointer"
      # Should have padding classes
      assert html =~ "p-4 gap-3"
    end

    test "renders solid variant on cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card variant="solid">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Solid variant classes
      assert html =~ "border-transparent"
      assert html =~ "bg-background"
      assert html =~ "hover:bg-primary/10"
    end

    test "renders outline variant on cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card variant="outline">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Outline variant classes
      assert html =~ "border-border"
      assert html =~ "hover:border-primary/50"
      assert html =~ "hover:bg-primary/5"
    end
  end

  describe "radio_group/1 color variants" do
    test "renders primary color by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "checked:border-primary"
      assert html =~ "checked:bg-primary"
      assert html =~ "focus-visible:ring-primary"
    end

    test "renders danger color when invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" invalid>
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Should use danger color when invalid
      assert html =~ "checked:border-danger"
      assert html =~ "checked:bg-danger"
      assert html =~ "focus-visible:ring-danger"
    end
  end

  describe "radio_group/1 size variants" do
    test "renders medium size by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "w-5 h-5"
      assert html =~ "before:inset-1"
    end

    test "renders different sizes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" size="lg">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "w-6 h-6"
      assert html =~ "before:inset-1.5"
    end
  end

  describe "radio_group/1 Phoenix form integration" do
    test "integrates with Phoenix form field for automatic validation" do
      form_data = %{"plan" => ""}

      changeset =
        {form_data, %{plan: :string}}
        |> Ecto.Changeset.cast(%{}, [:plan])
        |> Ecto.Changeset.validate_required([:plan], message: "can't be blank")

      # Apply action returns {:error, changeset} for invalid changesets
      changeset =
        case Ecto.Changeset.apply_action(changeset, :validate) do
          {:ok, _data} -> changeset
          {:error, changeset_with_errors} -> changeset_with_errors
        end

      form = Phoenix.Component.to_form(changeset, as: "user")
      field = form[:plan]

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}>
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      assert html =~ ~s(name="user[plan]")
      # Should automatically use danger color due to validation errors
      assert html =~ "checked:border-danger"
      # Verify invalid state is set correctly
      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "radio_group/1 special features" do
    test "renders with hide_radios option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" hide_radios>
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "sr-only"
    end

    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" disabled>
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(disabled)
    end
  end

  describe "radio_group/1 name and value presence behavior" do
    test "uses explicit name and value when provided as empty string" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="" value="">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Should use empty string, not fall back to field
      assert html =~ ~s(name="")
      assert html =~ ~s(data-name="")
    end

    test "falls back to field when name and value are nil" do
      form_data = %{"plan" => "pro"}
      changeset = {form_data, %{plan: :string}} |> Ecto.Changeset.cast(%{plan: "pro"}, [:plan])
      form = Phoenix.Component.to_form(changeset, as: "user")
      field = form[:plan]

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}>
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Should fall back to field-derived name and value
      assert html =~ ~s(name="user[plan]")
      assert html =~ ~s(value="pro")
    end

    test "respects explicit name over field" do
      form_data = %{"plan" => "pro"}
      changeset = {form_data, %{plan: :string}} |> Ecto.Changeset.cast(%{plan: "pro"}, [:plan])
      form = Phoenix.Component.to_form(changeset, as: "user")
      field = form[:plan]

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field} name="custom_name">
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Should use explicit name, not field-derived
      assert html =~ ~s(name="custom_name")
    end

    test "respects explicit value over field" do
      form_data = %{"plan" => "pro"}
      changeset = {form_data, %{plan: :string}} |> Ecto.Changeset.cast(%{plan: "pro"}, [:plan])
      form = Phoenix.Component.to_form(changeset, as: "user")
      field = form[:plan]

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field} value="custom_value">
          <:option value="basic">Basic</:option>
          <:option value="custom_value">Custom</:option>
        </.radio_group>
        """)

      # Should use explicit value and mark correct option as checked
      assert html =~ ~s(value="custom_value")
      # The custom value should be marked as checked (radio group value matches option value)
      assert html =~ "checked"
    end
  end

  describe "radio_group/1 label_color option" do
    test "uses neutral color by default for labels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" color="primary">
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Label should use neutral text colors by default
      assert html =~ "text-foreground"
    end

    test "inherits radio color when label_color is inherit" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" color="primary" label_color="inherit">
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Label should inherit primary color
      assert html =~ "text-primary"
    end

    test "inherits danger color when invalid and label_color is inherit" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" color="primary" label_color="inherit" invalid>
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Label should inherit danger color due to invalid state
      assert html =~ "text-danger"
    end

    test "uses different inherit colors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" color="success" label_color="inherit">
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Label should inherit success color
      assert html =~ "text-success"
    end
  end

  describe "radio_group/1 hide_radios accessibility" do
    test "content is not aria-hidden in card mode with hide_radios" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card hide_radios>
          <:option value="basic">
            <div>Basic Plan</div>
            <div>Description here</div>
          </:option>
        </.radio_group>
        """)

      # Content div should NOT have aria-hidden
      refute html =~ ~s(aria-hidden="true") && html =~ "Basic Plan"
      # Radio input should have sr-only
      assert html =~ "sr-only"
      # Content should be properly labeled
      assert html =~ ~s(id=") && html =~ ~s(-content")
    end

    test "radio inputs have sr-only when hide_radios in standard mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" hide_radios>
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Radio input should have sr-only
      assert html =~ "sr-only"
      # Label should still be visible
      assert html =~ "Basic Plan"
      refute html =~ ~s(aria-hidden="true")
    end
  end

  describe "radio_group/1 data attributes" do
    test "card labels have data-checked and data-disabled attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card>
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      # Should have data-checked="true" on selected option
      assert html =~ ~s(data-checked="true") && html =~ "Basic Plan"
      # Should have data-checked="false" on unselected option
      assert html =~ ~s(data-checked="false") && html =~ "Pro Plan"
      # Should have data-disabled="false" by default
      assert html =~ ~s(data-disabled="false")
    end

    test "data-checked reflects current state correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="pro" card>
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      # Pro should be checked, Basic should not be
      assert html =~ ~s(data-checked="false") && html =~ "Basic Plan"
      assert html =~ ~s(data-checked="true") && html =~ "Pro Plan"
    end

    test "data-disabled reflects disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card disabled>
          <:option value="basic">Basic Plan</:option>
        </.radio_group>
        """)

      # Should have data-disabled="true" when disabled
      assert html =~ ~s(data-disabled="true")
    end

    test "individual option disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card>
          <:option value="basic">Basic Plan</:option>
          <:option value="pro" disabled>Pro Plan</:option>
        </.radio_group>
        """)

      # Basic should not be disabled, Pro should be
      assert html =~ ~s(data-disabled="false") && html =~ "Basic Plan"
      assert html =~ ~s(data-disabled="true") && html =~ "Pro Plan"
    end
  end

  describe "radio_group/1 accessibility (ARIA)" do
    test "renders role=\"radiogroup\" on the container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~r/<div[^>]*role="radiogroup"/
    end

    test "forwards aria-labelledby to the container via the global rest attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" aria-labelledby="plan-label">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(aria-labelledby="plan-label")
    end

    test "checks the radio matching the group value (native aria-checked propagation)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="pro">
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Native <input type="radio"> derives aria-checked from the `checked` attribute.
      # Require whitespace around `checked` to avoid matching Tailwind's `checked:` variant in class strings.
      assert html =~ ~r/value="pro"[^>]*\schecked\s/
      refute html =~ ~r/value="basic"[^>]*\schecked\s/
    end

    test "applies aria_label attr to the radiogroup container (default variant)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" aria_label="Choose a plan">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~r/<div[^>]*role="radiogroup"[^>]*aria-label="Choose a plan"/
    end

    test "applies aria_labelledby attr to the radiogroup container (default variant)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" aria_labelledby="plan-label">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~r/<div[^>]*role="radiogroup"[^>]*aria-labelledby="plan-label"/
    end

    test "applies aria_labelledby attr to the radiogroup container (card variant) and not to option labels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card aria_labelledby="plan-label">
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      # The radiogroup container must carry the group's label.
      assert html =~ ~r/<div[^>]*role="radiogroup"[^>]*aria-labelledby="plan-label"/

      # No <label> element should carry aria-labelledby — the group label
      # belongs on the container, not on individual option labels.
      refute html =~ ~r/<label[^>]*aria-labelledby="plan-label"/
    end

    test "attaches the .PulsarRadioGroup hook to the radiogroup container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~r/<div[^>]*role="radiogroup"[^>]*phx-hook="Pulsar\.Components\.RadioGroup\.PulsarRadioGroup"/
    end
  end
end
