defmodule Pulsar.Components.RadioGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import Pulsar.Components.RadioGroup

  alias Phoenix.HTML.FormField

  describe "radio_group/1 basic functionality" do
    test "renders radio group with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic Plan</.radio_option>
          <.radio_option value="pro">Pro Plan</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(role="radiogroup")
      assert html =~ ~s(data-name="plan")
      assert html =~ ~s(data-value="basic")
      assert html =~ ~s(data-layout="default")
      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-color="primary")
      assert html =~ ~s(data-size="md")
    end

    test "renders radio options with proper structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic Plan</.radio_option>
          <.radio_option value="pro">Pro Plan</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(type="radio")
      assert html =~ ~s(value="basic")
      assert html =~ ~s(value="pro")
      assert html =~ "Basic Plan"
      assert html =~ "Pro Plan"
    end

    test "applies default styling classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      # Check for base CSS variables
      assert html =~ "--radio-color:"
      assert html =~ "--radio-color-foreground:"
      assert html =~ "--radio-border:"
      assert html =~ "--radio-background:"

      # Check for layout classes
      assert html =~ "flex flex-col gap-4"
    end

    test "renders with custom ID" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group id="my-radio-group" name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(id="my-radio-group")
    end

    test "generates auto ID when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~r/id="radio-group-[^"]+"/
    end
  end

  describe "radio_group/1 layout variants" do
    test "renders default layout vertically" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="default">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ "flex flex-col gap-4"
      assert html =~ ~s(data-layout="default")
    end

    test "renders default layout horizontally" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="default" orientation="horizontal">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ "flex flex-row gap-6"
      assert html =~ ~s(data-orientation="horizontal")
    end

    test "renders cards layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="cards">
          <.radio_option value="basic">
            <div>Basic Plan</div>
            <div>Description here</div>
          </.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-layout="cards")
      assert html =~ "flex flex-col gap-4"
    end

    test "renders grid layout with columns" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="grid" columns={3}>
          <.radio_option value="basic">Basic</.radio_option>
          <.radio_option value="pro">Pro</.radio_option>
          <.radio_option value="enterprise">Enterprise</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-layout="grid")
      assert html =~ ~s(data-columns="3")
      assert html =~ "grid gap-4"
      assert html =~ "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
    end

    test "renders flex layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="flex">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-layout="flex")
      assert html =~ "flex flex-col gap-4"
    end
  end

  describe "radio_group/1 variant styles" do
    test "renders solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" variant="solid">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="solid")
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" variant="outline">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="outline")
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" variant="ghost">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="ghost")
    end
  end

  describe "radio_group/1 color variants" do
    test "renders primary color by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-color="primary")
    end

    test "renders different color variants" do
      colors = ["neutral", "primary", "secondary", "success", "danger", "warning", "info"]

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.radio_group name="plan" value="basic" color={@color}>
            <.radio_option value="basic">Basic</.radio_option>
          </.radio_group>
          """)

        assert html =~ ~s(data-color="#{color}")
      end
    end
  end

  describe "radio_group/1 size variants" do
    test "renders medium size by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-size="md")
    end

    test "renders different size variants" do
      sizes = ["xs", "sm", "md", "lg", "xl"]

      for size <- sizes do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.radio_group name="plan" value="basic" size={@size}>
            <.radio_option value="basic">Basic</.radio_option>
          </.radio_group>
          """)

        assert html =~ ~s(data-size="#{size}")
      end
    end
  end

  describe "radio_group/1 state handling" do
    test "renders with disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" disabled={true}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(aria-disabled="true")
    end

    test "renders with enabled state by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-disabled="false")
      refute html =~ ~s(aria-disabled)
    end

    test "renders with required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" required={true}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(aria-required="true")
      assert html =~ ~s(data-required="true")
    end

    test "renders with invalid state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" invalid={true}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "radio_group/1 error handling" do
    test "renders error message with proper ARIA associations" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group
          id="plan-group"
          name="plan"
          value=""
          invalid={true}
          error_message="Please select a plan"
        >
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      # Check error message is rendered
      assert html =~ "Please select a plan"

      # Check error element has proper ARIA attributes
      assert html =~ ~s(role="alert")
      assert html =~ ~s(id="plan-group-error")

      # Check wrapper has aria-describedby pointing to error element
      assert html =~ ~s(aria-describedby="plan-group-error")

      # Verify invalid attributes are also present
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-invalid="true")
    end

    test "changes color to danger when invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" color="primary" invalid={true}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-color="danger")
      refute html =~ ~s(data-color="primary")
    end

    test "handles nil/empty error message gracefully" do
      assigns = %{}

      # Test with nil error message
      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" invalid={true} error_message={nil}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      # Should have invalid attributes but no error message or aria-describedby
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-invalid="true")
      refute html =~ ~s(aria-describedby)
      refute html =~ ~s(role="alert")

      # Test with empty string error message
      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" invalid={true} error_message="">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      # Empty string should behave same as nil
      assert html =~ ~s(aria-invalid="true")
      refute html =~ ~s(aria-describedby)
      refute html =~ ~s(role="alert")
    end
  end

  describe "radio_group/1 Phoenix form integration" do
    test "integrates with Phoenix form field for automatic validation" do
      # Create a form field with errors
      form_field = %FormField{
        errors: [{"can't be blank", []}],
        field: :plan,
        form: nil,
        id: "user_plan",
        name: "user[plan]",
        value: nil
      }

      assigns = %{form_field: form_field}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@form_field}>
          <.radio_option value="basic">Basic</.radio_option>
          <.radio_option value="pro">Pro</.radio_option>
        </.radio_group>
        """)

      # Should extract name and value from field
      assert html =~ ~s(data-name="user[plan]")
      assert html =~ ~s(id="user_plan")

      # Should detect invalid state from field errors
      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-color="danger")

      # Should generate error message from field errors (HTML escaped)
      assert html =~ "can&#39;t be blank"
      assert html =~ ~s(aria-describedby="user_plan-error")
      assert html =~ ~s(role="alert")
    end

    test "manual invalid prop overrides form field detection" do
      # Form field without errors
      form_field = %FormField{
        errors: [],
        field: :plan,
        form: nil,
        id: "user_plan",
        name: "user[plan]",
        value: "basic"
      }

      assigns = %{form_field: form_field}

      # Manually set invalid to true even though field has no errors
      html =
        rendered_to_string(~H"""
        <.radio_group field={@form_field} invalid={true} error_message="Custom error">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "Custom error"
    end
  end

  describe "radio_group/1 special features" do
    test "renders with hide_radios option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" hide_radios={true}>
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-hide-radios="true")
    end

    test "passes through custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" class="custom-radio-group">
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ "custom-radio-group"
    end

    test "passes through ARIA attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group
          name="plan"
          value="basic"
          aria-label="Choose a subscription plan"
          aria-labelledby="plan-heading"
        >
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(aria-label="Choose a subscription plan")
      assert html =~ ~s(aria-labelledby="plan-heading")
    end

    test "passes through data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group
          name="plan"
          value="basic"
          data-test-id="plan-selector"
        >
          <.radio_option value="basic">Basic</.radio_option>
        </.radio_group>
        """)

      assert html =~ ~s(data-test-id="plan-selector")
    end
  end

  describe "radio_option/1" do
    test "renders radio option with proper structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_option value="basic">Basic Plan</.radio_option>
        """)

      assert html =~ ~s(type="radio")
      assert html =~ ~s(value="basic")
      assert html =~ "Basic Plan"
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_option value="basic" class="custom-option">Basic</.radio_option>
        """)

      assert html =~ "custom-option"
    end

    test "renders with disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_option value="basic" disabled={true}>Basic</.radio_option>
        """)

      assert html =~ ~s(disabled)
    end

    test "generates unique ID for each option" do
      assigns = %{}

      html1 =
        rendered_to_string(~H"""
        <.radio_option value="basic">Basic</.radio_option>
        """)

      html2 =
        rendered_to_string(~H"""
        <.radio_option value="pro">Pro</.radio_option>
        """)

      # Extract IDs from both HTML strings
      [id1] = Regex.run(~r/id="([^"]+)"/, html1, capture: :all_but_first)
      [id2] = Regex.run(~r/id="([^"]+)"/, html2, capture: :all_but_first)

      refute id1 == id2
    end

    test "has proper label association" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_option value="basic">Basic Plan</.radio_option>
        """)

      # Extract ID from input
      [radio_id] = Regex.run(~r/id="([^"]+)"/, html, capture: :all_but_first)

      # Check that label has matching for attribute
      assert html =~ ~s(for="#{radio_id}")
    end
  end
end
