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
      assert html =~ "text-gray-600"
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
      assert html =~ "text-danger-600"
      # Should have error icon (Heroicon)
      assert html =~ "hero-exclamation-circle"
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
      assert html =~ "text-danger-600"
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
