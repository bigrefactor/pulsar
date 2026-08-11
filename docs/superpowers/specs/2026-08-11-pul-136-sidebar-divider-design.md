# PUL-136 Sidebar Divider Design

## Problem

The sidebar's left or right structural divider takes its color from the neutral `solid` and `outline` entries in
`@color_config`. Both entries currently use `border-border-strong`, which creates an unnecessarily bright shell seam,
especially in dark mode.

The global border-token scale also has a large step between `border` and `border-strong`, but changing that scale would
alter many components whose asserted edges intentionally use `border-strong`. That broader visual review is outside
PUL-136's scope.

## Design

Change the neutral `solid` and `outline` sidebar color configurations from `border-border-strong` to `border-border`.
Keep the border-width and side anchoring classes in `side_classes/1`, preserving `border-r` for left sidebars and
`border-l` for right sidebars. Keep colored sidebar variants unchanged so their existing semantic color borders remain
intact.

Make the change in `priv/templates/sidebar.ex.eex`, then run `mix pulsar.sync` to regenerate the committed
`lib/pulsar/components/sidebar.ex` module. Do not edit the generated module directly.

## Testing and Documentation

Add focused component tests for neutral `solid` and `outline` sidebars. Each test will assert that rendered classes use
`border-border` and exclude `border-border-strong`; this reproduces the current failure and guards against regression.

Update `docs/a11y/sidebar.md` to describe the divider as decorative structural separation rather than a contrast-bearing
control boundary. Update `CHANGELOG.md` under `Unreleased` because the rendered sidebar appearance changes for users.

Verify with the focused sidebar test, template synchronization, formatting, and the relevant broader test suite.
