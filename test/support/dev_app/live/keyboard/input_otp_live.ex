defmodule Pulsar.DevApp.Keyboard.InputOtpLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.InputOtp`.

  Renders a numeric OTP input whose `on_complete` pushes an event so the
  keyboard suite can prove the colocated `.PulsarInputOtp` hook actually
  receives keystrokes: digits paint and auto-advance the slots, non-digits
  are filtered, backspace clears, and a full code fires `on_complete`.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.InputOtp

  def mount(_params, _session, socket) do
    {:ok, assign(socket, completes: 0)}
  end

  def handle_event("otp_complete", _params, socket) do
    {:noreply, update(socket, :completes, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-input-otp" title="InputOTP keyboard fixture">
      <p>Completions: <span id="kbd-otp-completes">{@completes}</span></p>

      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-otp-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="numeric" title="Numeric (length 6)">
        <InputOtp.input_otp
          id="kbd-otp"
          length={6}
          aria-label="One-time code"
          on_complete={JS.push("otp_complete")}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
