defmodule Pulsar.Integration.A11y.InputOtpReflowTest do
  @moduledoc """
  Measures that InputOTP's slot row wraps at 320 CSS px instead of running
  past the viewport.

  `reflow_test.exs` cannot cover this. It asserts on
  `document.documentElement.scrollWidth`, and dev_app's shared layout column
  (`test/support/dev_app/layouts/app.html.heex`) is `overflow-x-auto`, so a
  row wider than the viewport is absorbed there and never widens the
  document. That is the same clipping the component showed in a host app:
  the trailing slots were simply unreachable, with no scrollbar to find them.

  So this measures the component directly — the two groups of a
  `groups={[5, 5]}` code must land on different rows, and the row must fit
  the viewport.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  ## Verification

  Drop `flex-wrap` from the slot row in `priv/templates/input_otp.ex.eex`,
  run `mix pulsar.sync`, and re-run: the row measures 535 px against a 320 px
  viewport and both groups report the same row.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration
  @moduletag browser_context_opts: [viewport: %{width: 320, height: 640}]

  @viewport 320

  test "a ten-slot grouped code wraps at the separator instead of overflowing", %{conn: conn} do
    session =
      conn
      |> visit("/components/input_otp/outline")
      |> A11y.await_live_connected()

    probe = """
    (() => {
      const wrapper = document.querySelector('#otp-outline-long-otp');
      const first = wrapper.querySelector('[data-slot="0"]').getBoundingClientRect();
      const second = wrapper.querySelector('[data-slot="5"]').getBoundingClientRect();
      return JSON.stringify({
        width: Math.round(wrapper.getBoundingClientRect().width),
        sameRow: Math.abs(second.top - first.top) < 4
      });
    })()
    """

    PhoenixTest.Playwright.evaluate(session, probe, fn json ->
      %{"width" => width, "sameRow" => same_row?} = Jason.decode!(json)

      refute same_row?,
             "expected the two groups of a groups={[5, 5]} code on separate rows at #{@viewport} px, but both sit on one"

      assert width <= @viewport,
             "slot row measured #{width} px against a #{@viewport} px viewport; the trailing slots are off-screen"
    end)
  end
end
