defmodule Mix.Tasks.Pulsar.Gen.Navbar do
  use Pulsar.Generator,
    component: :navbar,
    example: "mix pulsar.gen.navbar",
    long_doc: """
    Generates a top app-bar for app-shell navigation.

    Creates a banner with `left`, `center`, and `right` regions you compose
    freely — brand, search field, navigation, notifications, a user menu. Pair
    it with a sidebar by wiring `on_menu_toggle` to the sidebar's toggle helper;
    the navbar then renders a menu button that drives it.

    ## Example

    ```sh
    mix pulsar.gen.navbar

    # With custom module namespace
    mix pulsar.gen.navbar --components-module=MyAppWeb.UI
    ```

    ## Features

    - Generic regions: left, center, right
    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Optional sticky positioning with scroll-margin handling
    - Optional menu button wired to an overridable `on_menu_toggle`
    - Accessibility built-in (banner landmark, labeled menu button)

    ## Usage Examples

    ```elixir
    <.navbar sticky>
      <:left><.logo /></:left>
      <:center>
        <input type="search" placeholder="Search" class="w-full max-w-sm" />
      </:center>
      <:right><.user_menu /></:right>
    </.navbar>

    # Drive a sidebar from the menu button
    <.navbar on_menu_toggle={Sidebar.toggle("app-sidebar")} menu_controls="app-sidebar">
      <:left><.logo /></:left>
    </.navbar>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
