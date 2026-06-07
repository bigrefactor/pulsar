defmodule Pulsar.Components.InputOtpTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.HTML.FormField
  alias Pulsar.Components.InputOtp

  describe "input_otp/1 structure" do
    test "renders one real input with one-time-code autofill and the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={6} />
        """)

      # exactly one real <input>
      assert html |> String.split("<input") |> length() == 2
      assert html =~ ~s(autocomplete="one-time-code")
      assert html =~ ~s(maxlength="6")
      assert html =~ ~s(phx-hook="Pulsar.Components.InputOtp.PulsarInputOtp")
      assert html =~ ~s(inputmode="numeric")
    end

    test "renders one painted slot per length, all aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={4} />
        """)

      assert html |> String.split(~s(data-slot=)) |> length() == 5
      assert html =~ ~s(aria-hidden="true")
    end

    test "default variant is outline; solid and ghost are selectable" do
      assigns = %{}
      outline = rendered_to_string(~H|<InputOtp.input_otp id="o" />|)
      solid = rendered_to_string(~H|<InputOtp.input_otp id="s" variant="solid" />|)
      ghost = rendered_to_string(~H|<InputOtp.input_otp id="g" variant="ghost" />|)

      assert outline =~ "border-border-strong"
      assert solid =~ "bg-neutral/10"
      assert ghost =~ "border-b-2"
    end

    test "disabled dims the slots" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOtp.input_otp id="d" disabled />|)
      assert html =~ "opacity-disabled"
    end

    test "sets aria-invalid from invalid" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOtp.input_otp id="o" invalid />|)
      assert html =~ ~s(aria-invalid="true")
    end

    test "derives id/name/value from a Phoenix field" do
      field = %FormField{id: "user_otp", name: "user[otp]", value: "12", field: :otp, form: nil, errors: []}
      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp field={@field} length={6} />
        """)

      assert html =~ ~s(id="user_otp")
      assert html =~ ~s(name="user[otp]")
      assert html =~ ~s(value="12")
    end
  end
end
