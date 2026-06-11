defmodule Pulsar.Components.TextareaTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Pulsar.Components.Textarea

  describe "textarea/1 basic functionality" do
    test "follows the motion contract and keeps height transitionable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" />
        """)

      assert html =~ "transition-[color,background-color,border-color,box-shadow,height]"
      assert html =~ "duration-fast"
      assert html =~ "ease-standard"
      refute html =~ "transition-all"
      refute html =~ "duration-normal"
    end

    test "renders textarea with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" />
        """)

      assert html =~ ~s(<textarea)
      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-color="neutral")
      assert html =~ ~s(data-size="md")
      # Default solid variant with neutral color
      assert html =~ "bg-neutral/10"
      # Default size (md) with appropriate min-height for textarea
      assert html =~ "min-h-24"
      # Default max height constraint
      assert html =~ "max-h-64"
    end

    test "renders with ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" variant="ghost" />
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ "bg-transparent"
      assert html =~ "border-transparent"
    end

    test "renders with outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" variant="outline" />
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ "border-2"
      assert html =~ "border-border"
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" size="lg" />
        """)

      # Large size class
      assert html =~ "min-h-32"
      assert html =~ "text-lg"
      assert html =~ "max-h-80"
    end

    test "passes through Stellar textarea props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea
          name="test"
          rows={6}
          cols={50}
          required={true}
          disabled={true}
          placeholder="Enter text"
        />
        """)

      assert html =~ ~s(rows="6")
      assert html =~ ~s(cols="50")
      assert html =~ ~s(required)
      assert html =~ ~s(disabled)
      assert html =~ ~s(placeholder="Enter text")
    end

    test "merges custom classes with component classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" class="w-full custom-class" />
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
    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" variant="outline" />
        """)

      assert html =~ "border-2"
      assert html =~ "border-border"
      assert html =~ "bg-background"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" variant="ghost" />
        """)

      assert html =~ "bg-transparent"
      assert html =~ "border-transparent"
      assert html =~ "text-foreground"
    end

    test "renders solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" variant="solid" />
        """)

      assert html =~ "bg-neutral/10"
      assert html =~ "border-transparent"
      assert html =~ "text-foreground"
    end
  end

  describe "colors" do
    test "renders all colors correctly for outline variant" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Textarea.textarea name="test" variant="outline" color={@color} />
          """)

        case color do
          "neutral" ->
            assert html =~ "border-border"
            assert html =~ "bg-background"
            assert html =~ "text-foreground"

          "primary" ->
            assert html =~ "border-primary"
            assert html =~ "text-primary"

          "secondary" ->
            assert html =~ "border-secondary"
            assert html =~ "text-secondary"

          "success" ->
            assert html =~ "border-success"
            assert html =~ "text-success"

          "danger" ->
            assert html =~ "border-danger"
            assert html =~ "text-danger"

          "warning" ->
            assert html =~ "border-warning"
            assert html =~ "text-warning"

          "info" ->
            assert html =~ "border-info"
            assert html =~ "text-info"
        end
      end
    end

    test "renders all colors correctly for solid variant" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Textarea.textarea name="test" variant="solid" color={@color} />
          """)

        case color do
          "neutral" ->
            assert html =~ "bg-neutral/10"
            assert html =~ "text-foreground"

          "primary" ->
            assert html =~ "bg-primary/10"
            assert html =~ "text-primary"

          "secondary" ->
            assert html =~ "bg-secondary/10"
            assert html =~ "text-secondary"

          "success" ->
            assert html =~ "bg-success/10"
            assert html =~ "text-success"

          "danger" ->
            assert html =~ "bg-danger/10"
            assert html =~ "text-danger"

          "warning" ->
            assert html =~ "bg-warning/10"
            assert html =~ "text-warning"

          "info" ->
            assert html =~ "bg-info/10"
            assert html =~ "text-info"
        end
      end
    end

    test "renders all colors correctly for ghost variant" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Textarea.textarea name="test" variant="ghost" color={@color} />
          """)

        case color do
          "neutral" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-foreground"

          "primary" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-primary"

          "secondary" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-secondary"

          "success" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-success"

          "danger" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-danger"

          "warning" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-warning"

          "info" ->
            assert html =~ "bg-transparent"
            assert html =~ "text-info"
        end
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
          <Textarea.textarea name="test" size={@size} />
          """)

        case size do
          "xs" ->
            assert html =~ "min-h-16"
            assert html =~ "text-xs"
            assert html =~ "max-h-32"

          "sm" ->
            assert html =~ "min-h-20"
            assert html =~ "text-sm"
            assert html =~ "max-h-40"

          "md" ->
            assert html =~ "min-h-24"
            assert html =~ "max-h-64"

          "lg" ->
            assert html =~ "min-h-32"
            assert html =~ "text-lg"
            assert html =~ "max-h-80"

          "xl" ->
            assert html =~ "min-h-40"
            assert html =~ "text-xl"
            assert html =~ "max-h-96"
        end
      end
    end
  end

  describe "custom height constraints" do
    test "applies custom min and max height via styles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" min_height="100px" max_height="400px" />
        """)

      assert html =~ "min-height: 100px"
      assert html =~ "max-height: 400px"
      # Should not include default max height classes when custom heights provided
      refute html =~ "max-h-64"
    end

    test "applies only custom min height" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" min_height="80px" />
        """)

      assert html =~ ~s(style="min-height: 80px;")
      # Should not include default max height classes
      refute html =~ "max-h-64"
    end

    test "applies only custom max height" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" max_height="500px" />
        """)

      assert html =~ ~s(style="max-height: 500px;")
      # Should not include default max height classes
      refute html =~ "max-h-64"
    end

    test "uses default height constraints when no custom heights provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" size="lg" />
        """)

      # Default for lg size
      assert html =~ "max-h-80"
      # No custom style attribute
      refute html =~ "style="
    end
  end

  describe "character counting" do
    test "renders character count when enabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value="Hello" />
        """)

      # Shows current count / max
      assert html =~ "<span>5</span><span>/100</span>"
      # Normal state color
      assert html =~ "text-muted-foreground"
    end

    test "shows warning color when approaching limit" do
      assigns = %{long_text: String.duplicate("x", 95)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value={@long_text} />
        """)

      assert html =~ "<span>95</span><span>/100</span>"
      assert html =~ "text-warning"
      assert html =~ "5 remaining"
    end

    test "shows danger color when at limit" do
      assigns = %{at_limit_text: String.duplicate("x", 100)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value={@at_limit_text} />
        """)

      assert html =~ "<span>100</span><span>/100</span>"
      assert html =~ "text-danger"
      assert html =~ "font-medium"
    end

    test "shows over limit when exceeded" do
      assigns = %{over_limit_text: String.duplicate("x", 105)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value={@over_limit_text} />
        """)

      assert html =~ "<span>105</span><span>/100</span>"
      assert html =~ "text-danger"
      assert html =~ "5 over"
    end

    test "works without max_length" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count value="Hello World" />
        """)

      # Just shows count
      assert html =~ "11"
      # No max length display format
      refute html =~ "11/"
    end

    test "handles empty value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} />
        """)

      assert html =~ "<span>0</span><span>/100</span>"
    end

    test "counts Unicode characters correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value="👋🌍" />
        """)

      # Emoji should count as individual characters
      assert html =~ "<span>2</span><span>/100</span>"
    end
  end

  describe "character counter localization" do
    test "uses English counter words by default" do
      assigns = %{near_limit: String.duplicate("x", 95)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" show_character_count max_length={100} value={@near_limit} />
        """)

      assert html =~ "5 remaining"
    end

    test "translates remaining_label and over_label" do
      assigns = %{near_limit: String.duplicate("x", 95)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea
          name="test"
          show_character_count
          max_length={100}
          value={@near_limit}
          remaining_label="restantes"
        />
        """)

      assert html =~ "5 restantes"
      refute html =~ "5 remaining"
    end

    test "over_label replaces the over-limit word" do
      assigns = %{over_limit: String.duplicate("x", 105)}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea
          name="test"
          show_character_count
          max_length={100}
          value={@over_limit}
          over_label="de más"
        />
        """)

      assert html =~ "de más"
      refute html =~ "over)"
    end

    test "format_count runs every counter integer through the supplied formatter" do
      assigns = %{value: String.duplicate("x", 1234), formatter: &"[#{&1}]"}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea
          name="test"
          show_character_count
          max_length={2000}
          value={@value}
          format_count={@formatter}
        />
        """)

      # Count and max are both routed through the formatter.
      assert html =~ "[1234]"
      assert html =~ "[2000]"
    end
  end

  describe "auto-resize feature" do
    test "enables auto-resize when specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" auto_resize />
        """)

      assert html =~ ~s(data-auto-resize="true")
    end

    test "does not enable auto-resize by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" />
        """)

      assert html =~ ~s(data-auto-resize="false")
    end
  end

  describe "states and accessibility" do
    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" disabled={true} />
        """)

      assert html =~ ~s(disabled)
      assert html =~ "cursor-not-allowed"
      assert html =~ "opacity-disabled"
      assert html =~ "pointer-events-none"
    end

    test "handles readonly state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" readonly={true} />
        """)

      assert html =~ ~s(readonly)
      assert html =~ "cursor-default"
    end

    test "handles required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" required={true} />
        """)

      assert html =~ ~s(required)
      assert html =~ ~s(data-required="true")
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" />
        """)

      assert html =~ "focus-visible:ring-2"
      assert html =~ "focus-visible:ring-ring"
    end

    test "sets aria-invalid attribute when invalid is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" invalid={true} />
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "sets aria-invalid to 'false' when invalid is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" invalid={false} />
        """)

      assert html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "respects caller-provided aria-describedby attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" aria-describedby="help-text" />
        """)

      assert html =~ ~s(aria-describedby="help-text")
    end

    test "merges caller aria-describedby with error ids" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is too short", []}],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} aria-describedby="help-text" />
        """)

      # Should merge both the caller's aria-describedby and the errors id
      assert html =~ ~s(aria-describedby="help-text user_description-errors")
    end
  end

  describe "automatic error state handling" do
    test "error state overrides to danger styling" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is too short", []}],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} />
        """)

      # Should show danger styling automatically
      assert html =~ "bg-danger/10"
      assert html =~ "text-danger"

      # Should have data attributes for invalid state
      assert html =~ ~r/data-invalid(?=[^=])/
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-color="danger")
    end

    test "no error state uses specified color" do
      # Create a form field without errors
      field = %FormField{
        errors: [],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: "Some content"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} color="primary" />
        """)

      # Should use primary color
      assert html =~ "bg-primary/10"
      assert html =~ "text-primary"

      # Should have data attributes for valid state
      refute html =~ "data-invalid"
      assert html =~ ~s(aria-invalid="false")
      assert html =~ ~s(data-color="primary")
    end

    test "character count reflects error color" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is too short", []}],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: "Short"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} show_character_count max_length={100} />
        """)

      # Character count should reflect error color to match textarea styling
      assert html =~ "<span>5</span><span>/100</span>"
      assert html =~ "text-danger"
    end
  end

  describe "Phoenix form integration" do
    test "accepts field attribute for form integration" do
      field = %FormField{
        errors: [],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: "Test content"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} />
        """)

      assert html =~ ~s(name="user[description]")
      assert html =~ ~s(id="user_description")
      assert html =~ "Test content"
    end

    test "character count works with field values" do
      field = %FormField{
        errors: [],
        field: :description,
        form: %Form{},
        id: "user_description",
        name: "user[description]",
        value: "Hello World"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@field} show_character_count max_length={50} />
        """)

      # Count from field value
      assert html =~ "<span>11</span><span>/50</span>"
    end
  end

  describe "Twm integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" class="border-red-500 min-h-20" />
        """)

      # Twm should resolve conflicts
      # Custom border should override
      assert html =~ "border-red-500"
      # Custom height should override
      assert html =~ "min-h-20"
    end

    test "preserves non-conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" class="w-full shadow-lg font-mono" />
        """)

      # Should include both original and custom classes
      assert html =~ "w-full"
      assert html =~ "shadow-lg"
      assert html =~ "font-mono"
      # Original background preserved
      assert html =~ "bg-neutral/10"
    end
  end

  describe "edge cases" do
    test "requires name when field is not provided" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires either :field or :name attribute/, fn ->
        rendered_to_string(~H"""
        <Textarea.textarea />
        """)
      end
    end

    test "passes through LiveView events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea
          name="test"
          phx-change="validate"
          phx-debounce="300"
          data-testid="test-textarea"
        />
        """)

      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-debounce="300")
      assert html =~ ~s(data-testid="test-textarea")
    end

    test "handles nil values gracefully" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" value={nil} character_count />
        """)

      # Should show 0 count for nil value
      assert html =~ "0"
      refute html =~ "nil"
    end

    test "character count without display when not enabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" max_length={100} value="Hello" />
        """)

      # Should not show character count display
      refute html =~ "5<span>/100</span>"
      refute html =~ ~s(<div class="flex justify-between items-center text-sm" aria-hidden="true">)
    end

    test "wrap attribute passes through correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="test" wrap="hard" />
        """)

      assert html =~ ~s(wrap="hard")
    end
  end
end
