# Pulsar

Beautiful, accessible Phoenix LiveView components built on [Stellar](../stellar).

Pulsar provides production-ready, styled components that wrap Stellar's headless components with gorgeous Tailwind CSS styling. Get the accessibility and behavior of Stellar with the visual design of a complete design system.

## Features

- 🌟 **Built on Stellar** - Full accessibility and behavior from Stellar's headless components
- 🎨 **Tailwind-first** - Styled with Tailwind CSS utilities and semantic color tokens
- 🌙 **Dark mode ready** - Automatic light/dark mode support via CSS custom properties  
- 📚 **Well documented** - TypeScript-like documentation with `:values` validation
- 🔧 **Dual mode** - Use as library or generate components for full customization
- ⚡ **Zero JavaScript** - Pure Phoenix LiveView with colocated hooks
- 🎯 **Semantic colors** - Use `primary`, `success`, `error` instead of `blue-500`, `green-600`

## Quick Start

### Installation

Add Pulsar to your Phoenix application:

```bash
# Add to mix.exs
{:pulsar, "~> 0.1"}

# Or use the installer
mix pulsar.install
```

### Library Mode

Import components directly:

```elixir
# In your component/LiveView
use PulsarWeb, :components

# In templates
<.button variant="primary" size="lg">
  Save Changes
</.button>

<.button variant="outline" navigate={~p"/dashboard"}>
  Dashboard
</.button>
```

### Generator Mode

Generate components for full customization:

```bash
# Generate individual components
mix pulsar.gen.button
mix pulsar.gen.card

# Or generate all components
mix pulsar.gen.all
```

## Components

### Button

Interactive button with semantic variants and sizes.

```elixir
<.button variant="primary">Primary</.button>
<.button variant="success" size="lg" loading={@saving}>Save</.button>
<.button variant="outline" navigate={~p"/help"}>Help</.button>
```

**Variants**: `primary`, `secondary`, `success`, `error`, `warning`, `ghost`, `outline`, `link`  
**Sizes**: `sm`, `md`, `lg`, `icon`

All Stellar button props are supported: `loading`, `disabled`, `navigate`, `href`, `patch`, etc.

## Theming

Pulsar uses CSS custom properties that reference Tailwind's color palette:

```css
@theme inline {
  /* Primary uses Tailwind's blue */
  --color-primary-500: var(--color-blue-500);
  
  /* Success uses Tailwind's green */  
  --color-success-500: var(--color-green-500);
  
  /* Semantic surface colors */
  --color-background: var(--color-white);
  --color-dark-background: var(--color-gray-950);
}
```

### Custom Colors

Change the theme by updating color references:

```css
@theme inline {
  /* Change primary from blue to purple */
  --color-primary-500: var(--color-purple-500);
  --color-primary-600: var(--color-purple-600);
  
  /* Or use custom OKLCH colors */
  --color-primary-500: oklch(61% 0.24 290);
}
```

### Dark Mode

Dark mode works automatically with Tailwind's `dark:` variant:

```html
<html class="dark">
  <!-- Components automatically adapt -->
  <.button variant="primary">Dark mode button</.button>
</html>
```

## Development

### Component Showcase

See all components in action in the standalone storybook app:

```bash
# Navigate to storybook directory
cd ../storybook

# Install dependencies and run
mix deps.get
mix phx.server
```

Visit `http://localhost:4000` to browse components with interactive examples.

### Testing

```bash
mix test
mix credo
```

### Architecture

Pulsar components wrap Stellar components with styling:

```elixir
def button(assigns) do
  # Merge Pulsar styling with user classes
  stellar_assigns = assigns
    |> Map.put(:class, TailwindMerge.merge([
      button_base(),
      variant_classes(assigns.variant), 
      size_classes(assigns.size),
      assigns.class
    ]))
    |> Map.drop([:variant, :size])  # Remove Pulsar-specific attrs

  ~H"""
  <Stellar.Components.Button.button {...stellar_assigns}>
    <%= render_slot(@inner_block) %>
  </Stellar.Components.Button.button>
  """
end
```

This approach provides:
- All Stellar accessibility and behavior
- Beautiful Tailwind styling  
- Intelligent class merging via TailwindMerge
- Full prop pass-through to Stellar

## Roadmap

- [ ] Card component
- [ ] Alert component  
- [ ] Badge component
- [ ] Form components (Input, Select, Checkbox, etc.)
- [ ] Navigation components
- [ ] Data display components
- [ ] Additional themes

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Built on top of:
- [Stellar](../stellar) - Headless LiveView components
- [Tailwind CSS](https://tailwindcss.com) - Utility-first CSS framework
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Rich, interactive web applications
- [Igniter](https://github.com/ash-project/igniter) - Code generation and project patching

