defmodule Pulsar.Components.CheckboxTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import Pulsar.Components.Checkbox

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField

  describe "checkbox/1 basic functionality" do
    test "renders checkbox with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      assert html =~ ~s(<input)
      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(name="terms")
      assert html =~ ~s(value="true")
    end

    test "renders hidden input by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="false")
    end

    test "applies default styling classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      # Check for base styling
      assert html =~ "appearance-none"
      assert html =~ "cursor-pointer"
      assert html =~ "transition-all"

      # Check for size classes (default is md)
      assert html =~ "h-5"
      assert html =~ "w-5"
      assert html =~ "rounded-md"

      # Check for color classes (default is primary)
      assert html =~ "primary"
    end

    test "raises error when both field and name are missing" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires :field or :name/, fn ->
        rendered_to_string(~H"""
        <.checkbox />
        """)
      end
    end
  end

  describe "checkbox/1 size variants" do
    test "xs size applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" size="xs" />
        """)

      assert html =~ "h-3"
      assert html =~ "w-3"
      assert html =~ "text-[8px]"
    end

    test "sm size applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" size="sm" />
        """)

      assert html =~ "h-4"
      assert html =~ "w-4"
      assert html =~ "text-[10px]"
    end

    test "md size applies correct classes (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" size="md" />
        """)

      assert html =~ "h-5"
      assert html =~ "w-5"
      assert html =~ "text-xs"
    end

    test "lg size applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" size="lg" />
        """)

      assert html =~ "h-6"
      assert html =~ "w-6"
      assert html =~ "text-sm"
    end

    test "xl size applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" size="xl" />
        """)

      assert html =~ "h-7"
      assert html =~ "w-7"
      assert html =~ "text-base"
    end
  end

  describe "checkbox/1 color variants" do
    test "neutral color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="neutral" />
        """)

      assert html =~ "neutral"
      assert html =~ "border-border"
    end

    test "primary color applies correct classes (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="primary" />
        """)

      assert html =~ "primary"
    end

    test "secondary color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="secondary" />
        """)

      assert html =~ "secondary"
    end

    test "success color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="success" />
        """)

      assert html =~ "success"
    end

    test "danger color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="danger" />
        """)

      assert html =~ "danger"
    end

    test "warning color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="warning" />
        """)

      assert html =~ "warning"
    end

    test "info color applies correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" color="info" />
        """)

      assert html =~ "info"
    end
  end

  describe "checkbox/1 state handling" do
    test "handles checked state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" checked={true} />
        """)

      assert html =~ ~s(data-checked="true")
    end

    test "handles indeterminate state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" indeterminate={true} />
        """)

      assert html =~ ~s(data-indeterminate="true")
    end

    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" disabled={true} />
        """)

      assert html =~ ~s(disabled)
      assert html =~ ~s(data-disabled="true")
    end

    test "handles required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" required={true} />
        """)

      assert html =~ ~s(required)
      assert html =~ ~s(data-required="true")
    end
  end

  describe "checkbox/1 Phoenix form integration" do
    test "works with Phoenix form field" do
      form = %Form{
        data: %{},
        hidden: [],
        id: "user",
        impl: Phoenix.HTML.FormData.Map,
        name: "user",
        options: [],
        source: %{}
      }

      field = %FormField{
        errors: [],
        field: :newsletter,
        form: form,
        id: "user_newsletter",
        name: "user[newsletter]",
        value: nil
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      # Stellar handles form field integration - check for field presence
      assert html =~ ~s(type="checkbox")
    end

    test "overrides color when field has errors" do
      form = %Form{
        data: %{},
        hidden: [],
        id: "user",
        impl: Phoenix.HTML.FormData.Map,
        name: "user",
        options: [],
        source: %{}
      }

      field = %FormField{
        errors: [{"is required", [validation: :required]}],
        field: :terms,
        form: form,
        id: "user_terms",
        name: "user[terms]",
        value: nil
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} color="success" />
        """)

      # Should override success color with danger due to errors
      assert html =~ "danger"
      assert html =~ ~s(aria-invalid="true")
    end

    test "respects explicit invalid override" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" invalid={true} />
        """)

      assert html =~ "danger"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "checkbox/1 card layout" do
    test "renders card layout with container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" value="premium">
          <div class="font-medium">Premium Plan</div>
        </.checkbox>
        """)

      assert html =~ ~s(<label)
      assert html =~ "flex items-center"
      assert html =~ "border-2"
      assert html =~ "rounded-lg"
      assert html =~ "Premium Plan"
    end

    test "renders card with content in inner_block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" value="premium">
          <div class="font-medium">Premium Plan</div>
          <div class="text-sm">Advanced features and priority support</div>
          <div class="text-sm font-semibold">$29/month</div>
        </.checkbox>
        """)

      assert html =~ "Premium Plan"
      assert html =~ "Advanced features and priority support"
      assert html =~ "$29/month"
      assert html =~ "font-medium"
      assert html =~ "text-sm"
      assert html =~ "font-semibold"
    end

    test "applies card size classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" size="lg">
          <div class="font-medium">Large Card</div>
        </.checkbox>
        """)

      assert html =~ "p-5"
      assert html =~ "gap-4"
      assert html =~ "text-lg"
    end

    test "applies card variant classes - solid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card variant="solid" name="plan" color="primary">
          <div class="font-medium">Solid Card</div>
        </.checkbox>
        """)

      assert html =~ "primary"
      assert html =~ "border-transparent"
      assert html =~ "hover:shadow-sm"
    end

    test "applies card variant classes - outline" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card variant="outline" name="plan" color="success">
          <div class="font-medium">Outline Card</div>
        </.checkbox>
        """)

      assert html =~ "success"
      assert html =~ "border-success/30"
      assert html =~ "hover:shadow-md"
    end

    test "applies card variant classes - ghost" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card variant="ghost" name="plan" color="secondary">
          <div class="font-medium">Ghost Card</div>
        </.checkbox>
        """)

      assert html =~ "bg-transparent"
      assert html =~ "border-transparent"
      assert html =~ "hover:shadow-sm"
    end

    test "renders card with all content slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" value="premium">
          <div class="font-medium">Premium Plan</div>
          <div class="text-sm text-muted-foreground mt-1">Advanced features and priority support</div>
          <div class="text-sm font-semibold mt-2">$29/month</div>
        </.checkbox>
        """)

      assert html =~ "Premium Plan"
      assert html =~ "Advanced features and priority support"
      assert html =~ "$29/month"
      assert html =~ "font-medium"
      assert html =~ "text-sm"
      assert html =~ "font-semibold"
    end

    test "applies card color classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card variant="outline" name="plan" color="success">
          Success Card
        </.checkbox>
        """)

      assert html =~ "success"
      assert html =~ "border-success/30"
      assert html =~ "hover:border-success"
    end

    test "includes dynamic checked state styling in cards using has selectors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card variant="outline" name="plan" color="primary">
          Dynamic Card
        </.checkbox>
        """)

      # Check that checked state classes use has-[:checked] selectors
      assert html =~ "has-[:checked]:bg-primary/15"
      assert html =~ "has-[:checked]:hover:bg-primary/20"
      assert html =~ "has-[:checked]:border-primary"
      assert html =~ "dark:has-[:checked]:bg-dark-primary/20"
    end
  end

  describe "checkbox/1 accessibility" do
    test "includes proper ARIA attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      refute html =~ ~s(aria-invalid="false")
    end

    test "sets aria-invalid when invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" invalid={true} />
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      assert html =~ "focus-visible:outline-none"
      assert html =~ "focus-visible:ring-2"
      assert html =~ "focus-visible:ring-ring"
    end

    test "includes keyboard interaction classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      assert html =~ "cursor-pointer"
      assert html =~ "disabled:cursor-not-allowed"
    end
  end

  describe "checkbox/1 custom styling" do
    test "merges custom classes with TailwindMerge" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" class="custom-class" />
        """)

      assert html =~ "custom-class"
    end

    test "supports all global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" data-testid="my-checkbox" phx-click="toggle" />
        """)

      assert html =~ ~s(data-testid="my-checkbox")
      assert html =~ ~s(phx-click="toggle")
    end

    test "handles custom value and unchecked_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" value="yes" unchecked_value="no" />
        """)

      assert html =~ ~s(value="yes")

      # Check hidden input has unchecked value
      assert html =~ ~s(value="no")
    end
  end

  describe "checkbox/1 checkmark visualization" do
    test "includes checkmark styling for checked state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      # Check for checkmark content and animation classes (HTML escaped)
      assert html =~ "after:content-[&#39;✓&#39;]"
      assert html =~ "data-[checked=true]:after:scale-100"
      assert html =~ "data-[checked=true]:after:opacity-100"
    end

    test "includes dash styling for indeterminate state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" indeterminate={true} />
        """)

      # Check for dash content in indeterminate state (HTML escaped)
      assert html =~ "data-[indeterminate=true]:after:content-[&#39;−&#39;]"
      assert html =~ "data-[indeterminate=true]:after:scale-100"
      assert html =~ "data-[indeterminate=true]:after:opacity-100"
    end

    test "includes scaling animation classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      assert html =~ "after:scale-0"
      assert html =~ "after:opacity-0"
      assert html =~ "after:transition-all"
      assert html =~ "after:duration-200"
    end
  end
end
