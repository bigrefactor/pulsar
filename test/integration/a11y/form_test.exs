defmodule Pulsar.Integration.A11y.FormTest do
  @moduledoc """
  End-to-end accessibility test for the form fixture. Drives the
  `Pulsar.DevApp.FormLive` signup form through a real submit cycle and
  asserts the full Pulsar form-a11y story: focus order, `aria-invalid`,
  error-id ↔ `aria-describedby` association, and focus-on-error.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`. Tag rationale matches `AxeCleanTest` and
  `KeyboardTest`: `:browser` is a reserved Playwright key.

  ## Verification

  To prove the test catches a real a11y regression (and isn't passively
  passing), temporarily comment out the `aria-describedby={@aria_describedby}`
  line on the rendered input in `lib/pulsar/components/field.ex` and re-run
  this test. The "each invalid field's aria-describedby resolves to its
  error message" test should fail with the field's `aria-describedby` going
  missing.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Signup form a11y" do
    test "tab order follows visual order through the form fields", %{conn: conn} do
      # Pressing Tab while an element is focused moves focus to the next
      # focusable element. Walk down the form from the first input.
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> press("#signup_name", "Tab")
      |> A11y.assert_focused("signup_email")
      |> press("#signup_email", "Tab")
      |> A11y.assert_focused("signup_plan")
      |> press("#signup_plan", "Tab")
      # First radio in the role group. RadioGroup ids follow
      # `{group_id}-{option_index}` (see radio_group.ex:349). WAI-ARIA
      # pattern: Tab lands on the first/checked radio; subsequent radios
      # are reached via arrow keys, not Tab.
      |> A11y.assert_focused("signup_role-0")
      |> press("#signup_role-0", "Tab")
      |> A11y.assert_focused("signup_notifications")
      |> press("#signup_notifications", "Tab")
      |> A11y.assert_focused("signup_terms")
      |> press("#signup_terms", "Tab")
      |> A11y.assert_focused("signup_notes")
    end

    test "submit with empty required fields renders aria-invalid on those inputs",
         %{conn: conn} do
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> click_button("Sign up")
      |> assert_has(~s|#signup_name[aria-invalid="true"]|)
      |> assert_has(~s|#signup_email[aria-invalid="true"]|)
      |> assert_has(~s|#signup_terms[aria-invalid="true"]|)
    end

    test "each invalid field's aria-describedby resolves to its error message",
         %{conn: conn} do
      conn =
        conn
        |> visit("/components/form")
        |> A11y.await_live_connected()
        |> click_button("Sign up")
        # Wait for the failed-submit re-render to land before reading
        # attributes via evaluate. evaluate, unlike assert_has, does not
        # retry — so the DOM must be settled first.
        |> assert_has(~s|#signup_name[aria-invalid="true"]|)

      # Verify each required field's input declares aria-describedby and that
      # every id it lists resolves to a DOM element with non-empty text.
      Enum.each(["signup_name", "signup_email", "signup_terms"], fn field_id ->
        assert_aria_describedby_resolves(conn, field_id)
      end)

      # Verify error ids are unique across the form.
      assert_unique_error_ids(conn)
    end

    test "focus moves to the first invalid field after a failed submit",
         %{conn: conn} do
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> click_button("Sign up")
      # Wait for the failed-submit response to land before checking focus.
      # The hook defers .focus() via requestAnimationFrame so it runs after
      # LV's post-patch focus restoration — see form.ex.
      |> assert_has(~s|#signup_name[aria-invalid="true"]|)
      |> A11y.assert_focused("signup_name")
    end

    test "aria-invalid clears on a field after the next valid submit",
         %{conn: conn} do
      # Type by id instead of label because Pulsar's required-field label
      # includes a screen-reader-only span and a visual asterisk
      # (label.ex:159-160), so `textContent` doesn't match "Full name"
      # exactly — and Playwright's label matcher is exact.
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> click_button("Sign up")
      |> assert_has(~s|#signup_name[aria-invalid="true"]|)
      |> type("#signup_name", "Alice")
      |> click_button("Sign up")
      |> assert_has(~s|#signup_name[aria-invalid="false"]|)
    end
  end

  # Reads `aria-describedby` for the input at `field_id`, splits on
  # whitespace, and asserts each referenced id exists in the DOM with
  # non-empty text. Captures the failure reason so a regression surfaces a
  # specific cause (missing target, empty target, no describedby).
  defp assert_aria_describedby_resolves(conn, field_id) do
    expr = """
    (() => {
      const input = document.getElementById(#{Jason.encode!(field_id)});
      if (!input) return { ok: false, reason: "input_not_found" };
      const raw = input.getAttribute("aria-describedby") || "";
      const ids = raw.split(/\\s+/).filter(Boolean);
      if (ids.length === 0) return { ok: false, reason: "no_describedby", raw };
      for (const id of ids) {
        const el = document.getElementById(id);
        if (!el) return { ok: false, reason: "missing_target", id };
        if (!el.textContent.trim()) return { ok: false, reason: "empty_target", id };
      }
      return { ok: true, ids };
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr, fn result ->
      if !result["ok"] do
        raise ExUnit.AssertionError,
          message: "aria-describedby check failed for ##{field_id}: #{inspect(result)}"
      end
    end)
  end

  # Counts all elements whose id contains "-error-" (Field.field's
  # error-id format: `{field_id}-error-{index}`) and asserts they're
  # unique across the rendered form.
  defp assert_unique_error_ids(conn) do
    expr = """
    (() => {
      const els = document.querySelectorAll('[id*="-error-"]');
      const ids = Array.from(els).map(el => el.id);
      const unique = new Set(ids);
      return { count: ids.length, unique_count: unique.size, ids };
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr, fn result ->
      if result["count"] == 0 do
        raise ExUnit.AssertionError, message: "expected at least one error id in the DOM"
      end

      if result["count"] != result["unique_count"] do
        raise ExUnit.AssertionError,
          message: "duplicate error ids found: #{inspect(result["ids"])}"
      end
    end)
  end
end
