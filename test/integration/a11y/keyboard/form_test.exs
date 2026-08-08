defmodule Pulsar.Integration.A11y.Keyboard.FormTest do
  @moduledoc """
  Real-browser keyboard tests for Form traversal. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Form keyboard traversal" do
    # Backward complement to `FormTest`'s forward Tab walk: starting from
    # the last field, Shift+Tab should walk back through every form field
    # in reverse DOM order. Catches focus traps that would only show up
    # when navigating backwards (e.g. a custom widget that swallows
    # `keydown` for Shift+Tab but not Tab).
    #
    # Verification: temporarily add `tabindex="-1"` to the `<select>`
    # rendered by `lib/pulsar/components/select.ex` and rebuild assets.
    # Backward traversal skips `signup_plan`, so the `assert_focused`
    # after stepping past it lands on `signup_email` instead of
    # `signup_plan` and the test fails.

    test "Shift+Tab walks back through every signup form field",
         %{conn: conn} do
      # Forward tab order (covered by `FormTest`):
      #   name → email → plan → role-0 → notifications → terms → notes
      # Chromium treats an unchecked radio group as one stop in either
      # direction, but it picks DIFFERENT representative radios per
      # direction: forward enters at the first radio (`role-0`), backward
      # enters at the last (`role-1`). Either way, only one of the two
      # role radios participates in tab traversal at a time. The walk
      # below documents that observed behavior.
      conn
      |> visit("/components/form")
      |> A11y.await_live_connected()
      |> press("#signup_notes", "Shift+Tab")
      |> A11y.assert_focused("signup_terms")
      |> press("#signup_terms", "Shift+Tab")
      |> A11y.assert_focused("signup_notifications")
      |> press("#signup_notifications", "Shift+Tab")
      |> A11y.assert_focused("signup_role-1")
      |> press("#signup_role-1", "Shift+Tab")
      |> A11y.assert_focused("signup_plan")
      |> press("#signup_plan", "Shift+Tab")
      |> A11y.assert_focused("signup_email")
      |> press("#signup_email", "Shift+Tab")
      |> A11y.assert_focused("signup_name")
    end
  end
end
