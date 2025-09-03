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
      assert html =~ "flex flex-col gap-4"
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
      assert html =~ "rounded-lg border-2"
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
      assert html =~ ~s(id="user_plan")
      # Should automatically use danger color due to validation errors
      assert html =~ "checked:border-danger"
      assert html =~ "can&#39;t be blank"
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
end
