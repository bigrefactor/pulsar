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
      assert html =~ "rounded-field"

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

    test "hidden input is disabled when checkbox is disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" disabled={true} />
        """)

      # Check that both hidden and checkbox inputs have disabled attribute
      assert html =~ ~r(<input[^>]*type="hidden"[^>]*disabled[^>]*>)
      assert html =~ ~r(<input[^>]*type="checkbox"[^>]*disabled[^>]*>)
    end

    test "hidden input is not disabled when checkbox is not disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" disabled={false} />
        """)

      # Ensure hidden input doesn't have disabled attribute when checkbox is enabled
      refute html =~ ~r(<input[^>]*type="hidden"[^>]*disabled[^>]*>)
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
      assert html =~ "rounded-box"
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
      assert html =~ "hover:shadow-card"
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
      assert html =~ "hover:shadow-dropdown"
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
      assert html =~ "hover:shadow-card"
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
    end

    test "applies container_class to card container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" container_class="custom-container-class">
          <div>Test content</div>
        </.checkbox>
        """)

      assert html =~ "custom-container-class"
    end

    test "applies global attributes to card container in card mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" phx-click="handle_click" data-testid="card-container">
          <div>Test content</div>
        </.checkbox>
        """)

      assert html =~ ~s(phx-click="handle_click")
      assert html =~ ~s(data-testid="card-container")
      # Verify these attributes are on the label (container), not the input
      assert String.contains?(html, ~s(<label)) and String.contains?(html, ~s(phx-click="handle_click"))
    end

    test "card variant hidden input is disabled when checkbox is disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" disabled={true}>
          <div>Test content</div>
        </.checkbox>
        """)

      # Check that both hidden and checkbox inputs have disabled attribute in card variant
      assert html =~ ~r(<input[^>]*type="hidden"[^>]*disabled[^>]*>)
      assert html =~ ~r(<input[^>]*type="checkbox"[^>]*disabled[^>]*>)
      assert html =~ ~s(data-disabled="true")
    end

    test "card variant hidden input is not disabled when checkbox is not disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan" disabled={false}>
          <div>Test content</div>
        </.checkbox>
        """)

      # Ensure hidden input doesn't have disabled attribute when card checkbox is enabled
      refute html =~ ~r(<input[^>]*type="hidden"[^>]*disabled[^>]*>)
      assert html =~ ~s(data-disabled="false")
    end

    test "hides checkbox input with sr-only when hide_checkbox is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card hide_checkbox name="plan">
          <div>Hidden checkbox test</div>
        </.checkbox>
        """)

      assert html =~ "sr-only"
    end

    test "does not include opinionated margin classes by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox card name="plan">
          <div>No margin test</div>
        </.checkbox>
        """)

      refute html =~ "mb-3"
      refute html =~ "last:mb-0"
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

    test "wires PulsarCheckbox hook to sync indeterminate IDL property" do
      # axe's aria-conditional-attr rule forbids aria-checked on a native
      # <input type="checkbox">; tri-state must be exposed via the JS-only
      # `indeterminate` IDL property, which the PulsarCheckbox hook sets
      # from data-indeterminate on mount and update.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" indeterminate={true} />
        """)

      assert html =~ ~s(phx-hook="Pulsar.Components.Checkbox.PulsarCheckbox")
      assert html =~ ~s(data-indeterminate="true")
      assert html =~ ~r/<input[^>]*type="checkbox"[^>]*id="/
      refute html =~ ~s(aria-checked)
    end

    test "never sets aria-checked on the native checkbox input" do
      # Regression guard: aria-checked is invalid on native <input
      # type="checkbox"> (axe rule aria-conditional-attr). Hold the line
      # across checked, unchecked, and indeterminate states.
      for opts <- [[checked: true], [checked: false], [indeterminate: true]] do
        assigns = %{opts: opts}

        html =
          rendered_to_string(~H"""
          <.checkbox name="terms" {@opts} />
          """)

        refute html =~ ~s(aria-checked)
      end
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
    test "merges custom classes with Twm" do
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
      assert html =~ "after:duration-normal"
    end

    test "includes rounded classes for pseudo elements" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="terms" />
        """)

      # Default size (md) should have before:rounded-field
      assert html =~ "before:rounded-field"
      # Should not have the old broken syntax
      refute html =~ "before:rounded-inherit"
    end
  end

  describe "refactored functionality verification" do
    test "all color variants generate correct classes" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.checkbox name="test" color={@color} checked />
          """)

        # Should contain color-specific classes
        assert html =~ "data-[checked=true]:before:border-#{color}"
        assert html =~ "data-[checked=true]:before:bg-#{color}"
        assert html =~ "data-[checked=true]:after:text-#{color}-foreground"
      end
    end

    test "all size variants generate correct classes" do
      sizes = ~w(xs sm md lg xl)

      expected_heights = %{
        "lg" => "h-6",
        "md" => "h-5",
        "sm" => "h-4",
        "xl" => "h-7",
        "xs" => "h-3"
      }

      for size <- sizes do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.checkbox name="test" size={@size} />
          """)

        assert html =~ expected_heights[size]
      end
    end

    test "card variants with all colors work correctly" do
      colors = ~w(neutral primary secondary success danger warning info)
      variants = ~w(solid outline ghost)

      for color <- colors, variant <- variants do
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <.checkbox name="test" card variant={@variant} color={@color}>
            Content
          </.checkbox>
          """)

        # Should render as label with proper structure
        assert html =~ ~s(<label)
        assert html =~ "Content"
        assert html =~ ~s(type="checkbox")
      end
    end

    test "refactored size configuration works for both input and card" do
      assigns = %{}

      # Test input size classes
      html =
        rendered_to_string(~H"""
        <.checkbox name="test" size="lg" />
        """)

      assert html =~ "h-6 w-6"

      # Test card size classes
      html =
        rendered_to_string(~H"""
        <.checkbox name="test" card size="lg">Content</.checkbox>
        """)

      assert html =~ "p-5 gap-4 text-lg"
    end
  end
end
