defmodule Pulsar.Components.InputTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias Pulsar.Components.Input

  describe "input/1 basic functionality" do
    test "renders input with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" />
        """)

      assert html =~ ~s(<div)
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-color="neutral")
      assert html =~ ~s(data-size="md")
      # Default variant (outline) and color (neutral)
      assert html =~ "border-gray-300"
      assert html =~ "dark:border-gray-600"
      # Default size (md)
      assert html =~ "h-10"
    end

    test "renders with custom variant and color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="solid" color="primary" />
        """)

      assert html =~ "bg-primary-50"
      assert html =~ "dark:bg-primary-900/30"
      assert html =~ "text-primary-800"
      assert html =~ "dark:text-primary-200"
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" size="lg" />
        """)

      # Large size class
      assert html =~ "h-12"
      assert html =~ "text-lg"
    end

    test "passes through Stellar input props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" type="email" required={true} disabled={true} placeholder="Enter email" />
        """)

      assert html =~ ~s(type="email")
      assert html =~ ~s(required)
      assert html =~ ~s(disabled)
      assert html =~ ~s(placeholder="Enter email")
    end

    test "merges custom classes with component classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline" color="primary" class="w-full custom-class" />
        """)

      # Should contain both component classes and custom classes
      assert html =~ "border-primary-300"  # Component class
      assert html =~ "w-full"              # Custom class
      assert html =~ "custom-class"        # Custom class
    end
  end

  describe "variants" do
    test "renders solid variant with all colors" do
      colors = ~w(neutral primary secondary info success danger warning)

      for color <- colors do
        assigns = %{color: color}
        html =
          rendered_to_string(~H"""
          <Input.input name="test" variant="solid" color={@color} />
          """)

        case color do
          "neutral" -> 
            assert html =~ "bg-gray-50"
            assert html =~ "dark:bg-gray-800"
          "primary" -> 
            assert html =~ "bg-primary-50"
            assert html =~ "dark:bg-primary-900/30"
          "secondary" -> 
            assert html =~ "bg-secondary-50"
            assert html =~ "dark:bg-secondary-900/30"
          "info" -> 
            assert html =~ "bg-info-50"
            assert html =~ "dark:bg-info-900/30"
          "success" -> 
            assert html =~ "bg-success-50"
            assert html =~ "dark:bg-success-900/30"
          "danger" -> 
            assert html =~ "bg-danger-50"
            assert html =~ "dark:bg-danger-900/30"
          "warning" -> 
            assert html =~ "bg-warning-50"
            assert html =~ "dark:bg-warning-900/30"
        end
      end
    end

    test "renders outline variant with all colors" do
      colors = ~w(neutral primary secondary info success danger warning)

      for color <- colors do
        assigns = %{color: color}
        html =
          rendered_to_string(~H"""
          <Input.input name="test" variant="outline" color={@color} />
          """)

        case color do
          "neutral" -> 
            assert html =~ "border-gray-300"
            assert html =~ "dark:border-gray-600"
          "primary" -> 
            assert html =~ "border-primary-300"
            assert html =~ "dark:border-primary-600"
          "secondary" -> 
            assert html =~ "border-secondary-300"
            assert html =~ "dark:border-secondary-600"
          "info" -> 
            assert html =~ "border-info-300"
            assert html =~ "dark:border-info-600"
          "success" -> 
            assert html =~ "border-success-300"
            assert html =~ "dark:border-success-600"
          "danger" -> 
            assert html =~ "border-danger-300"
            assert html =~ "dark:border-danger-600"
          "warning" -> 
            assert html =~ "border-warning-300"
            assert html =~ "dark:border-warning-600"
        end

        # All outline variants should have border-2
        assert html =~ "border-2"
      end
    end

    test "renders ghost variant with all colors" do
      colors = ~w(neutral primary secondary info success danger warning)

      for color <- colors do
        assigns = %{color: color}
        html =
          rendered_to_string(~H"""
          <Input.input name="test" variant="ghost" color={@color} />
          """)

        case color do
          "neutral" -> 
            assert html =~ "text-gray-800"
            assert html =~ "dark:text-gray-200"
          "primary" -> 
            assert html =~ "text-primary-800"
            assert html =~ "dark:text-primary-200"
          "secondary" -> 
            assert html =~ "text-secondary-800"
            assert html =~ "dark:text-secondary-200"
          "info" -> 
            assert html =~ "text-info-800"
            assert html =~ "dark:text-info-200"
          "success" -> 
            assert html =~ "text-success-800"
            assert html =~ "dark:text-success-200"
          "danger" -> 
            assert html =~ "text-danger-800"
            assert html =~ "dark:text-danger-200"
          "warning" -> 
            assert html =~ "text-warning-800"
            assert html =~ "dark:text-warning-200"
        end

        # Ghost variants should not have border-2
        refute html =~ "border-2"
      end
    end
  end

  describe "sizes" do
    test "renders all available sizes correctly" do
      sizes = ~w(xs sm md lg xl)

      for size <- sizes do
        assigns = %{size: size}
        html =
          rendered_to_string(~H"""
          <Input.input name="test" size={@size} />
          """)

        case size do
          "xs" -> 
            assert html =~ "min-h-6"
            assert html =~ "text-xs"
          "sm" -> 
            assert html =~ "min-h-8"
            assert html =~ "text-sm"
          "md" -> 
            assert html =~ "min-h-10"
          "lg" -> 
            assert html =~ "min-h-12"
            assert html =~ "text-lg"
          "xl" -> 
            assert html =~ "min-h-14"
            assert html =~ "text-xl"
        end
      end
    end
  end

  describe "decorators" do
    test "renders with start decorator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test">
          <:start_decorator>$</:start_decorator>
        </Input.input>
        """)

      assert html =~ ~s(data-has-start-decorator)
      assert html =~ "$"
    end

    test "renders with end decorator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test">
          <:end_decorator>USD</:end_decorator>
        </Input.input>
        """)

      assert html =~ ~s(data-has-end-decorator)
      assert html =~ "USD"
    end

    test "renders with both decorators" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test">
          <:start_decorator>$</:start_decorator>
          <:end_decorator>USD</:end_decorator>
        </Input.input>
        """)

      assert html =~ ~s(data-has-start-decorator)
      assert html =~ ~s(data-has-end-decorator)
      assert html =~ "$"
      assert html =~ "USD"
    end

    test "decorator styling matches input variant and color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline" color="primary">
          <:start_decorator>Icon</:start_decorator>
        </Input.input>
        """)

      # Decorator should have matching styling
      assert html =~ "bg-primary-100"
      assert html =~ "dark:bg-primary-900/40"
      assert html =~ "text-primary-800"
      assert html =~ "dark:text-primary-200"
    end

    test "solid variant decorators have transparent backgrounds" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="solid" color="primary">
          <:start_decorator>Icon</:start_decorator>
        </Input.input>
        """)

      # Solid variant decorators should be transparent
      assert html =~ "bg-transparent"
    end

    test "ghost variant decorators handle focus transitions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="ghost" color="primary">
          <:start_decorator>Icon</:start_decorator>
          <:end_decorator>Icon</:end_decorator>
        </Input.input>
        """)

      # Ghost decorators should include transition classes
      assert html =~ "group-data-[variant=ghost]:transition-all"
      assert html =~ "group-data-[variant=ghost]:group-focus-within:pl-4"
      assert html =~ "group-data-[variant=ghost]:group-focus-within:pr-4"
    end
  end

  describe "states and accessibility" do
    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" disabled={true} />
        """)

      assert html =~ ~s(disabled)
      # Should include disabled styling
      assert html =~ "cursor-not-allowed"
      assert html =~ "opacity-50"
    end

    test "handles readonly state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" readonly={true} />
        """)

      assert html =~ ~s(readonly)
      assert html =~ "cursor-default"
    end

    test "handles required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" required={true} />
        """)

      assert html =~ ~s(required)
      # Should include required styling
      assert html =~ "data-[required=true]:shadow-sm"
      assert html =~ "data-[required=true]:focus-within:ring-opacity-80"
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" color="primary" />
        """)

      assert html =~ "focus-within:ring-2"
      assert html =~ "focus-within:ring-primary-500/50"
    end

    test "includes error state styling via data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" />
        """)

      # Should include error state selectors
      assert html =~ "data-[invalid=true]:border-danger-500"
      assert html =~ "data-[invalid=true]:text-danger-700"
      assert html =~ "dark:data-[invalid=true]:text-danger-300"
      assert html =~ "data-[invalid=true]:focus-within:ring-danger-500/50"
    end
  end

  describe "Phoenix form integration" do
    test "accepts field attribute for form integration" do
      assigns = %{}

      # Test that field attribute is properly handled by the Stellar component
      html =
        rendered_to_string(~H"""
        <Input.input name="test" id="custom_id" value="test_value" />
        """)

      assert html =~ ~s(name="test")
      assert html =~ ~s(id="custom_id")
      assert html =~ ~s(value="test_value")
    end
  end

  describe "input types" do
    test "supports all HTML5 input types" do
      types = ~w(text email password number tel url search date time datetime-local month week color range file hidden)

      for type <- types do
        assigns = %{type: type}
        html =
          rendered_to_string(~H"""
          <Input.input name="test" type={@type} />
          """)

        assert html =~ ~s(type="#{type}")
        assert html =~ ~s(<div)  # All inputs have container in Pulsar
      end
    end

    test "hidden input renders within container like other types" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" type="hidden" value="secret" />
        """)

      # In our Pulsar implementation, hidden inputs still get the container
      # The Stellar component handles the hidden input logic internally
      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="test")
      assert html =~ ~s(value="secret")
      # Will still have container div with data attributes
      assert html =~ ~s(data-variant)
      assert html =~ "flex group"
    end
  end

  describe "error state handling" do
    test "decorator error states override normal styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline" color="primary">
          <:start_decorator>$</:start_decorator>
        </Input.input>
        """)

      # Should include error override styles in decorators
      assert html =~ "group-data-[invalid=true]:bg-danger-50"
      assert html =~ "dark:group-data-[invalid=true]:bg-danger-500/20"
      assert html =~ "group-data-[invalid=true]:text-danger-700"
      assert html =~ "dark:group-data-[invalid=true]:text-danger-300"
      assert html =~ "group-data-[invalid=true]:border-danger-300"
    end

    test "error state overrides color to danger" do
      # Create a form field with errors
      field = %Phoenix.HTML.FormField{
        errors: [{"is required", []}],
        field: :email,
        form: %Phoenix.HTML.Form{},
        id: "user_email",
        name: "user[email]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Input.input field={@field} color="primary" />
        """)

      # Should show danger styling instead of primary
      assert html =~ "border-danger-300"
      assert html =~ "dark:border-danger-600"
      assert html =~ "text-danger-800"
      assert html =~ "dark:text-danger-200"

      # Should have data attributes for invalid state
      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(data-color="danger")
    end

    test "no error state uses original color" do
      # Create a form field without errors
      field = %Phoenix.HTML.FormField{
        errors: [],
        field: :email,
        form: %Phoenix.HTML.Form{},
        id: "user_email",
        name: "user[email]",
        value: "test@example.com"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Input.input field={@field} color="primary" />
        """)

      # Should use original primary color
      assert html =~ "border-primary-300"
      assert html =~ "dark:border-primary-600"
      assert html =~ "text-primary-800"
      assert html =~ "dark:text-primary-200"

      # Should have data attributes for valid state
      assert html =~ ~s(data-invalid="false")
      assert html =~ ~s(data-color="primary")
    end

    test "required attribute sets data-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" required={true} />
        """)

      assert html =~ ~s(data-required="true")
    end

    test "non-required attribute sets data-required to false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" required={false} />
        """)

      assert html =~ ~s(data-required="false")
    end
  end

  describe "TailwindMerge integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline" color="primary" class="border-red-500 h-16" />
        """)

      # TailwindMerge should resolve conflicts
      assert html =~ "border-red-500"  # Custom border should be present
      assert html =~ "h-16"            # Custom height should be present
    end

    test "preserves non-conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" class="w-full shadow-lg" />
        """)

      # Should include both original and custom classes
      assert html =~ "w-full"
      assert html =~ "shadow-lg"
      assert html =~ "border-gray-300"  # Original border preserved
      assert html =~ "h-10"             # Original height preserved
    end
  end

  describe "edge cases" do
    test "requires name when field is not provided" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires :name when :field is not provided/, fn ->
        rendered_to_string(~H"""
        <Input.input />
        """)
      end
    end

    test "passes through LiveView events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" phx-change="validate" phx-debounce="300" data-testid="test-input" />
        """)

      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-debounce="300")
      assert html =~ ~s(data-testid="test-input")
    end

    test "handles complex decorator content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test">
          <:start_decorator>
            <svg>...</svg>
            <span>Complex</span>
          </:start_decorator>
        </Input.input>
        """)

      assert html =~ "<svg>...</svg>"
      assert html =~ "<span>Complex</span>"
    end
  end

end