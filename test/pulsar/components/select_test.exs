defmodule Pulsar.Components.SelectTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Pulsar.Components.Select

  describe "select/1 basic functionality" do
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
      assert html =~ "dark:bg-dark-neutral/20"
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
      assert html =~ "dark:bg-dark-background"
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
      # Should have remove buttons (now uses JS command structure)
      assert html =~ ~s(phx-click="[[&quot;push&quot;,{&quot;event&quot;:&quot;remove_selection&quot;}]]")
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

      # Should have aria-label on close button
      assert html =~ ~s(aria-label="Remove item")
      # Should still have remove button (now uses JS command structure)
      assert html =~ ~s(phx-click="[[&quot;push&quot;,{&quot;event&quot;:&quot;remove_selection&quot;}]]")
      assert html =~ ~s(phx-value-option="elixir")
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
      assert html =~ "opacity-50"
      assert html =~ "pointer-events-none"
    end

    test "disabled arrow has reduced opacity" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} disabled={true} />
        """)

      # Should have arrow container with opacity-50 when disabled
      assert html =~
               ~s(class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none text-neutral dark:text-dark-neutral opacity-50")
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

      assert html =~ "focus:ring-2"
      assert html =~ "focus:ring-neutral/60"
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
      assert html =~ "dark:bg-dark-danger/20"
      assert html =~ "text-danger"
      assert html =~ "dark:text-dark-danger"
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

    test "sets aria-invalid to 'false' when field has no errors" do
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

      # Should have aria-invalid="false" when field has no errors
      assert html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "sets aria-invalid to 'false' when no field is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={[{"US", "us"}, {"CA", "ca"}]} />
        """)

      # Should have aria-invalid="false" when no field provided
      assert html =~ ~s(aria-invalid="false")
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

  describe "TailwindMerge integration" do
    test "properly merges conflicting classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} class="border-red-500 min-h-16" />
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
        <Select.select name="test" options={["A", "B", "C"]} class="w-full shadow-lg" />
        """)

      # Should include both original and custom classes
      assert html =~ "w-full"
      assert html =~ "shadow-lg"
      # Original background preserved
      assert html =~ "bg-neutral/10"
    end
  end

  describe "Stellar integration" do
    test "passes through Stellar data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} multiple={false} required={true} />
        """)

      # Should include Stellar's data attributes
      assert html =~ ~s(data-multiple="false")
      assert html =~ ~s(data-required="true")
      assert html =~ ~s(data-disabled="false")
      assert html =~ ~s(phx-hook="Stellar.Components.Select.StellarSelectState")
    end

    test "includes Stellar's JavaScript hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select name="test" options={["A", "B", "C"]} />
        """)

      # Should include the colocated hook attribute (script is embedded in Stellar component)
      assert html =~ ~s(phx-hook="Stellar.Components.Select.StellarSelectState")
      # Should include data-state attribute managed by the hook
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

    test "handles badges with custom phx-click-badge event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          name="skills"
          options={[{"Elixir", "elixir"}, {"Phoenix", "phoenix"}]}
          value={["elixir"]}
          multiple={true}
          on_remove_badge="custom_remove"
        />
        """)

      # Should use custom badge event (now uses JS command structure)
      assert html =~ ~s(phx-click="[[&quot;push&quot;,{&quot;event&quot;:&quot;custom_remove&quot;}]]")
      assert html =~ ~s(phx-value-option="elixir")
    end
  end
end
