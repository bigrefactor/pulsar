defmodule Mix.Tasks.Pulsar.Gen.DropdownMenu do
  use Pulsar.Generator,
    component: :dropdown_menu,
    example: "mix pulsar.gen.dropdown_menu",
    long_doc: """
    Generates an anchored action menu opened from a trigger button (the APG
    menu-button pattern).

    Built on the popover primitive in click mode: the trigger opens a menu of
    actions anchored to it; outside-click or Escape closes it and returns focus
    to the trigger. A colocated hook provides the menu keyboard model (roving
    focus, type-ahead, submenu navigation). Requires the icon and popover
    components.

    ## Example

    ```sh
    mix pulsar.gen.dropdown_menu

    # With custom module namespace
    mix pulsar.gen.dropdown_menu --components-module=MyAppWeb.UI
    ```

    ## Features

    - Items as action buttons or navigation links, with leading icons and
      trailing shortcut hints
    - Checkbox and radio items, labelled groups, and separators
    - Submenus (Right/Left arrow, hover) anchored as nested menus
    - Destructive item styling for delete-style actions
    - Full keyboard navigation: Up/Down, Home/End, type-ahead, Enter/Space to
      activate, Escape to close and restore focus
    - Anchored placement with flip + shift so the menu stays on screen
    - Surface variants/colors/sizes inherited from the popover primitive
    - Accessibility built-in (role="menu"/"menuitem", aria-haspopup, roving
      tabindex, aria-checked)

    ## Usage Examples

    ```elixir
    <.dropdown_menu id="account" label="Account">
      <:trigger><.button>Account</.button></:trigger>
      <.dropdown_menu_item navigate={~p"/profile"} icon="hero-user">Profile</.dropdown_menu_item>
      <.dropdown_menu_separator />
      <.dropdown_menu_item phx-click="sign_out" destructive>Sign out</.dropdown_menu_item>
    </.dropdown_menu>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
