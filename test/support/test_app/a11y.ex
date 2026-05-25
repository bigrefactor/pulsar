defmodule Pulsar.TestApp.A11y do
  @moduledoc """
  Helpers for running axe-core against fixture LiveViews under
  `phoenix_test_playwright`.

  Tests pipe a `PhoenixTest.Playwright` conn through `set_theme/2` and
  `assert_axe_clean/1`; both return the conn so they compose with `visit/2`.
  """

  # axe-core typically completes in well under a second on small fixture
  # pages; cap the audit at 10 s so a wedged page surfaces quickly. A
  # complex fixture can override per-test with `@tag timeout: …`.
  @axe_timeout 10_000

  @doc """
  Sets `document.documentElement.dataset.theme` on the current page.
  """
  def set_theme(conn, theme) when theme in [:light, :dark] do
    # Hard-coded JS payloads (no interpolation) so this call site stays
    # un-injectable even if the guard above is widened to accept strings later.
    js =
      case theme do
        :light -> "document.documentElement.dataset.theme = 'light'"
        :dark -> "document.documentElement.dataset.theme = 'dark'"
      end

    PhoenixTest.Playwright.evaluate(conn, js)
  end

  @doc """
  Injects axe-core into the current page, runs the audit, and asserts
  zero violations via `A11yAudit.Assertions.assert_no_violations/1`.
  """
  def assert_axe_clean(conn) do
    # Inject the axe-core library into the page.
    conn = PhoenixTest.Playwright.evaluate(conn, A11yAudit.JS.axe_core())

    # Run the audit. A11yAudit.JS.await_audit_results/0 returns
    # "return await axe.run();" which is a bare return statement — not a
    # complete function expression. Playwright's `is_function: true` requires
    # a complete arrow/function expression, so we wrap it ourselves.
    audit_fn = "async () => { #{A11yAudit.JS.await_audit_results()} }"

    PhoenixTest.Playwright.evaluate(
      conn,
      audit_fn,
      [is_function: true, timeout: @axe_timeout],
      fn json ->
        json
        |> A11yAudit.Results.from_json()
        |> A11yAudit.Assertions.assert_no_violations()
      end
    )
  end
end
