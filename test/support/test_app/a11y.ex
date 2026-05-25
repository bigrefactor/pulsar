defmodule Pulsar.TestApp.A11y do
  @moduledoc """
  Helpers for running axe-core against fixture LiveViews under
  `phoenix_test_playwright`.

  Tests pipe a `PhoenixTest.Playwright` conn through `set_theme/2` and
  `assert_axe_clean/1`; both return the conn so they compose with `visit/2`.
  """

  # axe-core can be slow on complex pages; allow up to 30 s for the audit.
  @axe_timeout 30_000

  @doc """
  Sets `document.documentElement.dataset.theme` on the current page.
  """
  def set_theme(conn, theme) when theme in [:light, :dark] do
    PhoenixTest.Playwright.evaluate(
      conn,
      "document.documentElement.dataset.theme = '#{theme}'"
    )
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
