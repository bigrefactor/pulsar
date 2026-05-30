defmodule Pulsar.Integration.A11y.MeasureTest do
  @moduledoc """
  Browser measurement runner. For each component fixture × theme,
  injects `priv/a11y/measure.js`, captures per-cell measurements (text contrast,
  border/focus-ring contrast, target size), then runs text-spacing and reflow
  overflow checks. Writes one markdown report per `(component, theme)` to
  `docs/a11y/measurements/<component>-<theme>.md`.

  These are **report-writing** tests, not assertions. They never fail except on
  unrecoverable browser errors. Tagged `:measure` and explicitly excluded from
  the default `mix test` and `:integration` runs — invoke via
  `mix pulsar.a11y.measure`.

  Env var filters:

    * `PULSAR_A11Y_COMPONENT` — restrict to a single component slug (e.g. `button`)
    * `PULSAR_A11Y_THEME` — `light`, `dark`, or unset (both)
  """

  use PhoenixTest.Playwright.Case, async: false

  alias Pulsar.DevApp.A11y
  alias Pulsar.DevApp.Components

  @moduletag :measure

  @output_dir "docs/a11y/measurements"
  @measure_js_path Path.join([:code.priv_dir(:pulsar), "a11y", "measure.js"])
  @external_resource @measure_js_path
  @measure_js File.read!(@measure_js_path)

  @reflow_width 320

  # Group fixtures by component (the first path segment after `/components/`),
  # mapping each component to all of its routes. Heavy components
  # (input/select/table) are split across per-variant sub-routes
  # (`/components/input/outline`, `.../ghost`, `.../solid`); their cells are
  # aggregated into one report per component, since cell IDs already carry the
  # variant. Skips fixtures that don't map to an audit page (form is a
  # composite, flash/trigger is a behavior duplicate of flash).
  @components Components.fixtures()
              |> Enum.flat_map(fn
                {_label, "/components/form"} ->
                  []

                {_label, "/components/flash/trigger"} ->
                  []

                {_label, "/components/" <> rest = route} ->
                  [{rest |> String.split("/") |> hd(), route}]

                _ ->
                  []
              end)
              |> Enum.group_by(fn {slug, _route} -> slug end, fn {_slug, route} -> route end)
              |> Enum.map(fn {slug, routes} -> {slug, Enum.sort(routes)} end)
              |> Enum.sort()

  for {slug, routes} <- @components, theme <- [:light, :dark] do
    @slug slug
    @routes routes
    @theme theme

    test "measure #{@slug} [#{@theme}]", %{conn: conn} do
      component_filter = System.get_env("PULSAR_A11Y_COMPONENT")
      theme_filter = System.get_env("PULSAR_A11Y_THEME")

      cond do
        component_filter && component_filter != @slug ->
          :ok

        theme_filter && theme_filter != Atom.to_string(@theme) ->
          :ok

        true ->
          run_measurement(conn, @slug, @routes, @theme)
      end
    end
  end

  defp run_measurement(conn, slug, routes, theme) do
    measurements = Enum.map(routes, &measure_route(conn, &1, theme))

    baseline = merge_baselines(Enum.map(measurements, & &1.baseline))
    text_spacing_overflows = Enum.flat_map(measurements, & &1.text_spacing)
    reflow_cells = Enum.flat_map(measurements, & &1.reflow_cells)
    reflow_page = Enum.any?(measurements, & &1.reflow_page)

    report =
      build_report(slug, theme, baseline, text_spacing_overflows, reflow_cells, reflow_page)

    File.mkdir_p!(@output_dir)
    File.write!(Path.join(@output_dir, "#{slug}-#{theme}.md"), report)
  end

  # Visits one route and captures its baseline cells plus the text-spacing and
  # reflow overflow probes for that page.
  defp measure_route(conn, route, theme) do
    parent = self()

    conn
    |> visit(route)
    |> A11y.set_theme(theme)
    |> A11y.await_live_connected()
    |> PhoenixTest.Playwright.evaluate(@measure_js)
    |> capture(parent, :baseline, "window.PulsarA11yMeasure.measureAll()")
    |> PhoenixTest.Playwright.evaluate("window.PulsarA11yMeasure.applyTextSpacingOverride()")
    |> capture(parent, :text_spacing, "window.PulsarA11yMeasure.detectOverflows()")
    |> PhoenixTest.Playwright.evaluate("window.PulsarA11yMeasure.removeTextSpacingOverride()")
    |> PhoenixTest.Playwright.evaluate("window.PulsarA11yMeasure.applyReflowConstraint(#{@reflow_width})")
    |> capture(parent, :reflow_cells, "window.PulsarA11yMeasure.detectOverflows()")
    |> capture(
      parent,
      :reflow_page,
      "window.PulsarA11yMeasure.pageOverflowsHorizontally(#{@reflow_width})"
    )
    |> PhoenixTest.Playwright.evaluate("window.PulsarA11yMeasure.removeReflowConstraint()")

    %{
      baseline: receive_msg(:baseline),
      text_spacing: receive_msg(:text_spacing),
      reflow_cells: receive_msg(:reflow_cells),
      reflow_page: receive_msg(:reflow_page)
    }
  end

  # Concatenates per-route baselines into one: cells from every route, with the
  # viewport taken from the first (identical across a component's routes).
  defp merge_baselines([]), do: %{"cells" => [], "viewport" => %{}}

  defp merge_baselines([first | _] = baselines) do
    cells = Enum.flat_map(baselines, &Map.get(&1, "cells", []))
    %{"cells" => cells, "viewport" => Map.get(first, "viewport", %{})}
  end

  # Pipes the conn through evaluate-with-callback, sending the JS result to
  # the test process so the caller can pull it via receive_msg/1.
  defp capture(conn, parent, key, expression) do
    PhoenixTest.Playwright.evaluate(conn, expression, fn value ->
      send(parent, {key, value})
    end)
  end

  defp receive_msg(key) do
    receive do
      {^key, value} -> value
    after
      5_000 ->
        raise "timed out waiting for measurement: #{inspect(key)}"
    end
  end

  # -- Report formatting ----------------------------------------------------

  defp build_report(slug, theme, baseline, text_spacing_overflows, reflow_cells, reflow_page) do
    cells = Map.get(baseline, "cells", [])
    viewport = Map.get(baseline, "viewport", %{})
    vp_width = Map.get(viewport, "width", "?")
    vp_height = Map.get(viewport, "height", "?")

    """
    # #{String.capitalize(slug)} — a11y measurements (#{theme})

    Auto-generated by `mix pulsar.a11y.measure`. Do not edit by hand —
    re-run the task to refresh. The canonical audit page is
    [`#{slug}.md`](../#{slug}.md).

    - **Theme:** `#{theme}`
    - **Viewport:** #{vp_width}×#{vp_height} CSS px
    - **Cells:** #{length(cells)}

    ## Per-cell measurements

    Columns:

    - **Size** — `getBoundingClientRect()` width × height. ≥24 column flags
      pass under WCAG 2.5.8 Target Size minimum.
    - **Text** — text-color vs effective background contrast ratio
      (alpha-resolved). Threshold 4.5:1 (3:1 for large text). `—` means no
      text or no resolvable color. For mask-painted icon glyphs the value is
      the painted glyph color vs the *ancestor* background at the 3:1 WCAG
      1.4.11 non-text threshold, marked `(glyph)`; decorative
      (`aria-hidden`) icons are exempt and marked `(glyph, decorative)`.
    - **Border** — border-color vs adjacent background contrast. `—` if no
      visible border. Threshold 3:1 per WCAG 1.4.11 Non-text Contrast.
    - **Focus** — focus-visible ring/outline vs adjacent background.
      Threshold 3:1 per WCAG 2.4.7 / 1.4.11.

    #{cells_table(cells)}

    ## Text-spacing override (WCAG 1.4.12)

    Applied: `line-height: 1.5`, `letter-spacing: 0.12em`,
    `word-spacing: 0.16em`, `p { margin-bottom: 2em }`.

    #{format_overflow_section(text_spacing_overflows)}

    ## Reflow at #{@reflow_width} CSS px (WCAG 1.4.10)

    Constraint applied via `html, body { width: #{@reflow_width}px }`.
    Media queries do not trigger under CSS-only constraint — interpret
    overflows as worst-case, not as media-query-aware behavior.

    - **Page horizontally overflows:** #{format_bool(reflow_page)}

    #{format_overflow_section(reflow_cells)}
    """
  end

  defp cells_table([]), do: "_No `[data-fixture-cell]` elements found on the page._"

  defp cells_table(cells) do
    header = """
    | Cell ID | Tag | Width | Height | ≥24×24 | Text | Border | Focus |
    |---------|-----|-------|--------|--------|------|--------|-------|
    """

    rows =
      cells
      |> Enum.sort_by(& &1["id"])
      |> Enum.map_join("\n", &cell_row/1)

    header <> rows
  end

  defp cell_row(cell) do
    rect = cell["rect"] || %{}
    text = cell["text"] || %{}
    border = cell["border"] || %{}
    ring = cell["focusRing"] || %{}

    "| `#{cell["id"]}` | `#{cell["tagName"]}` | #{format_dim(rect["width"])} | #{format_dim(rect["height"])} | #{format_pass(rect["pass24"])} | #{format_ratio(text)} | #{format_ratio(border)} | #{format_ratio(ring)} |"
  end

  defp format_dim(nil), do: "—"
  defp format_dim(n), do: "#{n}"

  defp format_pass(nil), do: "—"
  defp format_pass(true), do: "✓"
  defp format_pass(false), do: "✗"

  # A ratio cell shows the contrast number and pass/fail marker, or `—` if
  # the measurement was skipped (no border, not focusable, etc.).
  defp format_ratio(%{"ratio" => nil, "reason" => reason}), do: "— (#{reason})"

  # Mask-painted icon glyphs (1.4.11, 3:1). Decorative icons (`aria-hidden`)
  # are exempt — tagged so the pass/fail marker is read as informational only.
  defp format_ratio(%{"kind" => "icon-glyph", "ratio" => ratio, "pass" => pass, "decorative" => true}),
    do: "#{ratio}:1 #{format_pass(pass)} (glyph, decorative)"

  defp format_ratio(%{"kind" => "icon-glyph", "ratio" => ratio, "pass" => pass}),
    do: "#{ratio}:1 #{format_pass(pass)} (glyph)"

  # Border cells carry the edge that was measured (a single `border-b` rule
  # reports `bottom`); surface it so single-edge borders are legible.
  defp format_ratio(%{"edge" => edge, "ratio" => ratio, "pass" => pass}),
    do: "#{ratio}:1 #{format_pass(pass)} (#{edge})"

  defp format_ratio(%{"ratio" => ratio, "pass" => pass}), do: "#{ratio}:1 #{format_pass(pass)}"
  defp format_ratio(_), do: "—"

  defp format_overflow_section([]), do: "**Cells overflowing:** none."

  defp format_overflow_section(overflows) when is_list(overflows) do
    rows =
      Enum.map_join(overflows, "\n", fn o ->
        directions =
          [
            if(o["x"], do: "x"),
            if(o["y"], do: "y")
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.join("+")

        "- `#{o["id"]}` (#{directions}) — content #{o["scrollWidth"]}×#{o["scrollHeight"]} vs box #{o["clientWidth"]}×#{o["clientHeight"]}"
      end)

    "**Cells overflowing (#{length(overflows)}):**\n\n" <> rows
  end

  defp format_overflow_section(_), do: "_Measurement unavailable._"

  defp format_bool(true), do: "yes"
  defp format_bool(false), do: "no"
  defp format_bool(_), do: "?"
end
