defmodule Pulsar.DevApp.InputOtpLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.InputOtp

  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)
    assigns = assign(assigns, variant: variant, sizes: @sizes)

    ~H"""
    <.fixture_page name={"input-otp-#{@variant}"} title={"Input OTP (#{@variant})"}>
      <.fixture_section name={"#{@variant}-sizes"} title={"#{@variant} · sizes"}>
        <InputOtp.input_otp
          :for={size <- @sizes}
          id={"otp-#{@variant}-#{size}"}
          variant={@variant}
          size={size}
          length={6}
          aria-label={"#{@variant} #{size} one-time code"}
          data-fixture-cell={"#{@variant}-#{size}"}
        />
      </.fixture_section>

      <.fixture_section name={"#{@variant}-options"} title={"#{@variant} · options"}>
        <InputOtp.input_otp
          id={"otp-#{@variant}-grouped"}
          variant={@variant}
          length={6}
          groups={[3, 3]}
          aria-label={"#{@variant} grouped one-time code"}
          data-fixture-cell={"#{@variant}-grouped"}
        />
        <InputOtp.input_otp
          id={"otp-#{@variant}-masked"}
          variant={@variant}
          length={4}
          mask
          aria-label={"#{@variant} masked one-time code"}
          data-fixture-cell={"#{@variant}-masked"}
        />
        <InputOtp.input_otp
          id={"otp-#{@variant}-invalid"}
          variant={@variant}
          length={6}
          invalid
          aria-label={"#{@variant} invalid one-time code"}
          data-fixture-cell={"#{@variant}-invalid"}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
