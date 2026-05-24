defmodule Mix.Tasks.Pulsar.Gen.Link do
  use Pulsar.Generator,
    component: :link,
    example: "mix pulsar.gen.link",
    long_doc: """
    Generates an accessible link component with semantic variants, security, and Phoenix navigation

    Creates a link component with XSS protection, automatic external link security,
    Phoenix navigation support, and semantic color schemes. Perfect for inline links,
    navigation, and external resources.

    ## Example

    ```sh
    mix pulsar.gen.link

    # With custom module namespace
    mix pulsar.gen.link --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: solid (no underline), ghost (hover underline), outline (always underlined)
    - Colors: primary, secondary, danger, neutral, and all semantic colors
    - XSS protection (blocks javascript:, data: protocols)
    - Automatic external link security (rel="noopener noreferrer" for target="_blank")
    - Phoenix navigation support (navigate, patch, href)
    - Start/end icon slots
    - WCAG 2.1 AA accessibility compliance
    - Automatic dark mode support

    ## Dependencies

    This component requires: icon

    ## Usage Examples

    ```elixir
    # Basic link
    <.link href="/profile">View Profile</.link>

    # External link (auto-secure)
    <.link href="https://example.com">External Link</.link>

    # Phoenix navigation
    <.link navigate={~p"/dashboard"} variant="ghost" color="danger">
      Dashboard
    </.link>

    # Link with icon
    <.link href="/settings">
      <:start_icon>
        <.icon name="hero-cog" />
      </:start_icon>
      Settings
    </.link>
    ```

    ## Security Features

    - XSS protection blocks dangerous protocols (javascript:, data:, etc.)
    - Auto-adds rel="noopener noreferrer" for external links with target="_blank"
    - Proper handling of external vs internal navigation
    - Safe Phoenix LiveView navigation

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
