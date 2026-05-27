defmodule Pulsar.Integration.A11y.ReflowTest do
  @moduledoc """
  WCAG 1.4.10 Reflow regression gate (component-scoped). Per fixture
  × theme, constrains `html, body` to 320 CSS pixels and asserts no
  `[data-fixture-cell]` renders wider than that constraint —
  `getBoundingClientRect().width <= 320 + tolerance` for every fixture
  cell.

  ## Scope: why this is component-scoped, not page-scoped

  WCAG 1.4.10's normative measurement is the page (`document.documentElement.scrollWidth`
  at a 320 CSS px viewport). This test can't make that measurement
  directly: Playwright sets the browser's layout viewport (typically
  1280 px), and injecting `html { width: 320px !important }` doesn't
  change the layout viewport — `documentElement.scrollWidth` continues
  to reflect viewport width regardless of the CSS constraint. Genuine
  page-level reflow gating would require setting the Playwright
  viewport itself, which is a larger architectural change.

  The CSS-injection approach DOES change individual element layout
  (an element with `width: 100%` shrinks; an element with explicit
  width over 320 stays wide). So the meaningful, accurate assertion
  this test can make is: "no `[data-fixture-cell]` exceeds 320 CSS
  px when the body box is narrowed to 320 px." That's what's gated
  here.

  Containers tagged `data-reflow-allowed` (e.g. table's intentional
  `overflow-x-auto` wrapper, per WCAG 1.4.10 — data tables are
  explicit exempt content) and their descendants are excluded:
  they're allowed to scroll horizontally inside themselves without
  counting as a reflow violation. Fixed / sticky elements are
  excluded because they render against the viewport, not the
  constrained html/body.

  Per-element internal overflow (e.g. a placeholder string wider
  than its narrowed input) is **not** a reflow violation — the input
  scrolls its own contents.

  Note: this is a CSS-only viewport constraint. Media queries based
  on viewport width don't trigger — interpret a failure as
  worst-case, not as media-query-aware behavior. Pulsar components
  are content-driven (no fixed widths or min-widths called out in
  the 1.4.10 audit evidence), so the worst case is the real case
  here.

  Tagged `:integration`; run with `mix test --only integration`. Tag
  rationale matches AxeCleanTest.

  ## Verification

  Add `min-width: 480px` to a Button base class, rebuild assets,
  re-run — Button fixtures fail with a fixture cell wider than 320.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y
  alias Pulsar.DevApp.Components

  @moduletag :integration

  @reflow_width 320
  # Sub-pixel rounding tolerance. Chromium sometimes reports
  # scrollWidth = clientWidth + 0.5 even when no element overflows.
  @tolerance 1

  for {_label, route} <- Components.fixtures(), theme <- [:light, :dark] do
    @route route
    @theme theme

    test "page on #{@route} (#{@theme}) reflows at #{@reflow_width} CSS px",
         %{conn: conn} do
      parent = self()

      conn
      |> visit(@route)
      |> A11y.set_theme(@theme)
      |> A11y.await_live_connected()
      |> PhoenixTest.Playwright.evaluate(
        """
        (() => {
          const id = 'pulsar-a11y-reflow-constraint';
          const prev = document.getElementById(id);
          if (prev) prev.remove();
          const style = document.createElement('style');
          style.id = id;
          style.textContent = `
            html, body {
              width: #{@reflow_width}px !important;
              max-width: #{@reflow_width}px !important;
              overflow-x: visible !important;
            }
          `;
          document.head.appendChild(style);
          void document.documentElement.offsetWidth;

          const pageScroll = document.documentElement.scrollWidth;

          // Collect direct-child elements that exceed the constraint
          // and are NOT inside (or themselves) a `data-reflow-allowed`
          // scroll container. These are the actual offenders.
          const tol = #{@tolerance};
          const offenders = [];
          document.querySelectorAll('[data-fixture-cell]').forEach((el) => {
            if (el.closest('[data-reflow-allowed]')) return;
            // Fixed / sticky positioning takes the element out of body
            // flow — its rendered width is from the viewport, not the
            // constrained html/body. Doesn't contribute to page reflow.
            const pos = window.getComputedStyle(el).position;
            if (pos === 'fixed' || pos === 'sticky') return;
            const r = el.getBoundingClientRect();
            // An element is an offender only if its rendered (visible)
            // width exceeds the page constraint — i.e. it forces the
            // page horizontal. An input whose placeholder string is
            // wider than its box scrolls internally, not the page.
            if (r.width > #{@reflow_width} + tol) {
              offenders.push({
                id: el.getAttribute('data-fixture-cell'),
                width: Math.round(r.width * 100) / 100,
              });
            }
          });

          style.remove();
          return { pageScroll, offenders };
        })()
        """,
        fn result -> send(parent, {:result, result}) end
      )

      result =
        receive do
          {:result, r} -> r
        after
          5_000 -> raise "timed out collecting reflow measurements"
        end

      page_scroll = result["pageScroll"] || 0
      offenders = result["offenders"] || []

      if offenders != [] do
        details =
          Enum.map_join(offenders, "\n", fn o ->
            "  - `#{o["id"]}` rendered #{o["width"]} px wide (constraint: #{@reflow_width} px)"
          end)

        raise ExUnit.AssertionError,
          message:
            "WCAG 1.4.10 Reflow — fixture cell wider than #{@reflow_width} CSS px on #{@route} [#{@theme}] " <>
              "(observed documentElement.scrollWidth: #{page_scroll} px — see moduledoc on why this isn't asserted directly):\n#{details}\n\n" <>
              "If the wide element is an intentional scroll container (e.g. wide data table), tag it with `data-reflow-allowed`."
      end
    end
  end
end
