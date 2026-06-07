defmodule Pulsar.Components.FieldTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Pulsar.Components.Field

  # Helper function to create a form field
  defp create_field(field_name, value \\ "", errors \\ []) do
    # Create a form with params that indicate the field has been used
    # This simulates a form submission where the field was interacted with
    field_str = "#{field_name}"

    params =
      if errors == [] do
        # If no errors, we can have empty params
        %{}
      else
        # If we want to show errors, create params that indicate the field was used
        %{field_str => value}
      end

    %FormField{
      errors: errors,
      field: field_name,
      form: %Form{params: params},
      id: "user_#{field_name}",
      name: "user[#{field_name}]",
      value: value
    }
  end

  describe "field/1 basic functionality" do
    test "renders field with auto-generated label" do
      field = create_field(:email, "test@example.com")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Should contain field wrapper
      assert html =~ ~s(<div)
      # Should have auto-generated label
      assert html =~ "Email"
      # Should have input
      assert html =~ ~s(<input)
      assert html =~ ~s(type="email")
      assert html =~ ~s(value="test@example.com")
    end

    test "renders field with custom label" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email">
          <:label>Email Address</:label>
        </Field.field>
        """)

      # Should have custom label instead of auto-generated
      assert html =~ "Email Address"
      # Should still contain the basic "Email" word too since "Email Address" contains it
    end

    test "renders field with description" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email">
          <:label>Email</:label>
          <:description>We'll never share your email</:description>
        </Field.field>
        """)

      # Should contain description
      assert html =~ "We'll never share your email"
      assert html =~ "text-muted-foreground"
    end

    test "renders field without label for checkbox type" do
      field = create_field(:terms, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox" />
        """)

      # Checkbox fields don't auto-generate labels
      refute html =~ ">Terms<"
    end

    test "renders field without label for switch type" do
      field = create_field(:enabled, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="switch" />
        """)

      # Switch fields don't auto-generate labels
      refute html =~ ">Enabled<"
    end
  end

  describe "label generation" do
    test "generates proper labels from field names using Phoenix.Naming.humanize" do
      test_cases = [
        {:email, "Email"},
        {:first_name, "First name"},
        {:user_email, "User email"},
        {:created_at, "Created at"},
        {:is_active, "Is active"}
      ]

      for {field_name, expected_label} <- test_cases do
        field = create_field(field_name)
        assigns = %{field: field}

        html =
          rendered_to_string(~H"""
          <Field.field field={@field} />
          """)

        assert html =~ expected_label
      end
    end
  end

  describe "error handling" do
    test "displays field errors" do
      field = create_field(:email, "", [{"can't be blank", []}, {"is invalid", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Should display both errors (HTML escaped)
      assert html =~ "can&#39;t be blank"
      assert html =~ "is invalid"
      # Should have error styling
      assert html =~ "text-danger"
      # Should have error icon (Heroicon)
      assert html =~ "hero-exclamation-circle"
    end

    test "translates errors through Gettext, interpolating non-count bindings" do
      field = create_field(:name, "", [{"must be %{type}", [type: "valid"]}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="text" />
        """)

      # Routed through Gettext.dgettext/4, which interpolates %{type}.
      assert html =~ "must be valid"
    end

    test "translates errors through Gettext with count-based plural interpolation" do
      field = create_field(:password, "", [{"should be at least %{count} character(s)", [count: 8]}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="password" />
        """)

      # Routed through Gettext.dngettext/6 (the :count branch), interpolating %{count}.
      assert html =~ "should be at least 8 character(s)"
    end

    test "error container has aria-live attribute for screen readers" do
      field = create_field(:email, "", [{"is required", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Should have aria-live="polite" on error container
      assert html =~ ~s(aria-live="polite")
    end

    test "passes error state to label" do
      field = create_field(:email, "", [{"is required", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Label should receive error state (checked via Pulsar.Components.Label)
      # This is passed via the `error={@has_errors}` attribute
      assert html =~ "is required"
    end

    test "no error display when field has no errors" do
      field = create_field(:email, "test@example.com")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Should not display error section
      refute html =~ "text-danger-600"
      refute html =~ "can't be blank"
    end
  end

  describe "input type rendering" do
    test "renders text input by default" do
      field = create_field(:name)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} />
        """)

      assert html =~ ~s(type="text")
    end

    test "renders email input" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      assert html =~ ~s(type="email")
    end

    test "renders select field" do
      field = create_field(:country)
      assigns = %{field: field, options: [{"US", "us"}, {"UK", "uk"}]}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="select" options={@options} />
        """)

      assert html =~ ~s(<select)
      assert html =~ ">US<"
      assert html =~ ">UK<"
    end

    test "renders textarea field" do
      field = create_field(:bio)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="textarea" rows="3" />
        """)

      assert html =~ ~s(<textarea)
      assert html =~ ~s(rows="3")
    end

    test "renders checkbox field" do
      field = create_field(:terms, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox">
          <:label>I agree to the terms</:label>
        </Field.field>
        """)

      # Should render checkbox component (exact implementation depends on Checkbox component)
      assert html =~ "I agree to the terms"
    end

    test "renders switch field" do
      field = create_field(:enabled, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="switch">
          <:label>Enable notifications</:label>
        </Field.field>
        """)

      # Should render switch component
      assert html =~ "Enable notifications"
    end

    test "renders radio field" do
      field = create_field(:plan, "basic")
      assigns = %{field: field, options: [{"Basic", "basic"}, {"Pro", "pro"}]}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="radio" options={@options} />
        """)

      # Should render radio group component
      # Exact assertion depends on RadioGroup component implementation
      assert html =~ "Basic"
      assert html =~ "Pro"
    end

    test "renders file input field" do
      field = create_field(:avatar)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="file" accept="image/*" />
        """)

      assert html =~ ~s(type="file")
      assert html =~ ~s(accept="image/*")
    end

    test "file input does not include value attribute" do
      field = create_field(:avatar, "some_value")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="file" />
        """)

      # File inputs should not have value attribute even if field has a value
      refute html =~ ~r(<input[^>]*type="file"[^>]*value=)
      assert html =~ ~s(type="file")
    end

    test "non-file input includes value attribute" do
      field = create_field(:email, "test@example.com")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      # Non-file inputs should include value attribute
      assert html =~ ~s(value="test@example.com")
      assert html =~ ~s(type="email")
    end

    test "text input includes value attribute when field has value" do
      field = create_field(:name, "John Doe")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="text" />
        """)

      assert html =~ ~s(value="John Doe")
      assert html =~ ~s(type="text")
    end

    test "text input with empty value still includes value attribute" do
      field = create_field(:name, "")
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="text" />
        """)

      # Even empty values should include value attribute for non-file inputs
      assert html =~ ~s(value="")
      assert html =~ ~s(type="text")
    end

    test "renders range input field" do
      field = create_field(:volume, 50)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="range" min="0" max="100" step="10" />
        """)

      assert html =~ ~s(type="range")
      assert html =~ ~s(min="0")
      assert html =~ ~s(max="100")
      assert html =~ ~s(step="10")
      assert html =~ ~s(value="50")
    end
  end

  describe "decorators" do
    test "passes decorators to input component" do
      field = create_field(:price)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="number">
          <:start_decorator>$</:start_decorator>
          <:end_decorator>USD</:end_decorator>
        </Field.field>
        """)

      # Should pass decorators to underlying Input component
      assert html =~ "$"
      assert html =~ "USD"
    end

    test "decorators only work with compatible input types" do
      field = create_field(:country)
      assigns = %{field: field, options: [{"US", "us"}]}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="select" options={@options}>
          <:start_decorator>$</:start_decorator>
        </Field.field>
        """)

      # Select component doesn't support decorators, so they should be ignored
      # This test verifies the field doesn't crash when decorators are provided for incompatible types
      assert html =~ ~s(<select)
    end
  end

  describe "attributes pass-through" do
    test "passes variant, color, and size to underlying components" do
      field = create_field(:name)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} variant="solid" color="primary" size="lg" />
        """)

      # These attributes should be passed to the underlying Input component
      # Exact assertions depend on Input component implementation
      assert html =~ ~s(<input)
    end

    test "passes required attribute to underlying components and label" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" required />
        """)

      # Required should be passed to both label and input
      assert html =~ ~s(required)
    end

    test "passes required attribute to underlying select" do
      field = create_field(:country)
      assigns = %{field: field, options: [{"US", "us"}, {"UK", "uk"}]}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="select" options={@options} required />
        """)

      assert html =~ ~r/<select[^>]*\srequired[\s>]/
    end

    test "passes field-specific attributes" do
      field = create_field(:age)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="number" min="0" max="150" step="1" />
        """)

      # Number-specific attributes should be passed through
      assert html =~ ~s(min="0")
      assert html =~ ~s(max="150")
      assert html =~ ~s(step="1")
    end

    test "passes placeholder attribute" do
      field = create_field(:search)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} placeholder="Search..." />
        """)

      assert html =~ ~s(placeholder="Search...")
    end
  end

  describe "slot customization" do
    test "label slot with custom class" do
      field = create_field(:name)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field}>
          <:label class="font-bold text-primary-700">Full Name</:label>
        </Field.field>
        """)

      # Should render custom label with custom class
      assert html =~ "Full Name"
      # Class should be passed to Label component
      assert html =~ "font-bold text-primary-700"
    end

    test "label slot with custom size" do
      field = create_field(:title)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} size="md">
          <:label size="lg">Document Title</:label>
        </Field.field>
        """)

      # Should use label-specific size instead of field size
      assert html =~ "Document Title"
    end

    test "description slot with custom class" do
      field = create_field(:bio)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field}>
          <:description class="italic text-blue-600">Tell us about yourself</:description>
        </Field.field>
        """)

      # Should render description with custom class
      assert html =~ "Tell us about yourself"
      assert html =~ "italic text-blue-600"
    end
  end

  describe "inline labels for checkbox and switch" do
    test "checkbox field renders with inline label" do
      field = create_field(:terms, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox">
          <:label>I agree to the terms</:label>
        </Field.field>
        """)

      # Should wrap checkbox and label in a single label element
      assert html =~ ~s(<label for="user_terms")
      assert html =~ "I agree to the terms"
      # Should have inline-flex layout
      assert html =~ "inline-flex items-center gap-2"
      # Should NOT render separate Label component above
      refute html =~ ~s(<div class="flex flex-col gap-1">)
    end

    test "checkbox field with auto-generated inline label" do
      field = create_field(:terms_accepted, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox" />
        """)

      # Should have auto-generated label inline
      assert html =~ "Terms accepted"
      assert html =~ ~s(<label for="user_terms_accepted")
      assert html =~ "inline-flex items-center gap-2"
    end

    test "switch field renders with inline label" do
      field = create_field(:notifications, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="switch">
          <:label>Enable notifications</:label>
        </Field.field>
        """)

      # Should wrap switch and label in a single label element
      assert html =~ ~s(<label for="user_notifications")
      assert html =~ "Enable notifications"
      # Should have inline-flex layout
      assert html =~ "inline-flex items-center gap-2"
      # Should NOT render separate Label component above
      refute html =~ ~s(<div class="flex flex-col gap-1">)
    end

    test "switch field with auto-generated inline label" do
      field = create_field(:dark_mode, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="switch" />
        """)

      # Should have auto-generated label inline
      assert html =~ "Dark mode"
      assert html =~ ~s(<label for="user_dark_mode")
      assert html =~ "inline-flex items-center gap-2"
    end

    test "inline labels inherit error styling" do
      field = create_field(:terms, false, [{"must be accepted", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox">
          <:label>I agree to the terms</:label>
        </Field.field>
        """)

      # Inline label should have error color classes
      assert html =~ "text-danger"
    end

    test "inline labels support custom classes from label slot" do
      field = create_field(:premium, false)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="checkbox">
          <:label class="font-bold text-blue-600">Upgrade to Premium</:label>
        </Field.field>
        """)

      # Should include custom classes and base classes (where not conflicting)
      assert html =~ "font-bold text-blue-600"
      assert html =~ "leading-none"
      assert html =~ "peer-disabled:cursor-not-allowed peer-disabled:opacity-disabled"
    end
  end

  describe "field wrapper customization" do
    test "custom field wrapper class" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} class="mb-8 border p-4" />
        """)

      # Should apply custom classes to wrapper
      assert html =~ "mb-8 border p-4"
    end

    test "field wrapper supports layout classes" do
      field = create_field(:email)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} class="grid grid-cols-2 gap-4" />
        """)

      # Should apply grid layout classes
      assert html =~ "grid grid-cols-2 gap-4"
    end
  end

  describe "accessibility (ARIA)" do
    test "radio group uses aria-labelledby instead of for attribute" do
      field = create_field(:plan, "basic")
      assigns = %{field: field, options: [{"Basic", "basic"}, {"Pro", "pro"}]}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="radio" options={@options}>
          <:label>Choose Plan</:label>
        </Field.field>
        """)

      # Should have label with id but no for attribute
      assert html =~ ~s(id="user_plan-label")
      refute html =~ ~s(for="user_plan")
      # Should pass aria-labelledby to radio group
      assert html =~ ~s(aria-labelledby="user_plan-label")
    end

    test "aria-describedby includes description and errors" do
      field = create_field(:email, "", [{"is required", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email">
          <:description>Your primary email address</:description>
        </Field.field>
        """)

      # Should have description and error with IDs
      assert html =~ ~s(id="user_email-description")
      assert html =~ ~s(id="user_email-error-0")
      # Should compose aria-describedby
      assert html =~ ~s(aria-describedby="user_email-description user_email-error-0")
    end

    test "aria-describedby works with description only" do
      field = create_field(:username)
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="text">
          <:description>Choose a unique username</:description>
        </Field.field>
        """)

      # Should have description ID only
      assert html =~ ~s(id="user_username-description")
      assert html =~ ~s(aria-describedby="user_username-description")
      refute html =~ "error-"
    end

    test "aria-describedby works with errors only" do
      field = create_field(:password, "", [{"is too short", []}, {"needs a number", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="password" />
        """)

      # Should have error IDs only
      assert html =~ ~s(id="user_password-error-0")
      assert html =~ ~s(id="user_password-error-1")
      assert html =~ ~s(aria-describedby="user_password-error-0 user_password-error-1")
      refute html =~ "description"
    end

    test "aria-invalid passed to all input types when errors present" do
      error_field = create_field(:test_field, "", [{"is invalid", []}])
      options = [{"Option", "opt"}]

      # Test each input type
      types_to_test = ["text", "select", "textarea", "checkbox", "switch", "radio"]

      for type <- types_to_test do
        assigns = %{field: error_field, options: options, type: type}

        html =
          rendered_to_string(~H"""
          <Field.field field={@field} type={@type} options={@options} />
          """)

        # Should pass invalid=true to underlying component
        # The exact aria-invalid rendering depends on each component's implementation
        assert html =~ "is invalid"
      end
    end
  end

  describe "field/1 type=otp" do
    test "renders an InputOtp wired to the field with a label" do
      form = to_form(%{"otp" => "12"}, as: :user)
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <Field.field field={@form[:otp]} type="otp" length={6}>
          <:label>Verification code</:label>
        </Field.field>
        """)

      assert html =~ ~s(phx-hook="Pulsar.Components.InputOtp.PulsarInputOtp")
      assert html =~ ~s(maxlength="6")
      assert html =~ ~s(name="user[otp]")
      # label points at the single real input
      assert html =~ ~s(for="user_otp")
      assert html =~ "Verification code"
    end

    test "forwards otp options and marks invalid on errors" do
      form = to_form(%{"otp" => ""}, as: :user, errors: [otp: {"is invalid", []}])
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <Field.field field={@form[:otp]} type="otp" length={4} groups={[2, 2]} mask show_errors={:always} />
        """)

      assert html =~ ~s(data-length="4")
      assert html =~ ~s(data-mask="true")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "is invalid"
    end
  end

  describe "show_errors attribute" do
    test "show_errors=:never hides errors" do
      field = create_field(:email, "", [{"is required", []}])
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" show_errors={:never} />
        """)

      # Should not display errors
      refute html =~ "is required"
      refute html =~ "text-danger-600"
    end

    test "show_errors=:always shows errors even for unused fields" do
      # Create field without indicating it was used/touched
      field = %FormField{
        errors: [{"is required", []}],
        field: :email,
        # Empty params = not submitted/touched
        form: %Form{params: %{}},
        id: "user_email",
        name: "user[email]",
        value: ""
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" show_errors={:always} />
        """)

      # Should display errors despite field not being used
      assert html =~ "is required"
      assert html =~ "text-danger"
    end

    test "show_errors=:touched is default behavior" do
      field = create_field(:email, "", [{"is required", []}])
      assigns = %{field: field}

      html_default =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" />
        """)

      html_explicit =
        rendered_to_string(~H"""
        <Field.field field={@field} type="email" show_errors={:touched} />
        """)

      # Both should produce the same result
      assert html_default == html_explicit
    end
  end
end
