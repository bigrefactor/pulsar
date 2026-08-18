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

    # `maxlength` counts code characters only, so on a grouped code the browser
    # clips a pasted "ABCDE-FGHJK" to 10 characters *before* the hook strips the
    # separator, silently losing the last one. The hook's own
    # `v.slice(0, this.length)` runs after normalisation and is the real bound.
    test "sets no maxlength, so a separator-bearing paste reaches the hook intact" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={10} groups={[5, 5]} mode="alphanumeric" />
        """)

      refute html =~ "maxlength"
    end

    # Without `maxlength` the hook's `slice` is the only client-side bound, and
    # it is gone on a dead render or in a host app that never wired the
    # colocated hook. `pattern` rejects a wrong-length code at submit instead of
    # truncating it, so it bounds the value without clipping a formatted paste.
    test "sets a pattern of exactly length characters for the mode's alphabet" do
      assigns = %{}

      numeric = rendered_to_string(~H|<InputOtp.input_otp id="n" length={6} />|)

      alnum =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="a" length={10} groups={[5, 5]} mode="alphanumeric" />
        """)

      assert numeric =~ ~s(pattern="[0-9]{6}")
      assert alnum =~ ~s(pattern="[A-Za-z0-9]{10}")
    end

    test "the slot row wraps" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOtp.input_otp id="otp" length={10} />|)

      assert html =~ "flex-wrap"
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

    # Each group is its own non-wrapping row inside the wrapping outer row, so a
    # code that cannot fit breaks at a separator rather than mid-group.
    test "each group is its own row; ungrouped codes render no group rows" do
      assigns = %{}

      grouped =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={10} groups={[5, 5]} />
        """)

      flat = rendered_to_string(~H|<InputOtp.input_otp id="flat" length={10} />|)

      assert grouped |> String.split(~s(data-otp-group)) |> length() == 3
      refute flat =~ "data-otp-group"
    end

    # A separator that is its own item on the wrapping row can be pushed onto a
    # line by itself, stranded between the two groups it separates. Nested in
    # the preceding group's row it wraps with that group or not at all.
    test "the separator renders inside its group's row, not as a sibling of it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" length={10} groups={[5, 5]} />
        """)

      [_, after_separator] = String.split(html, ~s(px-1 text-muted-foreground))

      # The separator's group row closes after it; a sibling separator would
      # have to open the next group row instead.
      assert after_separator =~ ~r{\A[^<]*</span>\s*</div>}
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

  describe "input_otp/1 form attributes" do
    # These names are not LiveView globals, so an omitted `include:` costs an
    # "undefined attribute" warning at every call site. The attribute still reaches
    # the element via `@rest` either way, so the render assertions below cannot
    # catch the regression — this one can.
    test "declares autocomplete and opts form into :global so call sites do not warn" do
      attrs = InputOtp.__components__()[:input_otp].attrs
      global = Enum.find(attrs, &(&1.type == :global))
      include = Keyword.get(global.opts, :include, [])

      assert Enum.find(attrs, &(&1.name == :autocomplete))
      assert "form" in include
    end

    test "caller autocomplete overrides the default without duplicating the attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputOtp.input_otp id="otp" name="code" autocomplete="off" form="signup" />
        """)

      [input] = Regex.run(~r/<input[^>]*>/, html)

      assert input =~ ~s(autocomplete="off")
      assert input |> String.split(~s( autocomplete=)) |> length() == 2
    end
  end
end
