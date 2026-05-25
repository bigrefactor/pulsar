defmodule Pulsar.TestApp.A11y do
  @moduledoc """
  Helpers for running axe-core against fixture LiveViews under
  `phoenix_test_playwright`.

  Tests pipe a `PhoenixTest.Playwright` conn through `set_theme/2` and
  `assert_axe_clean/1`; both return the conn so they compose with `visit/2`.
  """

  @doc """
  Sets `document.documentElement.dataset.theme` on the current page.
  """
  def set_theme(conn, theme) when theme in [:light, :dark] do
    {:ok, _} =
      PlaywrightEx.Frame.evaluate(conn.frame_id,
        expression: "document.documentElement.dataset.theme = '#{theme}'"
      )

    conn
  end

  @doc """
  Injects axe-core into the current page, runs the audit, and asserts
  zero violations via `A11yAudit.Assertions.assert_no_violations/1`.
  """
  def assert_axe_clean(conn) do
    {:ok, _} =
      PlaywrightEx.Frame.evaluate(conn.frame_id, expression: A11yAudit.JS.axe_core())

    {:ok, json} =
      PlaywrightEx.Frame.evaluate(conn.frame_id,
        expression: A11yAudit.JS.await_audit_results()
      )

    json
    |> A11yAudit.Results.from_json()
    |> A11yAudit.Assertions.assert_no_violations()

    conn
  end
end
