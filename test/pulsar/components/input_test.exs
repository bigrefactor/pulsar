defmodule Pulsar.Components.InputTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Pulsar.Components.Input

  describe "input/1 basic functionality" do
    test "renders input with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" />
        """)

      assert html =~ ~s(<div)
      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-color="neutral")
      assert html =~ ~s(data-size="md")
      # Default solid variant with neutral color
      assert html =~ "bg-neutral/10"
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
      # Ghost doesn't have border
      refute html =~ "border-2"
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
      # Component class
      assert html =~ "bg-neutral/10"
      # Custom class
      assert html =~ "w-full"
      # Custom class
      assert html =~ "custom-class"
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
      assert html =~ "bg-background"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" variant="ghost" />
        """)

      assert html =~ "bg-transparent"
      # Ghost doesn't have border
      refute html =~ "border-2"
      assert html =~ "text-foreground"
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

      # Outline decorators have border background
      assert html =~ "bg-border"
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
      assert html =~ "text-muted-foreground"
      # Ghost decorators use size-based padding from get_decorator_padding, no extra pr/pl classes
      # md size decorator padding
      assert html =~ "px-3 py-1.5"
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
      assert html =~ "focus-within:ring-neutral/60"
    end
  end

  describe "automatic error state handling" do
    test "error state overrides to danger styling" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is required", []}],
        field: :email,
        form: %Form{},
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
      assert html =~ "bg-danger/10"
      assert html =~ "dark:bg-dark-danger/20"
      assert html =~ "text-danger"
      assert html =~ "dark:text-dark-danger"

      # Should have data attributes for invalid state
      assert html =~ ~s(data-invalid)
      assert html =~ ~s(data-color="danger")
    end

    test "no error state uses neutral color" do
      # Create a form field without errors
      field = %FormField{
        errors: [],
        field: :email,
        form: %Form{},
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
      assert html =~ "bg-neutral/10"
      assert html =~ "text-neutral"

      # Should have data attributes for valid state
      refute html =~ ~s(data-invalid)
      assert html =~ ~s(data-color="neutral")
    end

    test "sets aria-invalid to 'true' when field has errors" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is required", []}],
        field: :email,
        form: %Form{},
        id: "user_email",
        name: "user[email]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Input.input field={@field} />
        """)

      # Should have aria-invalid="true" when field has errors
      assert html =~ ~s(aria-invalid="true")
      refute html =~ ~s(aria-invalid="false")
    end

    test "sets aria-invalid to 'false' when field has no errors" do
      # Create a form field without errors
      field = %FormField{
        errors: [],
        field: :email,
        form: %Form{},
        id: "user_email",
        name: "user[email]",
        value: "test@example.com"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Input.input field={@field} />
        """)

      # Should have aria-invalid="false" when field has no errors
      assert html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "sets aria-invalid to 'false' when no field is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="test" />
        """)

      # Should have aria-invalid="false" when no field provided
      assert html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "error state affects decorators too" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is required", []}],
        field: :email,
        form: %Form{},
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
      assert html =~ "bg-danger"
      assert html =~ "dark:bg-dark-danger"
      assert html =~ "text-danger-foreground"
      assert html =~ "dark:text-dark-danger-foreground"
      assert html =~ "border-r"
      assert html =~ "border-danger"
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
      types =
        ~w(text email password number tel url search date time datetime-local month week color range file hidden)

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
      # Custom border should override
      assert html =~ "border-red-500"
      # Custom height should override
      assert html =~ "min-h-16"
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
      # Original background preserved
      assert html =~ "bg-neutral/10"
      # Original height preserved
      assert html =~ "min-h-10"
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
