defmodule Mix.Tasks.Pulsar.Gen.Sidebar do
  use Pulsar.Generator,
    component: :sidebar,
    example: "mix pulsar.gen.sidebar",
    long_doc: """
    Generates a responsive, collapsible sidebar panel for app-shell navigation.

    Creates a `<nav>` landmark that sits beside your main content on large
    screens and becomes an off-canvas drawer with a backdrop on small ones.
    Drive it from anywhere with the `toggle/2`, `show/2`, and `hide/2` helpers.

    ## Example

    ```sh
    mix pulsar.gen.sidebar

    # With custom module namespace
    mix pulsar.gen.sidebar --components-module=MyAppWeb.UI
    ```

    ## Features

    - Sides: left, right
    - Collapse modes: icon (rail), offcanvas (hide), none (fixed)
    - Responsive off-canvas drawer below the `lg` breakpoint, with backdrop,
      focus trap, and Escape-to-close
    - Variants: solid, outline, ghost, elevated
    - Colors: neutral, primary, secondary, success, danger, warning, info
    - Sizes: xs, sm, md, lg, xl
    - Header / content / footer regions
    - Accessibility built-in (navigation landmark, focus management)

    ## Usage Examples

    ```elixir
    <div class="flex min-h-svh">
      <.sidebar id="app-sidebar" collapsible="icon">
        <:header>Acme</:header>
        <nav>...</nav>
        <:footer>...</:footer>
      </.sidebar>
      <main class="flex-1">...</main>
    </div>

    # Toggle from a button anywhere on the page
    <button phx-click={Sidebar.toggle("app-sidebar")} aria-controls="app-sidebar">
      Menu
    </button>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
