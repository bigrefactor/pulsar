# CLAUDE.md

This file provides guidance to Claude Code when working with the Pulsar component generator.

## Repository Context

Pulsar is a **generator-based component system** for Phoenix LiveView, similar to shadcn/ui for React. It generates styled, production-ready components directly into Phoenix applications rather than being imported as a library dependency.

## Project Architecture

### Core Philosophy
- **Generator-First**: Components are generated into user apps, not imported as dependencies
- **Utility-First**: Built on Tailwind CSS classes, not custom CSS
- **Phoenix-Native**: Uses Phoenix.LiveView.JS exclusively, zero external JavaScript
- **Accessible by Default**: WCAG 2.1 AA compliance with ARIA attributes built-in
- **Copy-Paste Friendly**: Generated components can be fully customized after generation

### Directory Structure
```
lib/pulsar/
├── pulsar.ex              # Main module with CLI interface
├── generators/            # Mix task generators for each component
│   ├── button.ex         # mix pulsar.gen.button
│   ├── form.ex           # mix pulsar.gen.form  
│   └── modal.ex          # mix pulsar.gen.modal
└── templates/            # Component templates used by generators
    ├── button/
    ├── form/
    └── modal/

priv/templates/           # Template files for code generation
├── button.ex.eex        
├── form.ex.eex
└── modal.ex.eex
```

## Development Patterns

### Generator Implementation
Generators follow Mix task conventions:
```elixir
defmodule Mix.Tasks.Pulsar.Gen.Button do
  use Mix.Task

  def run(args) do
    # Parse options
    # Generate component file in user's lib/my_app_web/components/
    # Update imports if needed
  end
end
```

### Component Templates
Templates use EEx for dynamic generation:
```elixir
# priv/templates/button.ex.eex
defmodule <%= @module_name %>.Components.Button do
  use Phoenix.Component
  
  attr :variant, :string, default: "primary"
  attr :class, :string, default: ""
  slot :inner_block, required: true
  
  def button(assigns) do
    ~H"""
    <button class={[
      base_classes(),
      variant_classes(@variant),
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

### Theme System
Components use semantic color naming with Tailwind:
- `bg-light-primary dark:bg-dark-primary` instead of hardcoded colors
- Variants map to theme color combinations
- Users customize via Tailwind config, not component props

## Quality Standards

### Code Generation
- Generate clean, idiomatic Elixir code
- Include proper documentation with @doc
- Add typespecs with @spec where appropriate
- Follow Phoenix LiveView component conventions

### Accessibility
- All interactive elements have proper ARIA labels
- Keyboard navigation follows WAI-ARIA patterns  
- Focus management built into components
- Screen reader announcements for state changes

### Testing
- Generator tests verify correct file creation
- Generated component tests for rendering and interaction
- Accessibility tests for ARIA attributes and keyboard navigation

## Commands

### Development
```bash
mix compile              # Compile the generator
mix test                # Run all tests
mix dialyzer            # Type checking
mix credo               # Code quality
```

### Generator Usage (in user apps)
```bash
mix pulsar.gen.button    # Generate button component
mix pulsar.gen.form      # Generate form components
mix pulsar.gen.modal     # Generate modal component
```

## Integration Patterns

### Phoenix LiveView
Components integrate seamlessly with LiveView:
```elixir
<.button variant="primary" phx-click="save" loading={@saving}>
  Save Changes
</.button>

<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" />
</.simple_form>
```

### Tailwind CSS
All styling through Tailwind utilities:
- No custom CSS files
- PurgeCSS compatible  
- Dark mode via Tailwind's dark: prefix
- Responsive design with Tailwind breakpoints

### Phoenix.JS Commands
All interactions use Phoenix's built-in JavaScript:
```elixir
# Modal interactions
JS.show(to: "#modal")
|> JS.focus_first(to: "#modal [tabindex='0']")

# Form validation feedback  
JS.add_class("border-red-500", to: "#field-#{field}")
|> JS.show(to: "#error-#{field}")
```

## Storybook Development

Pulsar includes a **Phoenix LiveView storybook** at `lib/pulsar/storybook/catalog_live.ex` for component development and showcasing. The storybook provides:

- **Live component preview** with all variants, sizes, and states
- **Dark/light mode toggle** for testing theme support
- **Usage examples** with code snippets
- **Interactive testing** of component behavior

### Storybook Requirements

**All new components MUST include a storybook page** that demonstrates:
1. **All variants** (primary, secondary, success, error, etc.)
2. **All sizes** (sm, md, lg, icon, etc.)
3. **All states** (normal, loading, disabled, etc.)
4. **Usage examples** with realistic code snippets
5. **Dark mode compatibility** for theme switching

To add a component to the storybook:
1. Add component entry to `@components` list in `catalog_live.ex`
2. Create showcase function (e.g., `button_showcase/1`)
3. Add route pattern to handle the component path
4. Include comprehensive examples and documentation

## Contributing Guidelines

When adding new components:
1. Create generator in `lib/pulsar/generators/`
2. Add template in `priv/templates/`
3. **Add storybook page** with all variants, states, and examples
4. Write comprehensive tests
5. Document usage patterns
6. Ensure accessibility compliance
7. Test with various Tailwind themes

When modifying existing components:
1. Update both generator and template
2. **Update storybook examples** to reflect changes
3. Maintain backwards compatibility where possible
4. Update documentation and examples
5. Test generation in sample Phoenix app