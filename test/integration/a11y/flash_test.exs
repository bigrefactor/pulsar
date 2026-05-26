defmodule Pulsar.Integration.A11y.FlashTest do
  @moduledoc """
  End-to-end accessibility test for the Flash component. Drives the
  `Pulsar.DevApp.FlashTriggerLive` fixture through a real
  click-to-mount cycle and asserts the rendered flash exposes the
  attributes screen readers consume: `role`, `aria-live`, `aria-atomic`,
  and an accessible name matching the visible text.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  ## Verification

  To prove the test catches a real a11y regression, temporarily change
  `get_aria_live/2` in `lib/pulsar/components/flash.ex:572-575` to always
  return `"off"` and re-run this test. Both `aria-live` assertions
  should fail.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Flash screen reader announcement" do
    test "default flash announces as role=status with aria-live=polite",
         %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show status flash")
      |> assert_has(~s|#fl-trigger-status[role="status"]|)
      |> assert_has(~s|#fl-trigger-status[aria-live="polite"]|)
      |> assert_has(~s|#fl-trigger-status[aria-atomic="true"]|)
      |> assert_accessible_name("fl-trigger-status", "Status flash content")
    end

    test ~s|role="alert" flash announces as role=alert with aria-live=assertive|,
         %{conn: conn} do
      conn
      |> visit("/components/flash/trigger")
      |> A11y.await_live_connected()
      |> click_button("Show alert flash")
      |> assert_has(~s|#fl-trigger-alert[role="alert"]|)
      |> assert_has(~s|#fl-trigger-alert[aria-live="assertive"]|)
      |> assert_has(~s|#fl-trigger-alert[aria-atomic="true"]|)
      |> assert_accessible_name("fl-trigger-alert", "Alert flash content")
    end
  end

  # Flash has no aria-label / aria-labelledby, so the AT computes the
  # accessible name from descendant text. Read textContent and assert
  # it contains the expected string. The dismiss <button> is a separate
  # accessible element with its own name ("Dismiss") and its text does
  # not contribute to the parent flash's name.
  defp assert_accessible_name(conn, id, expected) do
    expr = """
    (() => {
      const el = document.getElementById(#{Jason.encode!(id)});
      if (!el) return { ok: false, reason: "not_found" };
      const txt = el.textContent.replace(/\\s+/g, " ").trim();
      return { ok: txt.includes(#{Jason.encode!(expected)}), text: txt };
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr, fn result ->
      if !result["ok"] do
        raise ExUnit.AssertionError,
          message: "accessible name mismatch for ##{id}: #{inspect(result)}"
      end
    end)
  end
end
