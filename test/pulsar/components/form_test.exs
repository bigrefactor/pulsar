defmodule Pulsar.Components.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Form

  describe "form/1 basic functionality" do
    test "renders a form element with the inner block" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form}>
          <p>inner content</p>
        </Form.form>
        """)

      assert html =~ ~s(<form)
      assert html =~ "inner content"
    end

    test "exposes the form struct via :let" do
      assigns = %{form: to_form(%{"name" => "Alice"}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form :let={f} for={@form}>
          <input value={f[:name].value} name={f[:name].name} />
        </Form.form>
        """)

      assert html =~ ~s(value="Alice")
      assert html =~ ~s(name="test[name]")
    end

    test "forwards phx-change and phx-submit to the form element" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form} phx-change="validate" phx-submit="submit">
          <input type="text" />
        </Form.form>
        """)

      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-submit="submit")
    end

    test "forwards arbitrary HTML attributes via :rest" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form} class="custom-class" data-test-id="my-form">
          <input type="text" />
        </Form.form>
        """)

      assert html =~ ~s(class="custom-class")
      assert html =~ ~s(data-test-id="my-form")
    end
  end

  describe "form/1 accessibility hook" do
    test "attaches the colocated PulsarForm hook to the form element" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form}>
          <input type="text" />
        </Form.form>
        """)

      # phx-hook must reference the fully-qualified colocated hook name.
      # Phoenix rewrites the leading-dot literal `.PulsarForm` inside ~H
      # to the module's namespaced identifier; if that rewrite breaks
      # (e.g. dynamic interpolation), the hook silently never attaches.
      assert html =~ ~s(phx-hook="Pulsar.Components.Form.PulsarForm")
    end

    test "auto-generates an id when not provided (required for phx-hook)" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form}>
          <input type="text" />
        </Form.form>
        """)

      assert html =~ ~r/<form[^>]*\sid="[^"]+"/
    end

    test "uses caller-provided id when given" do
      assigns = %{form: to_form(%{}, as: :test)}

      html =
        rendered_to_string(~H"""
        <Form.form for={@form} id="my-form-id">
          <input type="text" />
        </Form.form>
        """)

      assert html =~ ~s(id="my-form-id")
    end
  end
end
