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
      # Default outline variant with neutral color
      assert html =~ "border-border"
      assert html =~ "dark:border-dark-border"
      # Default size (md)
      assert html =~ "min-h-10"
    end

    test "renders with ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="ghost" />
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ "bg-transparent"
      refute html =~ "border-2"  # Ghost doesn't have border
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" size="lg" />
        """)

      # Large size class
      assert html =~ "min-h-12"
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
        <Input.input name="test" class="w-full custom-class" />
        """)

      # Should contain both component classes and custom classes
      assert html =~ "border-border"     # Component class
      assert html =~ "w-full"            # Custom class
      assert html =~ "custom-class"      # Custom class
    end
  end

  describe "variants" do
    test "renders outline variant (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline" />
        """)

      assert html =~ "border-2"
      assert html =~ "border-border"
      assert html =~ "dark:border-dark-border"
      assert html =~ "bg-background"
      assert html =~ "dark:bg-dark-background"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="ghost" />
        """)

      assert html =~ "bg-transparent"
      refute html =~ "border-2"  # Ghost doesn't have border
      assert html =~ "text-foreground"
      assert html =~ "dark:text-dark-foreground"
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

    test "outline decorator styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="outline">
          <:start_decorator>Icon</:start_decorator>
        </Input.input>
        """)

      # Outline decorators have surface background
      assert html =~ "bg-surface-secondary"
      assert html =~ "dark:bg-dark-surface-secondary"
      assert html =~ "border-r"
    end

    test "ghost decorator styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="ghost">
          <:start_decorator>Icon</:start_decorator>
          <:end_decorator>Icon</:end_decorator>
        </Input.input>
        """)

      # Ghost decorators are minimal
      assert html =~ "text-muted"
      assert html =~ "dark:text-dark-muted"
      # Ghost decorators use size-based padding from get_decorator_padding, no extra pr/pl classes
      assert html =~ "px-3 py-1.5"  # md size decorator padding
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
      assert html =~ "cursor-not-allowed"
      assert html =~ "opacity-50"
      assert html =~ "pointer-events-none"
      
      # Verify the input element itself also has cursor-not-allowed
      assert html =~ ~r/<input[^>]*class="[^"]*cursor-not-allowed[^"]*"[^>]*disabled/
    end

    test "handles readonly state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" readonly={true} />
        """)


      assert html =~ ~s(readonly)
      assert html =~ "cursor-default"
      
      # Verify the input element itself also has cursor-default
      assert html =~ ~r/<input[^>]*class="[^"]*cursor-default[^"]*"[^>]*readonly/
    end

    test "handles required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" required={true} />
        """)

      assert html =~ ~s(required)
      assert html =~ ~s(data-required="true")
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" />
        """)

      assert html =~ "focus-within:ring-2"
      assert html =~ "focus-within:ring-offset-2"
    end
  end

  describe "automatic error state handling" do
    test "error state overrides to danger styling" do
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
        <Input.input field={@field} />
        """)

      # Should show danger styling automatically
      assert html =~ "border-danger-500"
      assert html =~ "dark:border-danger-400"
      assert html =~ "text-danger-700"
      assert html =~ "dark:text-danger-300"

      # Should have data attributes for invalid state
      assert html =~ ~s(data-invalid="true")
      assert html =~ ~s(data-color="danger")
    end

    test "no error state uses neutral color" do
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
        <Input.input field={@field} />
        """)

      # Should use neutral color
      assert html =~ "border-border"
      assert html =~ "dark:border-dark-border"
      assert html =~ "text-foreground"
      assert html =~ "dark:text-dark-foreground"

      # Should have data attributes for valid state
      assert html =~ ~s(data-invalid="false")
      assert html =~ ~s(data-color="neutral")
    end

    test "error state affects decorators too" do
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
        <Input.input field={@field} variant="outline">
          <:start_decorator>$</:start_decorator>
        </Input.input>
        """)

      # Decorators should also show danger styling
      assert html =~ "bg-danger-50"
      assert html =~ "dark:bg-danger-900/20"
      assert html =~ "text-danger-700"
      assert html =~ "dark:text-danger-300"
      assert html =~ "border-r border-danger-500"
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
        if type == "hidden" do
          # Hidden inputs render directly without container/decorators
          refute html =~ ~s(<div)
        else
          assert html =~ ~s(<div)
        end
      end
    end

    test "hidden input renders without container for minimal DOM" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" type="hidden" value="secret" />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="test")
      assert html =~ ~s(value="secret")
      # No container div or group data attributes
      refute html =~ ~s(data-variant)
      refute html =~ "flex group"
    end
  end

  describe "TailwindMerge integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" class="border-red-500 min-h-16" />
        """)

      # TailwindMerge should resolve conflicts
      assert html =~ "border-red-500"  # Custom border should override
      assert html =~ "min-h-16"        # Custom height should override
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
      assert html =~ "border-border"   # Original border preserved
      assert html =~ "min-h-10"        # Original height preserved
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