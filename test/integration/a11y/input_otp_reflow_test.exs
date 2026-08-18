defmodule Pulsar.Integration.A11y.InputOtpReflowTest do
  @moduledoc """
  Asserts how InputOTP's slot row wraps at 320 CSS px.

  `reflow_test.exs` already covers the width: it fails every
  `/components/input_otp/*` route if a `data-fixture-cell` renders wider than
  320 px. What it cannot express is *where* the row breaks — a code that wraps
  mid-group, or a separator stranded on a row of its own, is just as wide as
  one that breaks cleanly, so the gate sees nothing wrong with either.

  This measures that a `groups={[5, 5]}` code puts one group per row and keeps
  each separator on its group's row.

  Dev_app fixture chrome is neutralised with `A11y.chrome_neutralising_css/0`,
  the same block `reflow_test.exs` injects. Without it the content column
  measures 252 px at a 320 px viewport, and the geometry under test is
  dev_app's, not the component's — so the two must not drift apart.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  ## Verification

  Move the separator back out of the group row (its own top-level cell between
  two groups) in `priv/templates/input_otp.ex.eex`, run `mix pulsar.sync`, and
  re-run: the separator lands on a row by itself between the two groups.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration
  @moduletag browser_context_opts: [viewport: %{width: 320, height: 640}]

  @viewport 320

  test "a ten-slot grouped code puts one group per row, separator included", %{conn: conn} do
    session =
      conn
      |> visit("/components/input_otp/outline")
      |> A11y.await_live_connected()

    probe = """
    (() => {
      const style = document.createElement('style');
      style.textContent = `#{A11y.chrome_neutralising_css()}`;
      document.head.appendChild(style);
      void document.documentElement.offsetWidth;

      const wrapper = document.querySelector('#otp-outline-long-otp');
      const row = wrapper.querySelector('[aria-hidden="true"]');
      const top = (el) => Math.round(el.getBoundingClientRect().top);

      // Every item on the wrapping row is a whole group. A separator that is
      // its own flex item can be pushed onto a line by itself, which is the
      // bug this guards; one nested in its group's row cannot.
      const items = Array.from(row.children);

      const result = {
        width: Math.round(wrapper.getBoundingClientRect().width),
        available: Math.round(wrapper.parentElement.getBoundingClientRect().width),
        rows: new Set(items.map(top)).size,
        nonGroupItems: items.filter((el) => !el.hasAttribute('data-otp-group')).length,
        separators: row.querySelectorAll('[data-otp-group] > span').length
      };

      style.remove();
      return JSON.stringify(result);
    })()
    """

    PhoenixTest.Playwright.evaluate(session, probe, fn json ->
      %{
        "width" => width,
        "available" => available,
        "rows" => rows,
        "nonGroupItems" => non_group_items,
        "separators" => separators
      } = Jason.decode!(json)

      assert separators == 1,
             "expected the one separator of a groups={[5, 5]} code to render inside a group row, found #{separators}"

      assert non_group_items == 0,
             "#{non_group_items} item(s) on the wrapping row are not whole groups; a separator that is its own flex item can wrap onto a line alone"

      assert rows == 2,
             "expected a groups={[5, 5]} code to occupy one row per group at #{@viewport} px, got #{rows}"

      assert width <= available,
             "slot row measured #{width} px inside a #{available} px column; the trailing slots are clipped"
    end)
  end
end
