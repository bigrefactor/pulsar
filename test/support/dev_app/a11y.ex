defmodule Pulsar.DevApp.A11y do
  @moduledoc """
  Helpers for running axe-core against fixture LiveViews under
  `phoenix_test_playwright`.

  Tests pipe a `PhoenixTest.Playwright` conn through `set_theme/2` and
  `assert_axe_clean/1`; both return the conn so they compose with `visit/2`.
  """

  # axe-core typically completes in well under a second on small fixture
  # pages; cap the audit at 10 s so a wedged page surfaces quickly. A
  # complex fixture can override per-test with `@tag timeout: …`.
  @axe_timeout 10_000

  @doc """
  Sets `document.documentElement.dataset.theme` on the current page.

  Forces a synchronous style + layout flush after the attribute change.
  Chromium batches style recalc, so without the flush the next `evaluate`
  (e.g. axe-core injection in `assert_axe_clean/1`) can read stale computed
  styles where CSS variables have updated to the new theme's values but
  `color: var(--…)` properties using them still resolve to the previous
  theme's value. Toggling `body.style.display` + reading `offsetHeight`
  is the canonical way to force the flush.
  """
  def set_theme(conn, theme) when theme in [:light, :dark] do
    # Hard-coded JS payloads (no interpolation) so this call site stays
    # un-injectable even if the guard above is widened to accept strings later.
    js =
      case theme do
        :light ->
          "document.documentElement.dataset.theme = 'light'; document.body.style.display='none'; void document.body.offsetHeight; document.body.style.display=''; void document.body.offsetHeight"

        :dark ->
          "document.documentElement.dataset.theme = 'dark'; document.body.style.display='none'; void document.body.offsetHeight; document.body.style.display=''; void document.body.offsetHeight"
      end

    PhoenixTest.Playwright.evaluate(conn, js)
  end

  @doc """
  Waits for the LiveView root element to reach `phx-connected` state, which
  signals that the LV channel has joined and any client-side hooks
  (`Phoenix.LiveView.ColocatedHook`) have mounted.

  `visit/2` only awaits the page's `load` event, not the LV channel join —
  pressing keys before hooks mount means the keyboard listeners aren't
  attached yet and the test sees no state change.
  """
  def await_live_connected(conn) do
    PhoenixTest.Playwright.assert_has(conn, "[data-phx-main].phx-connected")
  end

  @doc """
  Asserts that the currently focused element has the given `id`. Reads
  `document.activeElement.id` via the page's JavaScript context.
  """
  def assert_focused(conn, id) when is_binary(id) do
    PhoenixTest.Playwright.evaluate(conn, "document.activeElement && document.activeElement.id || ''", fn actual ->
      if actual != id do
        raise ExUnit.AssertionError,
          message: "expected element ##{id} to be focused, was '#{actual}'"
      end
    end)
  end

  @doc """
  Focuses the element with the given `id`, firing its `focus`/`focusin`
  handlers. Used to exercise focus-driven behavior (e.g. a tooltip opening on
  keyboard focus) without conflating it with a key press.
  """
  def focus(conn, id) when is_binary(id) do
    expr = "var el = document.getElementById(#{Jason.encode!(id)}); el && el.focus()"
    PhoenixTest.Playwright.evaluate(conn, expr)
  end

  @doc """
  Asserts that the element with the given `id` is an open *modal* dialog
  (`:modal` matches). Distinguishes a `showModal()` dialog — which traps focus
  and is dismissable by Escape — from a non-modal `<dialog open>`.
  """
  def assert_modal(conn, id) when is_binary(id) do
    expr =
      "Boolean(document.getElementById(#{Jason.encode!(id)}) && document.getElementById(#{Jason.encode!(id)}).matches(':modal'))"

    PhoenixTest.Playwright.evaluate(conn, expr, fn modal? ->
      if !modal? do
        raise ExUnit.AssertionError, message: "expected ##{id} to be an open modal dialog"
      end
    end)
  end

  @doc """
  Asserts that the currently focused element is NOT inside any ancestor
  matching `selector`. Used to verify focus has moved out of a container
  (e.g. tabbing out of a radio group).
  """
  def refute_focused_within(conn, selector) when is_binary(selector) do
    expr = "Boolean(document.activeElement && document.activeElement.closest(#{Jason.encode!(selector)}))"

    PhoenixTest.Playwright.evaluate(conn, expr, fn inside? ->
      if inside? do
        raise ExUnit.AssertionError, message: "focus is still inside #{selector}"
      end
    end)
  end

  @doc """
  Waits for any running CSS animations/transitions on the element `id` (and its
  descendants) to finish, so a subsequent contrast sample reads the settled
  colors. Overlays like DropdownMenu play a `fade-in` (opacity 0 → 1) on open;
  axe-core composites the live pixel, so sampling mid-fade reports a blended,
  artificially low contrast. `Element.getAnimations({subtree: true})` covers the
  panel and its items; each animation's `finished` promise resolves when it ends.
  """
  def await_animations(conn, id) when is_binary(id) do
    fun = """
    async () => {
      const el = document.getElementById(#{Jason.encode!(id)});
      if (!el || !el.getAnimations) return;
      await Promise.all(el.getAnimations({ subtree: true }).map((a) => a.finished.catch(() => {})));
    }
    """

    PhoenixTest.Playwright.evaluate(conn, fun, is_function: true, timeout: 2_000)
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

  @doc """
  Asserts the element with `id` is actually rendered visible — not merely present
  in the DOM. Checks computed `visibility`/`display` and a non-zero layout box.

  This is the assertion that catches a broken disclosure: a hook can flip
  `aria-expanded`/`data-expanded` while the panel stays `visibility: hidden` or
  collapsed to `grid-rows: 0fr` (e.g. a missing `group/*` root), so an
  attribute-only check passes while nothing opens on screen.
  """
  def assert_visible(conn, id) when is_binary(id), do: check_visible(conn, id, true)

  @doc """
  The inverse of `assert_visible/2`: asserts the element with `id` is present but
  not visible (collapsed/hidden).
  """
  def refute_visible(conn, id) when is_binary(id), do: check_visible(conn, id, false)

  defp check_visible(conn, id, expected) do
    # Tri-state so `refute_visible/2` distinguishes "present but hidden" from
    # "missing entirely" — a vanished element must fail, not silently pass as
    # "hidden". (Can't lean on Playwright's `assert_has`: it waits for the
    # element to be *visible*, which never settles for a collapsed panel.)
    expr =
      "(function(){var el=document.getElementById(#{Jason.encode!(id)});if(!el)return 'missing';" <>
        "var s=getComputedStyle(el);var r=el.getBoundingClientRect();" <>
        "return (s.visibility!=='hidden'&&s.display!=='none'&&r.height>0)?'visible':'hidden';})()"

    want = if expected, do: "visible", else: "hidden"

    PhoenixTest.Playwright.evaluate(conn, expr, fn actual ->
      if actual != want do
        raise ExUnit.AssertionError,
          message: "expected ##{id} to be #{want}, was #{actual}"
      end
    end)
  end
end
