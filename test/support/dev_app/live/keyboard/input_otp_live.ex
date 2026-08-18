defmodule Pulsar.DevApp.Keyboard.InputOtpLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.InputOtp`.

  Renders a numeric OTP input whose `on_complete` pushes an event so the
  keyboard suite can prove the colocated `.PulsarInputOtp` hook actually
  receives keystrokes: digits paint and auto-advance the slots, non-digits
  are filtered, backspace clears, and a full code fires `on_complete`.

  The grouped cell carries a separator in the value people paste, so it is
  the one that catches the browser truncating a paste before the hook can
  normalise it.
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

      <.fixture_section name="grouped" title="Grouped alphanumeric (length 10)">
        <InputOtp.input_otp
          id="kbd-otp-grouped"
          length={10}
          groups={[5, 5]}
          mode="alphanumeric"
          aria-label="Grouped recovery code"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
