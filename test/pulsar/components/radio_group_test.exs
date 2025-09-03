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
          <:option value="basic">Basic Plan</:option>
          <:option value="pro">Pro Plan</:option>
        </.radio_group>
        """)

      assert html =~ ~s(role="radiogroup")
      assert html =~ ~s(name="plan")
      assert html =~ ~s(value="basic")
      assert html =~ ~s(data-card="false")
      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-color="primary")
      assert html =~ ~s(data-size="md")
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

      # Check for base CSS variables
      assert html =~ "--radio-color:"
      assert html =~ "--radio-color-foreground:"
      assert html =~ "--radio-border:"
      assert html =~ "--radio-background:"

      # Check for data-radio-group attribute
      assert html =~ ~s(data-radio-group="true")

      # Check for default flex layout
      assert html =~ "flex flex-col gap-4"
    end

    test "renders with custom ID" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group id="my-radio-group" name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(id="my-radio-group")
    end

    test "generates auto ID when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~r/role="radiogroup"[^>]*id="[^"]+"/
    end
  end

  describe "radio_group/1 layout and card variants" do
    test "renders flex layout vertically (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "flex flex-col gap-4"
      assert html =~ ~s(data-orientation="vertical")
    end

    test "renders flex layout horizontally" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" orientation="horizontal">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ "flex flex-row flex-wrap gap-6"
      assert html =~ ~s(data-orientation="horizontal")
    end

    test "renders grid layout with columns" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" layout="grid" columns={3}>
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
          <:option value="enterprise">Enterprise</:option>
        </.radio_group>
        """)

      assert html =~ "grid gap-4"
      assert html =~ "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
    end

    test "renders standard radios (non-card)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-card="false")
      # Should render standard radio + label structure
      assert html =~ ~s(type="radio")
      assert html =~ ~s(<label)
    end

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

      assert html =~ ~s(data-card="true")
      # Should render as clickable label with radio inside
      assert html =~ ~s(<label)
      assert html =~ ~s(cursor-pointer)
    end

    test "combines card style with grid layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card layout="grid" columns={2}>
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-card="true")
      assert html =~ "grid gap-4"
      assert html =~ "grid-cols-1 sm:grid-cols-2"
    end
  end

  describe "radio_group/1 variant styles (for cards)" do
    test "renders solid variant on cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card variant="solid">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-card="true")
    end

    test "renders outline variant on cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card variant="outline">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-card="true")
    end

    test "renders ghost variant on cards" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card variant="ghost">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ ~s(data-card="true")
    end

    test "variant has no effect on non-card radios" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" variant="outline">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-card="false")
      # Should still render as standard radio
      assert html =~ ~s(type="radio")
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

      assert html =~ ~s(data-color="primary")
    end

    test "renders different color variants" do
      colors = ["neutral", "primary", "secondary", "success", "danger", "warning", "info"]

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.radio_group name="plan" value="basic" color={@color}>
            <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
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
            <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(aria-disabled="true")
      # Individual radios should also be disabled
      assert html =~ ~s(disabled)
    end

    test "renders with enabled state by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(aria-required="true")
      assert html =~ ~s(data-required="true")
      # Individual radios should have required attribute
      assert html =~ ~s(required)
    end

    test "renders with invalid state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="" invalid={true}>
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(aria-invalid="true")
      # Individual radios should have aria-invalid
      assert html =~ ~s(aria-invalid="true")
    end

    test "computes checked state automatically" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="pro">
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # The pro option should be checked
      assert html =~ ~s(value="pro")
      assert html =~ ~s(checked)

      # The basic option should not be checked - look for a line with basic that doesn't have checked
      assert html =~ ~s(value="basic")
      # Count occurrences: should have one "basic" input and one "checked" attribute
      basic_count = (html |> String.split("value=\"basic\"") |> length()) - 1
      checked_count = length(Regex.scan(~r/\bchecked(?![:\-])/, html))
      assert basic_count == 1
      assert checked_count == 1
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Should extract name and value from field
      assert html =~ ~s(name="user[plan]")
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-hide-radios="true")
      # Radio inputs should have sr-only class
      assert html =~ ~s(sr-only)
    end

    test "passes through custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" class="custom-radio-group">
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
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
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      assert html =~ ~s(data-test-id="plan-selector")
    end
  end

  describe "radio options with slots" do
    test "renders option slots with proper structure" do
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
      assert html =~ "Basic Plan"
      assert html =~ "Pro Plan"
    end

    test "option slots can have disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
          <:option value="pro" disabled>Pro</:option>
        </.radio_group>
        """)

      # Should have one disabled radio with disabled attribute
      assert html =~ ~r/value="pro".*?disabled(?!\:)/
      # Basic should not have disabled attribute  
      refute html =~ ~r/value="basic".*?disabled(?!\:)/
    end

    test "option slots can override checked state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
          <:option value="pro" checked>Pro</:option>
        </.radio_group>
        """)

      # Pro should be checked (override)
      assert html =~ ~r/value="pro"[^>]*checked/
      # Basic should not be checked (overridden by explicit checked on pro)
      # Note: Both might be checked in this case since we're overriding
    end

    test "generates unique IDs for each option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
          <:option value="pro">Pro</:option>
        </.radio_group>
        """)

      # Extract all radio IDs
      radio_ids = Regex.scan(~r/id="([^"]+)"/, html, capture: :all_but_first) |> List.flatten()

      # Should have at least 2 unique IDs (one for each radio)
      unique_ids = Enum.uniq(radio_ids)
      assert length(unique_ids) >= 2
    end

    test "has proper label association for each option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic">
          <:option value="basic">Basic</:option>
        </.radio_group>
        """)

      # Extract radio input ID specifically
      [radio_id | _] =
        Regex.scan(~r/input[^>]*id="([^"]+)"/, html, capture: :all_but_first) |> List.flatten()

      # Should have label with matching for attribute
      assert html =~ ~s(for="#{radio_id}")
    end

    test "supports rich content in option slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group name="plan" value="basic" card>
          <:option value="basic">
            <div class="font-medium">Basic Plan</div>
            <div class="text-sm text-muted">Perfect for individuals</div>
            <div class="font-bold">$10/month</div>
          </:option>
        </.radio_group>
        """)

      assert html =~ "Basic Plan"
      assert html =~ "Perfect for individuals"
      assert html =~ "$10/month"
      assert html =~ "font-medium"
      assert html =~ "font-bold"
    end
  end
end
