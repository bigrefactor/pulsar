defmodule Pulsar.DevApp.InputOtpLive do
  @moduledoc """
  A11y fixture for `Pulsar.Components.InputOtp`.

  The cells are deliberately unwrapped by any scroll container: an
  `overflow-x-auto` ancestor exempts a component from the 320 px reflow gate,
  so the gate would pass without measuring whether the slot row itself
  reflows. The ten-slot grouped cell is the one that needs the row to wrap.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.InputOtp

  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, variant: variant, sizes: @sizes)

    ~H"""
    <.fixture_page name={"input-otp-#{@variant}"} title={"Input OTP (#{@variant})"}>
      <.fixture_section name={"#{@variant}-sizes"} title={"#{@variant} · sizes"}>
        <div :for={size <- @sizes} class="py-1">
          <InputOtp.input_otp
            id={"otp-#{@variant}-#{size}"}
            variant={@variant}
            size={size}
            length={6}
            aria-label={"#{@variant} #{size} one-time code"}
            data-fixture-cell={"#{@variant}-#{size}"}
          />
        </div>
      </.fixture_section>

      <.fixture_section name={"#{@variant}-options"} title={"#{@variant} · options"}>
        <div class="py-1">
          <InputOtp.input_otp
            id={"otp-#{@variant}-grouped"}
            variant={@variant}
            length={6}
            groups={[3, 3]}
            aria-label={"#{@variant} grouped one-time code"}
            data-fixture-cell={"#{@variant}-grouped"}
          />
        </div>
        <div class="py-1">
          <InputOtp.input_otp
            id={"otp-#{@variant}-masked"}
            variant={@variant}
            length={4}
            mask
            aria-label={"#{@variant} masked one-time code"}
            data-fixture-cell={"#{@variant}-masked"}
          />
        </div>
        <div class="py-1">
          <InputOtp.input_otp
            id={"otp-#{@variant}-invalid"}
            variant={@variant}
            length={6}
            invalid
            aria-label={"#{@variant} invalid one-time code"}
            data-fixture-cell={"#{@variant}-invalid"}
          />
        </div>
        <div class="py-1">
          <InputOtp.input_otp
            id={"otp-#{@variant}-long"}
            variant={@variant}
            length={10}
            groups={[5, 5]}
            mode="alphanumeric"
            aria-label={"#{@variant} long grouped recovery code"}
            data-fixture-cell={"#{@variant}-long"}
          />
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
