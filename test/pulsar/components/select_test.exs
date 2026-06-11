defmodule Pulsar.Components.SelectTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Select

  describe "select/1 basic functionality" do
    test "follows the motion contract" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["Option 1", "Option 2"]} />
        """)

      assert html =~ "transition-[color,background-color,border-color,box-shadow]"
      assert html =~ "duration-fast"
      assert html =~ "ease-standard"
      refute html =~ "transition-all"
      refute html =~ "duration-normal"
    end

    test "renders select with default props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["Option 1", "Option 2", "Option 3"]} />
        """)

      assert html =~ ~s(<select)
      assert html =~ ~s(name="test")
      # Should include custom arrow styling
      assert html =~ "appearance-none"
      assert html =~ "pr-10"
      # Should have custom arrow icon using Icon component
      assert html =~ "hero-chevron-down"
      assert html =~ "w-4 h-4"
    end

    test "renders with solid variant by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} />
        """)

      # Default solid variant with neutral color
      assert html =~ "bg-neutral/10"
    end

    test "renders with outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} variant="outline" />
        """)

      assert html =~ "border-2"
      assert html =~ "border-border"
      assert html =~ "bg-background"
    end

    test "renders with ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} variant="ghost" />
        """)

      assert html =~ "bg-transparent"
      assert html =~ "border-0"
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} size="lg" />
        """)

      # Large size class
      assert html =~ "min-h-12"
      assert html =~ "text-lg"
      assert html =~ "px-4 py-2"
    end

    test "passes through Stellar select props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} required={true} disabled={true} multiple={true} />
        """)

      assert html =~ ~s(required)
      assert html =~ ~s(disabled)
      assert html =~ ~s(multiple)
      assert html =~ ~s(data-multiple="true")
    end

    test "merges custom classes with component classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} class="w-full custom-class" />
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
        <Select.select name="test" options={["A", "B", "C"]} variant="outline" />
        """)

      assert html =~ "border-2"
      assert html =~ "border-border"
      assert html =~ "bg-background"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} variant="ghost" />
        """)

      assert html =~ "bg-transparent"
      assert html =~ "border-0"
      assert html =~ "text-foreground"
    end

    test "renders solid variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} variant="solid" />
        """)

      assert html =~ "bg-neutral/10"
      assert html =~ "text-neutral"
    end
  end

  describe "colors" do
    test "renders all available colors correctly" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <Select.select name="test" options={["A", "B", "C"]} color={@color} />
          """)

        case color do
          "neutral" ->
            assert html =~ "bg-neutral/10"
            assert html =~ "text-neutral"

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
  end

  describe "sizes" do
    test "renders all available sizes correctly" do
      sizes = ~w(xs sm md lg xl)

      for size <- sizes do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Select.select name="test" options={["A", "B", "C"]} size={@size} />
          """)

        case size do
          "xs" ->
            assert html =~ "min-h-6"
            assert html =~ "text-xs"
            assert html =~ "px-2 py-1"

          "sm" ->
            assert html =~ "min-h-8"
            assert html =~ "text-sm"
            assert html =~ "px-2 py-1"

          "md" ->
            assert html =~ "min-h-10"
            assert html =~ "px-3 py-1.5"

          "lg" ->
            assert html =~ "min-h-12"
            assert html =~ "text-lg"
            assert html =~ "px-4 py-2"

          "xl" ->
            assert html =~ "min-h-14"
            assert html =~ "text-xl"
            assert html =~ "px-4 py-2"
        end
      end
    end
  end

  describe "options handling" do
    test "renders simple string options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["Option 1", "Option 2", "Option 3"]} />
        """)

      assert html =~ "Option 1"
      assert html =~ "Option 2"
      assert html =~ "Option 3"
    end

    test "renders keyword list options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={[Admin: "admin", User: "user", Guest: "guest"]} />
        """)

      assert html =~ ~s(value="admin")
      assert html =~ ~s(value="user")
      assert html =~ ~s(value="guest")
      assert html =~ "Admin"
      assert html =~ "User"
      assert html =~ "Guest"
    end

    test "renders tuple options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={[{"United States", "US"}, {"Canada", "CA"}]} />
        """)

      assert html =~ ~s(value="US")
      assert html =~ ~s(value="CA")
      assert html =~ "United States"
      assert html =~ "Canada"
    end

    test "renders option groups" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="test"
          options={[
            "North America": [{"United States", "US"}, {"Canada", "CA"}],
            Europe: [{"United Kingdom", "UK"}, {"Germany", "DE"}]
          ]}
        />
        """)

      assert html =~ ~s(<optgroup)
      assert html =~ "North America"
      assert html =~ "Europe"
      assert html =~ "United States"
      assert html =~ "United Kingdom"
    end

    test "renders with prompt" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} prompt="Choose option..." />
        """)

      assert html =~ "Choose option..."
      assert html =~ ~s(value="")
      assert html =~ "disabled"
    end
  end

  describe "multi-select badge removal" do
    test "hook is attached to wrapper div for proper event bubbling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix"]} value={["Elixir"]} multiple={true} />
        """)

      # Hook should be on wrapper div, not select element
      assert html =~ ~s(phx-hook="Pulsar.Components.Select.PulsarSelect")
      # Wrapper should have ID for event targeting (uses field name + -wrapper)
      assert html =~ ~s(id="skills-wrapper")
    end

    test "remove button uses 'Remove' label by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir"]} value={["Elixir"]} multiple={true} />
        """)

      assert html =~ ~s(aria-label="Remove Elixir")
    end

    test "remove_label localizes the badge remove button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={["Elixir"]}
          value={["Elixir"]}
          multiple={true}
          remove_label="Quitar"
        />
        """)

      assert html =~ ~s(aria-label="Quitar Elixir")
      refute html =~ ~s(aria-label="Remove Elixir")
    end

    test "colocated hook script is present for multi-select" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix"]} value={["Elixir"]} multiple={true} />
        """)

      # Should contain JavaScript hook comment
      assert html =~ "<!-- JavaScript hook for multi-select badge removal -->"
      # Should contain script tag reference (even if script content is not rendered)
      # The hook functionality is tested by integration testing in the showcase app
    end

    test "JS dispatch targets wrapper element for proper event bubbling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={[{"Elixir", "elixir"}]} value={["elixir"]} multiple={true} />
        """)

      # Should dispatch to wrapper element
      assert html =~ ~s(&quot;pulsar:remove-selection&quot;)
      # Should target wrapper element
      assert html =~ ~s(to&quot;:&quot;#)
      assert html =~ ~s(-wrapper&quot;)
    end

    test "data_has_value correctly handles empty arrays" do
      assigns = %{}

      # Test with empty array
      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix"]} value={[]} multiple={true} />
        """)

      assert html =~ ~s(data-has-value="false")

      # Test with nil
      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix"]} value={nil} multiple={true} />
        """)

      assert html =~ ~s(data-has-value="false")

      # Test with actual values
      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix"]} value={["Elixir"]} multiple={true} />
        """)

      assert html =~ ~s(data-has-value="true")
    end

    test "supports %JS{} command for on_remove_badge" do
      assigns = %{
        custom_js: %JS{} |> JS.hide(to: "#modal")
      }

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}]}
          value={["elixir"]}
          multiple={true}
          on_remove_badge={@custom_js}
        />
        """)

      # Should handle %JS{} command and dispatch event
      assert html =~ ~s(&quot;pulsar:remove-selection&quot;)
      assert html =~ ~s(&quot;hide&quot;)
    end

    test "supports a JS.push command for on_remove_badge" do
      assigns = %{custom_js: JS.push("custom_remove")}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}]}
          value={["elixir"]}
          multiple={true}
          on_remove_badge={@custom_js}
        />
        """)

      # Should run the caller's push and dispatch the internal event
      assert html =~ ~s(&quot;pulsar:remove-selection&quot;)
      assert html =~ ~s(&quot;custom_remove&quot;)
    end

    test "badge component doesn't have unused phx-value-option attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}]}
          value={["elixir"]}
          multiple={true}
        />
        """)

      # Extract the badge portion (before the button)
      badge_section =
        html
        |> String.split("<button")
        |> List.first()

      # Badge itself should not have phx-value-option
      refute badge_section =~ ~s(phx-value-option="elixir")

      # But button should have it
      button_section =
        html
        |> String.split("<button")
        |> List.last()

      assert button_section =~ ~s(phx-value-option="elixir")
    end

    test "grouped options work correctly with badge display" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="location"
          options={[
            "North America": [{"United States", "US"}, {"Canada", "CA"}],
            Europe: [{"United Kingdom", "UK"}, {"Germany", "DE"}]
          ]}
          value={["US", "UK"]}
          multiple={true}
        />
        """)

      # Should show correct labels for grouped options
      assert html =~ "United States"
      assert html =~ "United Kingdom"
      # Should have remove buttons for both
      assert html =~ ~s(phx-value-option="US")
      assert html =~ ~s(phx-value-option="UK")
    end

    test "handles mixed option formats in multi-select badges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="mixed"
          options={[
            "Simple",
            {"Complex Label", "complex_value"},
            {:atom_label, "atom_value"}
          ]}
          value={["Simple", "complex_value", "atom_value"]}
          multiple={true}
        />
        """)

      # Should display correct labels
      assert html =~ "Simple"
      assert html =~ "Complex Label"
      assert html =~ "atom_label"
      # Should have correct values in buttons
      assert html =~ ~s(phx-value-option="Simple")
      assert html =~ ~s(phx-value-option="complex_value")
      assert html =~ ~s(phx-value-option="atom_value")
    end
  end

  describe "multi-select functionality" do
    test "enables multi-select mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix", "LiveView"]} multiple={true} />
        """)

      assert html =~ ~s(multiple)
      assert html =~ ~s(data-multiple="true")
      # Auto-appended for form submission
      assert html =~ ~s(name="skills[]")
    end

    test "displays badges for selected values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[
            {"Elixir", "elixir"},
            {"Phoenix", "phoenix"},
            {"LiveView", "liveview"}
          ]}
          value={["elixir", "phoenix"]}
          multiple={true}
        />
        """)

      # Should have badges container
      assert html =~ ~s(class="flex flex-wrap gap-2")
      # Should display selected badges
      assert html =~ "Elixir"
      assert html =~ "Phoenix"
      # Should have remove buttons with JS dispatch event handling
      assert html =~ ~s(&quot;pulsar:remove-selection&quot;)
      assert html =~ ~s(phx-value-option="elixir")
      assert html =~ ~s(phx-value-option="phoenix")
    end

    test "handles mixed option formats for badges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="mixed"
          options={[
            "Simple",
            {"Labeled", "value"}
          ]}
          value={["Simple", "value"]}
          multiple={true}
        />
        """)

      # Should display both types correctly
      assert html =~ "Simple"
      assert html =~ "Labeled"
    end

    test "handles empty selection for multi-select" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["A", "B", "C"]} value={[]} multiple={true} />
        """)

      # Should not show badges container when empty
      refute html =~ ~s(class="flex flex-wrap gap-2")
    end

    test "badge close buttons have aria-label for accessibility" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}, {"Phoenix", "phoenix"}]}
          value={["elixir"]}
          multiple={true}
        />
        """)

      # Should have aria-label on close button with option label
      assert html =~ ~s(aria-label="Remove Elixir")
      # Should have remove button with JS dispatch event handler
      assert html =~ ~s(&quot;pulsar:remove-selection&quot;)
      assert html =~ ~s(phx-value-option="elixir")
    end

    test "omits the dropdown chevron and its reserved padding in multi-select mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="skills" options={["Elixir", "Phoenix", "LiveView"]} multiple={true} />
        """)

      # Native multi-select renders as a listbox; the single-select chevron and
      # its reserved right-padding gutter must not be present.
      refute html =~ "hero-chevron-down"
      refute html =~ "pr-10"
    end
  end

  describe "states and accessibility" do
    test "handles disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} disabled={true} />
        """)

      assert html =~ ~s(disabled)
      assert html =~ "cursor-not-allowed"
      assert html =~ "opacity-disabled"
      assert html =~ "pointer-events-none"
    end

    test "disabled arrow has reduced opacity" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} disabled={true} />
        """)

      # Should have arrow container with opacity-disabled when disabled
      assert html =~
               ~s(class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none text-neutral opacity-disabled")
    end

    test "handles required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} required={true} />
        """)

      assert html =~ ~s(required)
      assert html =~ ~s(data-required="true")
    end

    test "includes focus ring classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} />
        """)

      assert html =~ "focus-visible:ring-2"
      assert html =~ "focus-visible:ring-ring"
    end

    test "does not render a dangling aria-describedby when field has errors but no caller-provided describedby" do
      field = %FormField{
        errors: [{"is required", []}],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}]} />
        """)

      refute html =~ "aria-describedby="
    end

    test "passes caller-provided aria-describedby through unchanged (no merging with internal IDs)" do
      field = %FormField{
        errors: [{"is required", []}],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}]} aria-describedby="caller-help" />
        """)

      assert html =~ ~s(aria-describedby="caller-help")
      refute html =~ ~s(aria-describedby="caller-help user_country-errors")
    end

    test "includes custom arrow styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} color="primary" />
        """)

      # Should have arrow container
      assert html =~ "absolute inset-y-0 right-0"
      assert html =~ "pointer-events-none"
      # Should have arrow icon using Icon component
      assert html =~ "hero-chevron-down"
      # Should have color styling for arrow
      assert html =~ "text-primary"
    end
  end

  describe "automatic error state handling" do
    test "error state overrides to danger styling" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is required", []}],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should show danger styling automatically
      assert html =~ "bg-danger/10"
      assert html =~ "text-danger"
    end

    test "no error state uses neutral color" do
      # Create a form field without errors
      field = %FormField{
        errors: [],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: "us"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should use neutral color
      assert html =~ "bg-neutral/10"
      assert html =~ "text-neutral"
    end

    test "sets aria-invalid to 'true' when field has errors" do
      # Create a form field with errors
      field = %FormField{
        errors: [{"is required", []}],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should have aria-invalid="true" when field has errors
      assert html =~ ~s(aria-invalid="true")
      refute html =~ ~s(aria-invalid="false")
    end

    test "omits aria-invalid when field has no errors (reduces noise)" do
      # Create a form field without errors
      field = %FormField{
        errors: [],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: "us"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should not have aria-invalid when field has no errors (reduces noise)
      refute html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "omits aria-invalid when no field is provided (reduces noise)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should not have aria-invalid when no field provided (reduces noise)
      refute html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end
  end

  describe "Phoenix form integration" do
    test "accepts field attribute for form integration" do
      field = %FormField{
        errors: [],
        field: :country,
        form: %Form{},
        id: "user_country",
        name: "user[country]",
        value: "us"
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Select.select field={@field} options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Note: The actual implementation passes field to Stellar, which handles the attributes
      # The test passes if the select element is rendered properly with Stellar handling
      assert html =~ ~s(<select)
      assert html =~ ~s(value="us">US)
      assert html =~ ~s(value="ca">CA)
    end

    test "supports manual name and value when no field provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="category" value="tech" options={[{"Tech", "tech"}, {"Design", "design"}]} />
        """)

      assert html =~ ~s(name="category")
      # Value is handled by Phoenix options_for_select
    end
  end

  describe "Twm integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} class="border-red-500 min-h-16" />
        """)

      # Twm should resolve conflicts
      # Custom border should override
      assert html =~ "border-red-500"
      # Custom height should override
      assert html =~ "min-h-16"
    end

    test "preserves non-conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} class="w-full shadow-lg" />
        """)

      # Should include both original and custom classes
      assert html =~ "w-full"
      assert html =~ "shadow-lg"
      # Original background preserved
      assert html =~ "bg-neutral/10"
    end
  end

  describe "data attributes" do
    test "includes standard data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} multiple={false} required={true} />
        """)

      # Should include standard data attributes
      assert html =~ ~s(data-multiple="false")
      assert html =~ ~s(data-required="true")
      assert html =~ ~s(data-disabled="false")
    end

    test "includes state attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} />
        """)

      # Should include data-state attribute for styling
      assert html =~ ~s(data-state="closed")
    end
  end

  describe "edge cases" do
    test "requires name when field is not provided" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires :name when :field is not provided/, fn ->
        rendered_to_string(~H"""
        <Select.select options={["A", "B", "C"]} />
        """)
      end
    end

    test "passes through LiveView events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} phx-change="validate" phx-debounce="300" data-testid="test-select" />
        """)

      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-debounce="300")
      assert html =~ ~s(data-testid="test-select")
    end

    test "handles complex option structures" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="location"
          options={[
            "North America": [
              {"United States", "US"},
              {"Canada", "CA"},
              {"Mexico", "MX"}
            ],
            Europe: [
              {"United Kingdom", "UK"},
              {"Germany", "DE"}
            ]
          ]}
        />
        """)

      # Should render optgroups
      assert html =~ ~s(<optgroup)
      assert html =~ "North America"
      assert html =~ "Europe"
      # Should render all options
      assert html =~ "United States"
      assert html =~ "Canada"
      assert html =~ "Mexico"
      assert html =~ "United Kingdom"
      assert html =~ "Germany"
    end

    test "handles badges with custom on_remove_badge command" do
      assigns = %{custom_js: JS.push("custom_remove")}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}, {"Phoenix", "phoenix"}]}
          value={["elixir"]}
          multiple={true}
          on_remove_badge={@custom_js}
        />
        """)

      # Should use custom badge event with JS dispatch + push handling
      assert html =~ ~s(&quot;custom_remove&quot;)
      assert html =~ ~s(phx-value-option="elixir")
    end
  end
end
