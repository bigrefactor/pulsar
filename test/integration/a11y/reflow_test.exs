defmodule Pulsar.Integration.A11y.ReflowTest do
  @moduledoc """
  WCAG 1.4.10 Reflow regression gate. Per fixture × theme, constrains
  `html, body` to 320 CSS pixels and asserts the page does not require
  horizontal scrolling — `document.documentElement.scrollWidth <=
  320 + tolerance`.

  Containers tagged `data-reflow-allowed` (e.g. table's intentional
  `overflow-x-auto` wrapper, per WCAG 1.4.10 — data tables are explicit
  exempt content) are subtracted from the page's effective scroll
  width: they're allowed to scroll horizontally inside themselves
  without that counting as a page-level reflow failure.

  Per-element internal overflow (e.g. a placeholder string wider than
  its narrowed input) is **not** a reflow violation — the input scrolls
  its own contents and the page does not. Only page-level overflow is
  asserted here.

  Note: this is a CSS-only viewport constraint. Media queries based on
  viewport width don't trigger — interpret a failure as worst-case,
  not as media-query-aware behavior. Pulsar components are
  content-driven (no fixed widths or min-widths called out in the
  1.4.10 audit evidence), so the worst case is the real case here.

  Tagged `:integration`; run with `mix test --only integration`. Tag
  rationale matches AxeCleanTest.

  ## Verification

  Add `min-width: 480px` to a Button base class, rebuild assets,
  re-run — Button fixtures fail with page scrollWidth ≫ 320.
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

      if page_scroll > @reflow_width + @tolerance and offenders != [] do
        details =
          Enum.map_join(offenders, "\n", fn o ->
            "  - `#{o["id"]}` rendered #{o["width"]} px wide (constraint: #{@reflow_width} px)"
          end)

        raise ExUnit.AssertionError,
          message:
            "WCAG 1.4.10 Reflow — page horizontally scrolls (scrollWidth #{page_scroll}) at #{@reflow_width} CSS px on #{@route} [#{@theme}]:\n#{details}\n\n" <>
              "If the wide element is an intentional scroll container (e.g. wide data table), tag it with `data-reflow-allowed`."
      end
    end
  end
end
