defmodule Pulsar.Components.SwitchTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Pulsar.Components.Switch

  # Helper to create a proper FormField struct
  defp create_field(name, value, errors \\ []) do
    %FormField{
      errors: errors,
      field: String.to_atom(name),
      form: %Form{
        errors: [],
        name: "form",
        params: %{},
        source: %{name => value}
      },
      id: "form_#{name}",
      name: "form[#{name}]",
      value: value
    }
  end

  describe "switch/1 basic functionality" do
    test "renders switch with default props" do
      assigns = %{}

      html = rendered_to_string(~H[<Switch.switch name="test_switch" />])

      assert html =~ ~s(<input type="checkbox")
      assert html =~ ~s(name="test_switch")
      assert html =~ ~s(value="true")
      assert html =~ ~s(class="sr-only peer")
      assert html =~ ~s(role="presentation")
      assert html =~ ~s(phx-click=)
      # The click target is the wrapper, sized to a ≥24px hit box (WCAG 2.5.8)
      assert html =~ "min-h-6"
    end

    test "renders with field attribute" do
      field = create_field("notifications", false)
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      assert html =~ ~s(id="form_notifications")
      assert html =~ ~s(name="form[notifications]")
      assert html =~ ~s(value="true")
      # Check that checkbox input doesn't have checked attribute
      refute html =~ ~r/type="checkbox"[^>]*\schecked/
    end

    test "renders checked state when field value matches switch value" do
      # Use string to match switch value
      field = create_field("notifications", "true")
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      # Check that checkbox input has checked attribute
      assert html =~ ~r/type="checkbox"[^>]*\schecked/
    end

    test "raises error when neither field nor name is provided" do
      assigns = %{}

      assert_raise ArgumentError, ~r/Switch requires :field or :name/, fn ->
        rendered_to_string(~H[<Switch.switch />])
      end
    end
  end

  describe "switch/1 variants and styling" do
    test "applies default variant and color classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" />])

      # Default variant is solid, color is primary
      assert html =~ "peer-checked:bg-primary/90"
    end

    test "applies outline variant classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="outline" color="success" />])

      assert html =~ "peer-checked:bg-success/10"
      assert html =~ "peer-checked:border-success"
    end

    test "applies ghost variant classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="ghost" color="danger" />])

      assert html =~ "peer-checked:bg-danger/15"
      assert html =~ "hover:peer-checked:bg-danger/20"
    end

    test "applies all supported colors" do
      colors = ~w(neutral primary secondary success danger warning info)

      for color <- colors do
        assigns = %{color: color}
        html = rendered_to_string(~H[<Switch.switch name="test" color={@color} />])
        assert html =~ "peer-checked:bg-#{color}/90"
      end
    end
  end

  describe "switch/1 off-state contrast (WCAG 1.4.11)" do
    test "solid track has border-strong fill with foreground hover/focus" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="solid" />])

      assert html =~ "bg-border-strong"
      assert html =~ "group-hover:bg-foreground/30"
      assert html =~ "peer-focus-visible:bg-foreground/30"
    end

    test "outline track has border-strong border with foreground hover/focus" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="outline" />])

      assert html =~ "border-border-strong"
      assert html =~ "group-hover:border-foreground"
      assert html =~ "peer-focus-visible:border-foreground"
      assert html =~ "bg-background"
    end

    test "ghost track has border-strong border that drops on checked" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="ghost" />])

      assert html =~ "border-border-strong"
      assert html =~ "peer-checked:border-transparent"
      assert html =~ "bg-muted/30"
      assert html =~ "group-hover:bg-muted/40"
      assert html =~ "peer-focus-visible:bg-muted/50"
    end

    test "checked-state track hover routes through group-hover (overlay-aware)" do
      assigns = %{}
      solid = rendered_to_string(~H[<Switch.switch name="test" variant="solid" />])
      ghost = rendered_to_string(~H[<Switch.switch name="test" variant="ghost" />])

      # The absolute click overlay covers the track, so the checked-state
      # brightening must fire via the group, not the track's own :hover.
      assert solid =~ "peer-checked:group-hover:"
      assert ghost =~ "group-hover:peer-checked:"
      refute solid =~ ~r/(?<!group-)hover:bg-primary\b/
    end

    test "outline thumb has border-strong border" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="outline" />])

      assert html =~ "border border-border-strong"
    end

    test "ghost thumb has border-strong border" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" variant="ghost" />])

      assert html =~ "border border-border-strong"
    end
  end

  describe "switch/1 sizes" do
    test "applies xs size classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" size="xs" />])

      # track size
      assert html =~ "h-3.5 w-7"
      # thumb size
      assert html =~ "h-2.5 w-2.5"
      # thumb translation
      assert html =~ "peer-checked:translate-x-[14px]"
    end

    test "applies md size classes (default)" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" />])

      # track size
      assert html =~ "h-5 w-11"
      # thumb size
      assert html =~ "h-4 w-4"
      # thumb translation
      assert html =~ "peer-checked:translate-x-[24px]"
    end

    test "applies xl size classes with custom sizing" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" size="xl" />])

      # track size
      assert html =~ "h-7 w-16"
      # thumb size (custom)
      assert html =~ "h-[22px] w-[22px]"
      # thumb translation
      assert html =~ "peer-checked:translate-x-[36px]"
    end
  end

  describe "switch/1 form states" do
    test "applies disabled state" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" disabled />])

      assert html =~ ~s(disabled)
      assert html =~ ~s(data-disabled="true")
    end

    test "applies required attribute" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" required />])

      assert html =~ ~s(required)
    end

    test "shows invalid state with field errors" do
      field = create_field("notifications", false, [{"can't be blank", []}])
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      assert html =~ ~s(aria-invalid="true")
      assert html =~ "ring-2 ring-danger"
      # Color should override to danger
      assert html =~ "peer-checked:bg-danger/90"
    end

    test "respects explicit invalid attribute" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" invalid />])

      assert html =~ ~s(aria-invalid="true")
      assert html =~ "ring-danger"
      assert html =~ "peer-checked:bg-danger/90"
    end
  end

  describe "switch/1 loading state" do
    test "shows loading spinner when loading=true" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" loading />])

      assert html =~ ~s(data-loading="true")
      assert html =~ ~s(<svg)
      assert html =~ ~s(animate-spin)
    end

    test "hides spinner when show_loading_spinner=false" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" loading show_loading_spinner={false} />])

      assert html =~ ~s(data-loading="true")
      refute html =~ ~s(<svg)
      refute html =~ ~s(animate-spin)
    end

    test "shows custom loading content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="test" loading>
          <:loading_content>
            <div class="custom-loader">Loading...</div>
          </:loading_content>
        </Switch.switch>
        """)

      assert html =~ ~s(data-loading="true")
      assert html =~ ~s(custom-loader)
      assert html =~ ~s(Loading...)
      # Default spinner should not appear
      refute html =~ ~s(<svg)
    end

    test "adjusts spinner size based on switch size" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" size="xs" loading />])
      # xs spinner size
      assert html =~ ~s(h-2 w-2)

      html = rendered_to_string(~H[<Switch.switch name="test" size="xl" loading />])
      # xl spinner size
      assert html =~ ~s(h-6 w-6)
    end
  end

  describe "switch/1 accessibility" do
    test "includes proper ARIA attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" aria_label="Enable notifications" />])

      assert html =~ ~s(aria-label="Enable notifications")
    end

    test "supports aria_labelledby" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" aria_labelledby="label-id" />])

      assert html =~ ~s(aria-labelledby="label-id")
    end

    test "sets aria-invalid for field errors" do
      field = create_field("test", false, [{"is required", []}])
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      assert html =~ ~s(aria-invalid="true")
    end

    test "does not set aria-invalid when no errors" do
      field = create_field("test", false)
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      refute html =~ ~s(aria-invalid)
    end

    test "renders role=\"switch\" on the input" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="notifications" />])

      assert html =~ ~r/type="checkbox"[^>]*role="switch"/
    end

    test "renders aria-checked=\"true\" when checked" do
      field = create_field("notifications", "true")
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      assert html =~ ~s(aria-checked="true")
    end

    test "renders aria-checked=\"false\" when not checked" do
      field = create_field("notifications", false)
      assigns = %{field: field}

      html = rendered_to_string(~H[<Switch.switch field={@field} />])

      assert html =~ ~s(aria-checked="false")
    end
  end

  describe "switch/1 form integration" do
    test "renders hidden input for unchecked value" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" />])

      assert html =~ ~s(<input type="hidden")
      assert html =~ ~s(name="test")
      assert html =~ ~s(value="false")
    end

    test "can disable hidden input rendering" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" render_hidden={false} />])

      refute html =~ ~s(<input type="hidden")
    end

    test "uses custom unchecked value" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" unchecked_value="off" />])

      assert html =~ ~s(value="off")
    end

    test "supports custom checked value" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" value="on" />])

      assert html =~ ~s(value="on")
    end
  end

  describe "switch/1 custom classes and attributes" do
    test "merges custom classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" class="custom-class" />])

      assert html =~ ~s(custom-class)
    end

    test "passes through global attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Switch.switch name="test" data-testid="my-switch" />])

      assert html =~ ~s(data-testid="my-switch")
    end
  end
end
