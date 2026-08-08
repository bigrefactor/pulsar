defmodule Pulsar.Integration.A11y.Keyboard.FlashTest do
  @moduledoc """
  Real-browser keyboard tests for Flash dismissal. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Flash keyboard dismissal" do
    # The Flash component's `.PulsarFlash` colocated hook listens for a
    # `keydown` Escape on the flash root and triggers the same `dismiss()`
    # path used by the close button. Escape should work whether focus is
    # on the dismiss button, the message body, or any nested focusable.
    #
    # Verification: remove the `if (event.key === "Escape")` branch from
    # the keydown handler in `lib/pulsar/components/flash.ex` (and the
    # mirrored block in `priv/templates/flash.ex.eex`) and re-run — the
    # `refute_has` assertion should fail because the flash stays mounted.

    test "Escape on the dismiss button dismisses the flash", %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show status flash")
      |> assert_has("#fl-trigger-status")
      |> press(~s|#fl-trigger-status button[aria-label="Dismiss"]|, "Escape")
      |> refute_has("#fl-trigger-status")
    end

    # A flash rendered with `dismissible={false}` exposes no close button, so
    # Escape must not provide a hidden dismissal path. The hook gates its
    # Escape branch on `data-dismissible === "true"`. Escape is pressed on the
    # flash's own action button so the keydown bubbles to the flash root — the
    # same mechanism the dismiss-button test above exercises.
    #
    # A dismiss removes the node `EXIT_MS` (120ms) *after* it fires, so a plain
    # `assert_has` would still find the node mid-animation even if Escape did
    # dismiss it. `assert_flash_present_after_dismiss_window/2` waits past that
    # window before asserting, so the test fails iff a dismiss actually fired.
    #
    # Verification: drop the `&& this.el.dataset.dismissible === "true"` guard
    # from the keydown handler in `lib/pulsar/components/flash.ex` (and the
    # mirrored block in `priv/templates/flash.ex.eex`), rebuild assets, re-run —
    # the flash is removed within the window and the assertion fails.
    test "Escape does not dismiss a non-dismissible flash", %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show persistent flash")
      |> assert_has("#fl-trigger-persistent")
      |> press("#fl-persistent-action", "Escape")
      |> assert_flash_present_after_dismiss_window("fl-trigger-persistent")
    end
  end

  # Waits past the flash exit-animation window (EXIT_MS = 120ms) and asserts the
  # element with `id` is still in the DOM. Distinguishes "Escape was ignored"
  # from "Escape fired a dismiss" — the latter removes the node after the window.
  defp assert_flash_present_after_dismiss_window(conn, id) do
    expr =
      "(async () => {" <>
        "await new Promise((resolve) => setTimeout(resolve, 400));" <>
        "return document.getElementById(#{Jason.encode!(id)}) !== null;" <>
        "})()"

    PhoenixTest.Playwright.evaluate(conn, expr, fn present? ->
      if !present? do
        raise ExUnit.AssertionError,
          message: "##{id} was removed after Escape — a non-dismissible flash must ignore Escape"
      end
    end)
  end
end
