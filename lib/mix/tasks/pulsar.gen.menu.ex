defmodule Mix.Tasks.Pulsar.Gen.Menu do
  use Pulsar.Generator,
    component: :menu,
    example: "mix pulsar.gen.menu",
    long_doc: """
    Generates an orientation-aware navigation menu for app-shell navigation.

    Renders a list of navigation links with optional sections and collapsible
    groups. The same component works `vertical` (default) inside a sidebar and
    `horizontal` inside a top bar; the orientation flips the layout direction
    and the arrow-key affordance, and switches a group between an in-place
    disclosure and a dropdown popover.

    ## Example

    ```sh
    mix pulsar.gen.menu

    # With custom module namespace
    mix pulsar.gen.menu --components-module=MyAppWeb.UI
    ```

    ## Features

    - Orientations: vertical (sidebar) and horizontal (top bar)
    - Composable sub-components: menu_item, menu_section, menu_group
    - Item composition: leading icon, label, trailing affordance
    - Link variants: navigate, patch, href (action button when no target)
    - Active item via `aria-current="page"`
    - Groups via the APG disclosure pattern (`aria-expanded` + `aria-controls`)
    - Honors the sidebar icon-rail collapse contract with no runtime state
    - Keyboard navigation, Escape-to-close, and click-outside dismissal
    - Accessibility built-in (nav landmark, list of links, focus-visible rings)

    ## Dependencies

    This component requires: icon, popover

    ## Usage Examples

    ```elixir
    <.menu label="Primary">
      <.menu_item navigate={~p"/"} icon="hero-home" active>Home</.menu_item>
      <.menu_section label="Workspace">
        <.menu_group label="Reports" icon="hero-chart-bar">
          <.menu_item navigate={~p"/reports/sales"}>Sales</.menu_item>
        </.menu_group>
      </.menu_section>
    </.menu>

    # Horizontal menu in a navbar region — groups open as dropdowns
    <.menu orientation="horizontal" label="Primary">
      <.menu_item navigate={~p"/"} active>Home</.menu_item>
      <.menu_group orientation="horizontal" label="Products">
        <.menu_item navigate={~p"/products/app"}>App</.menu_item>
      </.menu_group>
    </.menu>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
