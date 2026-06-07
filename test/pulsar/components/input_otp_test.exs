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

  describe "input_otp/1 options" do
    test "groups insert a separator and keep length slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={6} groups={[3, 3]} />
        """)

      # still 6 slots
      assert html |> String.split(~s(data-slot=)) |> length() == 7
      # one separator between the two groups
      assert html |> String.split(~s(px-1 text-muted-foreground)) |> length() == 2
    end

    test "numeric mode sets inputmode numeric; alphanumeric sets text" do
      assigns = %{}
      num = rendered_to_string(~H|<InputOtp.input_otp id="n" mode="numeric" />|)
      alpha = rendered_to_string(~H|<InputOtp.input_otp id="a" mode="alphanumeric" />|)

      assert num =~ ~s(inputmode="numeric")
      assert alpha =~ ~s(inputmode="text")
    end

    test "mask is exposed to the hook via data-mask" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOtp.input_otp id="m" mask />|)
      assert html =~ ~s(data-mask="true")
    end

    test "mode and length are exposed to the hook" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOtp.input_otp id="d" length={4} mode="alphanumeric" />|)
      assert html =~ ~s(data-length="4")
      assert html =~ ~s(data-mode="alphanumeric")
    end

    test "on_complete is encoded into data-on-complete; default is empty" do
      assigns = %{}

      with_cb =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="c" on_complete={Phoenix.LiveView.JS.push("verify")} />
        """)

      default = rendered_to_string(~H|<InputOtp.input_otp id="d" />|)

      assert with_cb =~ "verify"
      assert with_cb =~ "data-on-complete"
      # default %JS{} encodes to the empty "[]" the hook guards against
      assert default =~ ~s(data-on-complete="[]")
    end
  end
end
