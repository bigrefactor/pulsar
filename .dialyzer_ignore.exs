# Twm.merge/1's @spec is narrower (`String.t() | [String.t()] -> String.t()`)
# than its runtime accepts — `flatten_and_filter_classes/1` strips nil, false,
# and nested lists, and Pulsar components pass values dialyzer cannot prove are
# non-nil (e.g. map-lookup helpers like `@size_config[size]`). Dialyzer therefore
# reports cascading `no_return` on every public component / private helper that
# transitively calls `merge`, and then `unused_fun` on downstream helpers whose
# only callers were marked unreachable. Because the inferred type collapses to
# `none()`, the explicit `@spec public_component(map()) :: Rendered.t()` on each
# component also trips `invalid_contract`.
#
# Runtime correctness is covered by the test suite (829 tests). The proper long-
# term fix is to widen Twm's `@spec` upstream; track that and remove these
# entries once a Twm release lands with a permissive type.
[
  {"lib/pulsar/components/badge.ex", :no_return},
  {"lib/pulsar/components/badge.ex", :invalid_contract},
  {"lib/pulsar/components/button.ex", :no_return},
  {"lib/pulsar/components/button.ex", :invalid_contract},
  {"lib/pulsar/components/card.ex", :no_return},
  {"lib/pulsar/components/card.ex", :invalid_contract},
  {"lib/pulsar/components/checkbox.ex", :no_return},
  {"lib/pulsar/components/checkbox.ex", :invalid_contract},
  {"lib/pulsar/components/checkbox.ex", :unused_fun},
  {"lib/pulsar/components/flash.ex", :no_return},
  {"lib/pulsar/components/flash.ex", :invalid_contract},
  {"lib/pulsar/components/header.ex", :no_return},
  {"lib/pulsar/components/header.ex", :invalid_contract},
  {"lib/pulsar/components/input.ex", :no_return},
  {"lib/pulsar/components/list.ex", :no_return},
  {"lib/pulsar/components/list.ex", :invalid_contract},
  {"lib/pulsar/components/list.ex", :unused_fun},
  {"lib/pulsar/components/menu.ex", :no_return},
  {"lib/pulsar/components/menu.ex", :invalid_contract},
  {"lib/pulsar/components/navbar.ex", :no_return},
  {"lib/pulsar/components/navbar.ex", :invalid_contract},
  {"lib/pulsar/components/sidebar.ex", :no_return},
  {"lib/pulsar/components/sidebar.ex", :invalid_contract},
  {"lib/pulsar/components/switch.ex", :no_return},
  {"lib/pulsar/components/switch.ex", :invalid_contract},
  {"lib/pulsar/components/textarea.ex", :no_return},
  {"lib/pulsar/components/textarea.ex", :invalid_contract},
  {"lib/pulsar/components/textarea.ex", :unused_fun},

  # Sidebar's `toggle/2`, `show/2`, `hide/2` follow the idiomatic Phoenix
  # `def helper(js \\ %JS{}, id)` shape. The `%JS{}` default literal builds the
  # opaque `Phoenix.LiveView.JS.t()` outside the JS module, so dialyzer reports
  # `call_without_opaque` when they are called with the default — the same
  # false positive Phoenix's own JS helpers trip. Runtime behavior is correct.
  {"lib/pulsar/components/sidebar.ex", :call_without_opaque}
]
