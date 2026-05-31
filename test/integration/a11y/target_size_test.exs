defmodule Pulsar.Integration.A11y.TargetSizeTest do
  @moduledoc """
  WCAG 2.5.8 Target Size (Minimum) regression gate. Per fixture × theme,
  asserts every interactive `[data-fixture-cell]` meets ≥ 24×24 CSS
  pixels via `getBoundingClientRect()`.

  Interactive cells are those whose tag is `button`, `select`, or
  `textarea`, or whose tag is `input` and `type` is in the text-input
  allowlist (`text`, `email`, `password`, `number`, `search`, `tel`,
  `url`, `date`, `datetime-local`, `month`, `time`, `week`). Checkbox
  inputs (`type="checkbox"`) and switch cells (any cell containing a
  `[role="switch"]`) are also enforced: both carry a guaranteed 24×24
  pointer hit box at every size, so they pass on size rather than via
  the spacing exception (see `checkbox.md`, `switch.md` 2.5.8 entries).
  Radio inputs (`type="radio"`) remain excluded — they still lean on the
  spacing exception. `<a>` is excluded because the WCAG inline-link exception
  is context-dependent (the same link size can be a 2.5.8 violation
  standalone and a pass inline in body text); inline links are
  explicitly supported by the Link component, so gating them here
  would force a one-size-fits-all constraint that doesn't match the
  component's design.

  Cells carrying `data-target-size-exception` are allowlisted (e.g.
  flash dismiss button — per WCAG 2.5.8 spacing exception).

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
            const inputType = (el.getAttribute('type') || 'text').toLowerCase();
            const role = (el.getAttribute('role') || '').toLowerCase();
            const isInteractive =
              interactiveTags.includes(tag) ||
              (tag === 'input' && textTypes.includes(inputType)) ||
              // Visible checkbox input is its own 24×24 target. The switch's
              // native input is `role="switch"` + `sr-only` (the hidden
              // control) — skip it here; the switch is gated via its wrapper.
              (tag === 'input' && inputType === 'checkbox' && role !== 'switch') ||
              // Switch wrapper cell: a cell that wraps the [role="switch"] control.
              el.querySelector('[role="switch"]') !== null;
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
