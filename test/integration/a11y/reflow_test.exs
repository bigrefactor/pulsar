defmodule Pulsar.Integration.A11y.ReflowTest do
  @moduledoc """
  WCAG 1.4.10 Reflow regression gate. Per fixture × theme, runs with
  Playwright's viewport set to 320 × 640 CSS pixels and asserts the
  page does not require horizontal scrolling —
  `document.documentElement.scrollWidth <= 320 + tolerance`.

  The 320 px viewport is set via `@moduletag browser_context_opts:
  [viewport: %{width: 320, height: 640}]`, which
  `phoenix_test_playwright` forwards to Chromium's per-browser-context
  viewport. Async-safe; viewport is module-scoped and doesn't bleed
  into other a11y tests.

  Dev_app fixture chrome (the `<aside>` navigation sidebar and `<main>`
  padding) is hidden during the gate via injected CSS — it's not part
  of Pulsar's shipping surface, and at 320 px it would dominate the
  viewport. With chrome hidden, the gate measures whether Pulsar
  components reflow at 320 px, not whether the dev_app's test
  scaffolding does.

  Containers tagged `data-reflow-allowed` (e.g. table's intentional
  `overflow-x-auto` wrapper, per WCAG 1.4.10 — data tables are
  explicit exempt content) are naturally exempt: `overflow-x-auto`
  contains horizontal overflow internally, so
  `documentElement.scrollWidth` is unaffected.

  Per-element internal overflow (e.g. a placeholder string wider than
  its narrowed input) is **not** a reflow violation — the input
  scrolls its own contents.

  Note: this is a real viewport constraint, not a CSS workaround.
  Media queries keyed on viewport width (e.g. `@media (max-width:
  320px)`) DO trigger here, unlike the previous CSS-injection
  approach.

  Tagged `:integration`; run with `mix test --only integration`. Tag
  rationale matches AxeCleanTest.

  ## Verification

  Add `min-width: 480px` to a Button base class, rebuild assets,
  re-run — Button fixtures fail with documentElement.scrollWidth
  ≫ 320.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y
  alias Pulsar.DevApp.Components

  @moduletag :integration
  @moduletag browser_context_opts: [viewport: %{width: 320, height: 640}]

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
            /* Dev_app fixture chrome — not part of Pulsar's shipping
               surface. Hidden during the reflow gate so the assertion
               measures whether Pulsar components reflow at 320 CSS px,
               not whether the dev_app navigation sidebar / scroll
               wrapper do.

               The flex-1 content wrapper has overflow-x-auto for
               developer ergonomics — without overriding it, any
               component that exceeds 320 px would scroll inside that
               wrapper, hiding the reflow failure from
               documentElement.scrollWidth. */
            aside { display: none !important; }
            /* The dev_app flex-1 wrapper inherits min-width: auto (the
               flex default), which prevents it from shrinking below
               its content's intrinsic min-width. That's dev_app
               scaffolding behavior; real consumers control their own
               layout. We force min-width: 0 so the wrapper genuinely
               sits at the viewport's 320 px, and the test measures
               whether Pulsar components reflow at that width. */
            .overflow-x-auto.flex-1 {
              overflow-x: visible !important;
              min-width: 0 !important;
            }
            main[data-fixture] { padding: 0 !important; }
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

      if page_scroll > @reflow_width + @tolerance do
        details =
          case offenders do
            [] ->
              "  - documentElement.scrollWidth = #{page_scroll} px exceeds #{@reflow_width} px, but no `[data-fixture-cell]` is the offender — check for non-cell wrappers or chrome that escaped the test's hide-CSS."

            _ ->
              Enum.map_join(offenders, "\n", fn o ->
                "  - `#{o["id"]}` rendered #{o["width"]} px wide (constraint: #{@reflow_width} px)"
              end)
          end

        raise ExUnit.AssertionError,
          message:
            "WCAG 1.4.10 Reflow — page horizontally scrolls (documentElement.scrollWidth #{page_scroll}) at #{@reflow_width} CSS px viewport on #{@route} [#{@theme}]:\n#{details}\n\n" <>
              "If the wide element is an intentional scroll container (e.g. wide data table), tag it with `data-reflow-allowed`."
      end
    end
  end
end
