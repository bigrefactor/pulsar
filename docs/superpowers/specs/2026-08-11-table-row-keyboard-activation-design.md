# Table Row Keyboard Activation Design

## Problem

Clickable table rows currently render `phx-hook` through a dynamic expression. Phoenix LiveView only expands a colocated hook's dot-prefixed shorthand when the attribute is a literal, so the browser receives `.PulsarTableRow` instead of the manifest's fully qualified hook name. Non-stream rows also lack an ID unless the caller supplies `row_id`, preventing LiveView from mounting any hook independently of the naming defect.

The result is a control that advertises `role="button"` and `tabindex="0"` but does not respond to Enter or Space.

## Design

The table will enumerate its rows with zero-based indexes while rendering. Each data row will use the caller's resolved `row_id` when one exists; otherwise it will receive a deterministic fallback ID in the form `<table-id>-row-<index>`. Existing stream behavior remains unchanged because streams already install a `row_id` resolver for their `{dom_id, item}` tuples.

Every data row will declare `phx-hook=".PulsarTableRow"` as a static literal. This lets LiveView rewrite the colocated hook name to its fully qualified module name. A `data-row-click` boolean attribute will tell the hook whether the row is interactive. On non-clickable rows the hook mounts but installs no activation listeners. Clickable rows retain their current role, tab stop, click command, disabled/busy checks, and Enter/Space behavior.

The component template remains the source of truth. The committed component module will be regenerated with `mix pulsar.sync`; it will not be edited directly.

## Testing

Component rendering tests will assert that a non-stream clickable row receives a zero-based fallback ID, a fully qualified hook name, and the behavior-gating data attribute. Existing custom and stream row-ID tests will continue to cover those paths.

A new development fixture at `/keyboard/table` will render a non-stream table with `row_click` and expose the selected row as visible text. A Playwright integration test will press Space and Enter on table rows and assert the visible selection changes, proving the colocated hook mounts and drives LiveView events. This browser test is the regression boundary that static rendering and axe checks cannot provide.

## Documentation and Compatibility

`CHANGELOG.md` will record the accessibility fix under `Unreleased`. The public component API does not change. Rows without an explicit `row_id` gain deterministic DOM IDs, and all data rows gain a mounted but inert hook plus `data-row-click`; interactive semantics remain conditional on `row_click`.
