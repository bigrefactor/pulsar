# Pulsar

Beautiful, accessible Phoenix LiveView components.

Pulsar provides production-ready, styled components with gorgeous Tailwind CSS styling. This self-contained library includes all accessibility and behavior built-in while providing complete control and customization.

## Features

- 🚀 **Single Dependency** - Only requires TailwindMerge for intelligent class merging
- ♿ **Full Accessibility** - WCAG 2.1 AA compliant with proper ARIA attributes and keyboard navigation
- 🎨 **Tailwind-first** - Styled with Tailwind CSS utilities and semantic color tokens
- 🌙 **Dark mode ready** - Automatic light/dark mode support via CSS custom properties  
- 📚 **Well documented** - TypeScript-like documentation with `:values` validation
- 🔧 **Production ready** - High-quality components for Phoenix applications
- ⚡ **Zero JavaScript** - Pure Phoenix LiveView with colocated hooks when needed
- 🎯 **Semantic colors** - Use `primary`, `success`, `error` instead of `blue-500`, `green-600`
- 🛡️ **Security first** - XSS protection and proper input validation built-in

## Quick Start

### Installation

Add Pulsar to your Phoenix application:

```bash
# Add to mix.exs dependencies
{:pulsar, "~> 0.1"},
{:tailwind_merge, "~> 0.2"}

# Install dependencies
mix deps.get
```

### Library Mode

Import components directly:

```elixir
# In your component/LiveView
import Pulsar.Components.{Button, Label, Link, Input, Textarea, Select, Checkbox, Switch, RadioGroup}

# In templates
<.button variant="primary" size="lg">
  Save Changes
</.button>

<.input field={@form[:email]} type="email" label="Email Address" />

<.select field={@form[:category]} options={@categories} />
```

## Components

### Core Components (All Available)

**Form Components:**
- **Button** - Interactive buttons with semantic variants (`primary`, `success`, etc.)
- **Input** - Text inputs with validation, decorators, and accessibility
- **Textarea** - Multi-line text inputs with character counting
- **Select** - Dropdown selects with option generation
- **Checkbox** - Checkboxes with card variants and field integration
- **Switch** - Toggle switches with Phoenix form support
- **RadioGroup** - Radio button groups with proper ARIA semantics

**UI Components:**
- **Label** - Semantic labels with error states and accessibility
- **Link** - Navigation links with XSS protection and Phoenix integration

### Examples

```elixir
# Button with loading state
<.button variant="primary" size="lg" loading={@saving}>
  Save Changes
</.button>

# Form input with validation
<.input field={@form[:email]} type="email" 
        label="Email Address" 
        placeholder="Enter your email" />

# Select with options
<.select field={@form[:role]} 
         options={[{"Admin", "admin"}, {"User", "user"}]} />

# Checkbox with card styling
<.checkbox field={@form[:terms]} 
           variant="card" 
           label="I agree to the terms" />
```

**All components support:**
- Phoenix form integration with `field` attribute
- Full accessibility (ARIA, keyboard navigation)
- Dark mode via Tailwind's `dark:` classes
- Security features (XSS protection, input validation)
- Custom styling via `class` attribute with intelligent merging

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

Pulsar components are self-contained with inlined accessibility and behavior:

```elixir
def button(assigns) do
  # Normalize Phoenix form field if provided
  normalized_assigns = normalize_field_props(assigns)
  
  # Merge styling classes intelligently
  classes = TailwindMerge.merge([
    button_base_classes(),
    variant_classes(assigns.variant), 
    size_classes(assigns.size),
    normalized_assigns.class
  ])

  ~H"""
  <button type="button" class={classes} {...assign_computed_attributes(normalized_assigns)}>
    <%= render_slot(@inner_block) %>
  </button>
  """
end
```

This approach provides:
- **Complete independence** - No external component dependencies
- **Full accessibility** - ARIA attributes, keyboard navigation, screen reader support
- **Intelligent class merging** - TailwindMerge prevents style conflicts
- **Phoenix integration** - Seamless form field support with validation
- **Security first** - XSS protection and proper escaping built-in

## Migration Guide

If you were using an older version of Pulsar:

1. **Update imports** - Import directly from `Pulsar.Components.*`
2. **No API changes** - All component APIs remain identical
3. **Clean compilation** - Run `mix deps.get && mix compile --force`

## Roadmap

- [x] **Core Form Components** - Button, Input, Textarea, Select, Checkbox, Switch, RadioGroup
- [x] **UI Components** - Label, Link
- [x] **Self-Contained Components** - Zero external dependencies beyond TailwindMerge
- [ ] Card component
- [ ] Alert component  
- [ ] Badge component (partial implementation available)
- [ ] Navigation components
- [ ] Data display components
- [ ] Additional themes

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Built with:
- [TailwindMerge](https://hex.pm/packages/tailwind_merge) - Intelligent Tailwind class merging
- [Tailwind CSS](https://tailwindcss.com) - Utility-first CSS framework  
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Rich, interactive web applications

Originally inspired by:
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Rich, interactive web applications

