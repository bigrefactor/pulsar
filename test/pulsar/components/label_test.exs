defmodule Pulsar.Components.LabelTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Label

  describe "label/1 basic functionality" do
    test "renders label with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="email">Email Address</Label.label>
        """)

      assert html =~ ~s(<label)
      assert html =~ ~s(for="email")
      assert html =~ "Email Address"
      # Default size (md)
      assert html =~ "text-base"
      # Default color (normal)
      assert html =~ "text-foreground"
      # Font weight
      assert html =~ "font-medium"
      # Cursor pointer for clickability
      assert html =~ "cursor-pointer"
      # No indicators by default
      refute html =~ "*"
    end

    test "renders with for attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="username">Username</Label.label>
        """)

      assert html =~ ~s(for="username")
      assert html =~ "Username"
    end

    test "passes through data-required attribute from Stellar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="email" required>Email</Label.label>
        """)

      assert html =~ ~s(data-required="true")
    end
  end

  describe "label/1 size variants" do
    test "renders with xs size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" size="xs">XS Label</Label.label>
        """)

      assert html =~ "text-xs"
      assert html =~ "XS Label"
    end

    test "renders with sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" size="sm">SM Label</Label.label>
        """)

      assert html =~ "text-sm"
      assert html =~ "SM Label"
    end

    test "renders with md size (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" size="md">MD Label</Label.label>
        """)

      assert html =~ "text-base"
      assert html =~ "MD Label"
    end

    test "renders with lg size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" size="lg">LG Label</Label.label>
        """)

      assert html =~ "text-lg"
      assert html =~ "LG Label"
    end

    test "renders with xl size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" size="xl">XL Label</Label.label>
        """)

      assert html =~ "text-xl"
      assert html =~ "XL Label"
    end
  end

  describe "label/1 required indicator" do
    test "renders required indicator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="password" required>Password</Label.label>
        """)

      assert html =~ "Password"
      assert html =~ "<span"
      assert html =~ "text-danger"
      assert html =~ ">*</span>"
    end

    test "required indicator matches label size" do
      assigns = %{}

      # Test xs size
      html_xs =
        rendered_to_string(~H"""
        <Label.label for="field" size="xs" required>XS</Label.label>
        """)

      assert html_xs =~ "text-xs"

      # Test xl size
      html_xl =
        rendered_to_string(~H"""
        <Label.label for="field" size="xl" required>XL</Label.label>
        """)

      assert html_xl =~ "text-xl"
    end

    test "required indicator uses danger color and is aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" required>Required</Label.label>
        """)

      assert html =~ "text-danger dark:text-dark-danger"
      assert html =~ ~s(aria-hidden="true")
    end

    test "supports custom sr_required_text for i18n" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" required sr_required_text="(obligatorio)">Spanish Required</Label.label>
        """)

      assert html =~ "Spanish Required"
      # Should pass through custom text to Stellar (visible in sr-only span)
      assert html =~ "(obligatorio)"
      assert html =~ ~s(class="sr-only")
    end

    test "uses default sr_required_text when not specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" required>Default Required</Label.label>
        """)

      assert html =~ "Default Required"
      # Should use default "(required)" text
      assert html =~ "(required)"
      assert html =~ ~s(class="sr-only")
    end
  end

  describe "label/1 default state" do
    test "renders without indicators by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field">Just Label</Label.label>
        """)

      refute html =~ "*"
      assert html =~ "Just Label"
    end
  end

  describe "label/1 error state" do
    test "renders error state styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="invalid-field" error>Invalid Field</Label.label>
        """)

      assert html =~ "Invalid Field"
      assert html =~ "text-danger dark:text-dark-danger"
    end

    test "error state with required indicator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" error required>Error Required</Label.label>
        """)

      # Both label and asterisk should be danger color
      assert html =~ "Error Required"
      # Count occurrences of danger color (should be 2: label + asterisk)
      danger_matches = Regex.scan(~r/text-danger/, html)
      assert length(danger_matches) >= 2
    end

    test "normal state uses foreground color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field">Normal Field</Label.label>
        """)

      assert html =~ "text-foreground dark:text-dark-foreground"
      refute html =~ "text-danger"
    end
  end

  describe "label/1 custom styling" do
    test "accepts custom CSS classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" class="custom-class mb-4">Custom</Label.label>
        """)

      assert html =~ "custom-class"
      assert html =~ "mb-4"
      assert html =~ "Custom"
    end

    test "merges classes with TailwindMerge" do
      assigns = %{}

      # Test that custom classes can override defaults
      html =
        rendered_to_string(~H"""
        <Label.label for="field" class="text-red-500 font-bold">Override</Label.label>
        """)

      # Should contain both default and custom classes
      assert html =~ "text-red-500"
      assert html =~ "font-bold"
      assert html =~ "Override"
    end

    test "passes through additional HTML attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" id="custom-id" data-test="value">Attributes</Label.label>
        """)

      assert html =~ ~s(id="custom-id")
      assert html =~ ~s(data-test="value")
      assert html =~ "Attributes"
    end
  end

  describe "label/1 dark mode support" do
    test "includes dark mode classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field">Dark Mode</Label.label>
        """)

      assert html =~ "dark:text-dark-foreground"
    end

    test "error state includes dark mode classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" error>Dark Error</Label.label>
        """)

      assert html =~ "dark:text-dark-danger"
    end

    test "required indicator includes dark mode classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" required>Dark Required</Label.label>
        """)

      assert html =~ "dark:text-dark-danger"
    end
  end

  describe "label/1 accessibility" do
    test "includes accessibility classes and transitions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field">Accessible</Label.label>
        """)

      assert html =~ "transition-colors"
      assert html =~ "duration-200"
    end

    test "uses Stellar label for accessibility features" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" required>Stellar Integration</Label.label>
        """)

      # Should include Stellar's data-required attribute
      assert html =~ ~s(data-required="true")
      # Should include screen reader text from Stellar
      assert html =~ ~s(class="sr-only")
    end
  end

  describe "label/1 data attributes" do
    test "includes data-error attribute" do
      assigns = %{}

      # Test error state
      html_error =
        rendered_to_string(~H"""
        <Label.label for="field" error>Error Label</Label.label>
        """)

      assert html_error =~ ~s(data-error="true")

      # Test normal state
      html_normal =
        rendered_to_string(~H"""
        <Label.label for="field">Normal Label</Label.label>
        """)

      assert html_normal =~ ~s(data-error="false")
    end

    test "includes data-size attribute" do
      # Test different sizes
      sizes = ["xs", "sm", "md", "lg", "xl"]

      for size <- sizes do
        assigns = %{test_size: size}

        html =
          rendered_to_string(~H"""
          <Label.label for="field" size={@test_size}>Size Label</Label.label>
          """)

        assert html =~ ~s(data-size="#{size}")
      end
    end

    test "data attributes can be used for external styling hooks" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="field" error size="lg" required>Styled Label</Label.label>
        """)

      # Should have all data attributes for external CSS targeting
      assert html =~ ~s(data-error="true")
      assert html =~ ~s(data-size="lg")
      # From Stellar
      assert html =~ ~s(data-required="true")
    end
  end
end
