defmodule Pulsar.Integration.A11y.TargetSizeTest do
  @moduledoc """
  WCAG 2.5.8 Target Size (Minimum) regression gate. Per fixture × theme,
  asserts every interactive `[data-fixture-cell]` whose underlying tag is
  one of `button`, `a`, `input`, `select`, `textarea` meets ≥ 24×24 CSS
  pixels via `getBoundingClientRect()`.

  Cells carrying `data-target-size-exception` are allowlisted (e.g.
  flash dismiss button — per WCAG 2.5.8 spacing exception). Checkbox /
  switch inputs at small sizes intentionally fall below 24×24 because
  the effective target is the surrounding label; those are excluded
  here by the `input[type="checkbox"]` and `input[type="radio"]`
  filter (radio_group's underlying inputs likewise).

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`. Tag rationale matches AxeCleanTest.

  ## Verification

  To prove this fires on a real regression, set `min-h-3` on Button `xs`
  in `lib/pulsar/components/button.ex`, rebuild assets, and re-run —
  the Button fixture's xs cells should fail height-≥-24.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y
  alias Pulsar.DevApp.Components

  @moduletag :integration

  # Interactive tags worth gating. Checkbox / radio / switch inputs are
  # excluded — their effective target is the wrapping label and the WCAG
  # spacing exception covers small visual sizes (see `checkbox.md`,
  # `switch.md`, `radio_group.md` 2.5.8 entries). `<a>` is excluded
  # because the WCAG inline-link exception depends on context (the same
  # link size can be a 2.5.8 violation standalone and a pass inline in
  # body text); inline links are explicitly supported by the Link
  # component, so gating them here would force a one-size-fits-all
  # constraint that doesn't match the component's design.
  @interactive_tags ~w(button select textarea)
  @text_input_types ~w(text email password number search tel url date datetime-local month time week)

  for {_label, route} <- Components.fixtures(), theme <- [:light, :dark] do
    @route route
    @theme theme

    test "interactive cells on #{@route} (#{@theme}) meet ≥ 24×24 target size",
         %{conn: conn} do
      parent = self()

      conn
      |> visit(@route)
      |> A11y.set_theme(@theme)
      |> A11y.await_live_connected()
      |> PhoenixTest.Playwright.evaluate(
        """
        (() => {
          const interactiveTags = #{Jason.encode!(@interactive_tags)};
          const textTypes = #{Jason.encode!(@text_input_types)};
          const failures = [];
          document.querySelectorAll('[data-fixture-cell]').forEach((el) => {
            if (el.hasAttribute('data-target-size-exception')) return;
            const tag = el.tagName.toLowerCase();
            const isInteractive =
              interactiveTags.includes(tag) ||
              (tag === 'input' && textTypes.includes((el.getAttribute('type') || 'text').toLowerCase()));
            if (!isInteractive) return;
            const r = el.getBoundingClientRect();
            if (r.width < 24 || r.height < 24) {
              failures.push({
                id: el.getAttribute('data-fixture-cell'),
                tag,
                width: Math.round(r.width * 100) / 100,
                height: Math.round(r.height * 100) / 100,
              });
            }
          });
          return failures;
        })()
        """,
        fn failures -> send(parent, {:failures, failures}) end
      )

      failures =
        receive do
          {:failures, list} -> list
        after
          5_000 -> raise "timed out collecting target-size measurements"
        end

      if failures != [] do
        details =
          Enum.map_join(failures, "\n", fn f ->
            "  - #{f["tag"]} `#{f["id"]}` measures #{f["width"]}×#{f["height"]}"
          end)

        raise ExUnit.AssertionError,
          message:
            "WCAG 2.5.8 Target Size (Minimum) — interactive cells under 24×24 on #{@route} [#{@theme}]:\n#{details}\n\n" <>
              "If the cell is intentionally below floor (e.g. the WCAG spacing exception applies), add `data-target-size-exception` to the rendered element."
      end
    end
  end
end
