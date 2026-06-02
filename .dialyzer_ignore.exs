[
  # Sidebar's `toggle/2`, `show/2`, `hide/2` follow the idiomatic Phoenix
  # `def helper(js \\ %JS{}, id)` shape. The `%JS{}` default literal builds the
  # opaque `Phoenix.LiveView.JS.t()` outside the JS module, so dialyzer reports
  # `call_without_opaque` when they are called with the default — the same
  # false positive Phoenix's own JS helpers trip. Runtime behavior is correct.
  {"lib/pulsar/components/sidebar.ex", :call_without_opaque}
]
