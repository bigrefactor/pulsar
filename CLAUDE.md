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

### Generator Architecture

Pulsar uses the **Igniter** library for sophisticated code generation and project modification. This allows generators to:

- **Smart File Creation**: Creates files only if they don't exist
- **No Dependency Management**: Components are generated directly - no external dependencies added
- **Import Updates**: Modifies existing files to add component imports
- **Conflict Resolution**: Handles module naming and path conflicts
- **Rollback Safety**: Can undo changes if generation fails

**Generator-Only Benefits:**
- **Tailwind Purging**: Generated classes in user's codebase are detected automatically
- **Zero Dependencies**: No external packages to manage or version conflicts
- **Complete Control**: Users own generated code and can modify freely
- **Simpler Builds**: No complex safelist configurations needed

**Key Files:**
- `lib/mix/tasks/pulsar/gen/*.ex` - Generator task implementations
- `lib/pulsar/components/*.ex` - Source components that get copied
- Uses Igniter for all file system operations

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

Pulsar uses a sophisticated semantic color system built on CSS custom properties that reference Tailwind's color palette. This allows for flexible theming while maintaining the utility-first approach.

#### How It Works

**1. CSS Custom Properties Layer**
```css
/* priv/static/themes/pulsar.css */
@theme inline {
  /* Semantic aliases pointing to Tailwind colors */
  --color-primary-500: var(--color-blue-500);
  --color-secondary-500: var(--color-violet-500);
  --color-success-500: var(--color-green-500);
  
  /* Surface colors for light/dark modes */
  --color-background: var(--color-white);
  --color-dark-background: var(--color-gray-950);
}
```

**2. Tailwind Integration**
Components use semantic names that automatically resolve to the theme:
```elixir
# Component code uses semantic names
"bg-primary-500 text-white dark:bg-primary-600"
```

**3. Dark Mode Strategy**
- Uses `data-theme="dark"` attribute (not class-based)
- Custom variant: `@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *))`
- Separate dark- prefixed colors for optimal contrast

#### Theme Customization

**Change Primary Color:**
```css
@theme inline {
  /* Change from blue to indigo */
  --color-primary-500: var(--color-indigo-500);
  --color-primary-600: var(--color-indigo-600);
  /* etc. */
}
```

**Create Brand Theme:**
```css
@theme inline {
  /* Use custom brand colors */
  --color-primary-500: #1e40af;  /* Custom brand blue */
  --color-secondary-500: #7c3aed; /* Custom brand purple */
}
```

#### Dark Mode Toggle

Toggle dark mode by setting the data attribute:
```javascript
document.documentElement.dataset.theme = 'dark'; // Enable
document.documentElement.dataset.theme = 'light'; // Disable
```

#### Benefits

- **Semantic**: Colors have meaning (primary, success) not just appearance (blue, green)
- **Consistent**: All components use the same color tokens
- **Flexible**: Change entire theme by updating CSS custom properties
- **Tailwind Compatible**: Still get all Tailwind utilities and PurgeCSS benefits
- **Runtime Themeable**: Can switch themes without rebuilding CSS

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
- **Unit Tests**: ExUnit tests for component rendering, variants, and interaction
- **Generator Tests**: Verify correct file creation and code generation
- **Visual Tests**: Playwright-MCP for component appearance and responsive behavior
- **Accessibility Tests**: ARIA attributes, keyboard navigation, and screen reader compatibility

## Dependencies

### Generator Development Dependencies
- **Stellar**: Headless components for accessibility and behavior (`path: "../stellar"`)
- **TailwindMerge**: Class conflict resolution for dynamic styling 
- **Igniter**: Code generation and project modification toolkit
- **Phoenix LiveView**: Component system and reactivity

### Component Showcase
Component examples and interactive testing are available in the standalone storybook app located at `../storybook/`. This is a separate Phoenix application that imports Pulsar as a dependency.

**Important**: Generated components depend on **Stellar** and **TailwindMerge** as the only required dependencies. No Pulsar package dependency is needed.

**Generated Components Include:**
- **Badge**: Flexible labels with variants/sizes, removable option, and action slot
- **Button**: Multiple variants (solid, outline, ghost, link) with full color palette
- **Icon**: Centralized icon component (Heroicons; outline/solid/mini/micro, sizes, accessibility)
- **Input**: Text inputs with decorator system (start/end icons, text, buttons)
- **Label**: Typography variants with required indicators and helper text
- **Link**: Link component with button-like styling options
- **Select**: Native select with custom arrow, multi-select badges, and option groups
- **Textarea**: Multi-line input with consistent styling
- Complete component implementation using Stellar for behavior
- TailwindMerge integration for intelligent class composition  
- All styling and interaction code
- Full accessibility features via Stellar

## Commands

### Development
```bash
mix compile              # Compile the generator
mix test                # Run all tests
mix dialyzer            # Type checking
mix credo               # Code quality
# No server - Pulsar is generator-only
```

### Generator Usage (in user apps)
```bash
mix pulsar.gen.button    # Generate button component
mix pulsar.gen.form      # Generate form components
mix pulsar.gen.modal     # Generate modal component
```

## Testing Strategy

Pulsar uses a multi-layered testing approach to ensure component quality, accessibility, and visual consistency.

### Unit Testing with ExUnit

**Component Functionality Tests:**
```elixir
# test/pulsar/components/button_test.exs
describe "button/1 basic functionality" do
  test "renders button with default props" do
    html = rendered_to_string(~H"<Button.button>Click me</Button.button>")
    assert html =~ ~s(<button)
    assert html =~ "bg-primary-500"  # Theme color
    assert html =~ "h-10"            # Default size
  end
end
```

**Variant Testing:**
- Tests all variant combinations (solid, outline, ghost, link)
- Verifies color applications for each variant
- Validates size classes and responsive behavior
- Checks state handling (loading, disabled, pressed)

**TailwindMerge Integration:**
- Tests class conflict resolution
- Validates custom class overrides
- Ensures proper class deduplication

### Visual Testing with Playwright-MCP

**Component Appearance Testing:**
```bash
# Start the showcase app for visual testing (in ../storybook/)
mix phx.server

# Test components visually using Claude Code's browser tools
# Screenshots are automatically saved to .playwright-mcp/
```

**Visual Test Coverage:**
- **Spacing and Layout**: Button automatic spacing, gap handling
- **Theme Switching**: Light/dark mode transitions and colors
- **Responsive Behavior**: Component appearance across breakpoints
- **State Visualization**: Loading, disabled, and interactive states
- **Icon Integration**: Icon button alignment and sizing

**Screenshot Artifacts:**
- `button-automatic-spacing.png` - Layout and spacing validation
- `dark-mode-enabled.png` - Dark theme appearance
- `icon-button-spacing.png` - Icon button layout consistency

### Accessibility Testing

**ARIA Compliance:**
```elixir
test "includes focus ring classes" do
  html = rendered_to_string(~H"<Button.button>Focus test</Button.button>")
  assert html =~ "focus-visible:outline-none"
  assert html =~ "focus-visible:ring-2"
end

test "supports aria-label for icon-only buttons" do
  html = rendered_to_string(~H"<Button.button aria_label=\"Add item\">+</Button.button>")
  assert html =~ ~s(aria-label="Add item")
end
```

**Keyboard Navigation:**
- Tab order and focus management
- Enter/Space key activation
- Escape key handling for dismissible components
- Arrow key navigation for grouped components

**Screen Reader Support:**
- Proper semantic markup (`button`, `a`, `div` as appropriate)
- State announcements for loading/disabled states
- Role and property attributes for complex components

### Generator Testing

**File Generation Tests:**
```elixir
# test/mix/tasks/pulsar/gen/button_test.exs
test "generates button component with correct content" do
  # Test file creation, module naming, and import updates
end
```

**Code Generation Validation:**
- Verifies correct file paths and module names
- Tests code generation (stellar, tailwind_merge code embedded)
- Validates component import updates
- Checks error handling for edge cases

### Showcase App Integration Testing

**Component Showcase Validation:**
- All variants rendered correctly
- Interactive examples function properly
- Code snippets match actual implementation
- Dark/light mode toggle works across all components

**Development Workflow:**
1. **Component Development**: Build component with comprehensive ExUnit tests
2. **Visual Validation**: Use Playwright-MCP to capture screenshots and verify appearance
3. **Showcase Update**: Add comprehensive examples and usage patterns in the storybook app
4. **Accessibility Audit**: Test keyboard navigation and screen reader compatibility
5. **Generator Testing**: Ensure code generation works in target projects

### Testing Commands

```bash
# Run all unit tests
mix test

# Run specific component tests  
mix test test/pulsar/components/button_test.exs

# Run generator tests
mix test test/mix/tasks/pulsar/gen/

# Start showcase app for visual testing (in ../storybook/)
mix phx.server

# Test with coverage
mix test --cover
```

### Testing Guidelines

**When Adding New Components:**
1. Write comprehensive unit tests covering all variants
2. Add accessibility tests for ARIA attributes and keyboard nav
3. Create storybook page with all examples
4. Use Playwright-MCP to capture visual validation screenshots
5. Test generator functionality in a sample Phoenix app

**Visual Test Maintenance:**
- Screenshots are gitignored but can be regenerated for validation
- Use consistent naming: `{component}-{feature}.png`
- Test both light and dark themes
- Capture responsive breakpoints for complex layouts

## Integration Patterns

### Phoenix LiveView
Components integrate seamlessly with LiveView:
```elixir
<.button variant="primary" phx-click="save" loading={@saving}>
  Save Changes
</.button>

<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" />
  <.select field={@form[:country]} options={@countries} />
</.simple_form>
```

### Tailwind CSS & TailwindMerge
All styling through Tailwind utilities with intelligent class merging:

**TailwindMerge Integration:**
```elixir
# Components use TailwindMerge for class conflict resolution
assigns = assign(assigns, :merged_classes,
  merge([
    button_base(@variant),           # Base component classes
    variant_classes(@variant, @color), # Variant-specific classes
    size_classes(@size),             # Size-specific classes
    @class                          # User-provided custom classes
  ])
)
```

**Benefits:**
- **Conflict Resolution**: Custom classes override component defaults intelligently
- **No Duplicate Classes**: Removes redundant utilities automatically  
- **Predictable Styling**: Last-in-wins for conflicting properties
- **PurgeCSS Compatible**: All classes are still standard Tailwind utilities
- **Dark Mode**: Automatic dark: prefix handling
- **Responsive Design**: Full Tailwind breakpoint support

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

## Component Showcase Development

Component examples are developed in the standalone storybook app located at `../storybook/`. The storybook provides:

- **Live component preview** with all variants, sizes, and states
- **Dark/light mode toggle** for testing theme support
- **Usage examples** with code snippets
- **Interactive testing** of component behavior

### Showcase Requirements

**All new components should have showcase pages** that demonstrate:
1. **All variants** (primary, secondary, success, error, etc.)
2. **All sizes** (sm, md, lg, icon, etc.)
3. **All states** (normal, loading, disabled, etc.)
4. **Usage examples** with realistic code snippets
5. **Dark mode compatibility** for theme switching

To add a component to the showcase:
1. Navigate to `../storybook/` directory
2. Add component to the showcase app's LiveView pages
3. Import Pulsar component and create comprehensive examples
4. Test all variants and states

## Contributing Guidelines

When adding new components:
1. Create generator in `lib/pulsar/generators/`
2. Add template in `priv/templates/`
3. **Add showcase page** in the storybook app with all variants, states, and examples
4. Write comprehensive tests
5. Document usage patterns
6. Ensure accessibility compliance
7. Test with various Tailwind themes

When modifying existing components:
1. Update both generator and template
2. **Update showcase examples** in the storybook app to reflect changes
3. Maintain backwards compatibility where possible
4. Update documentation and examples
5. Test generation in sample Phoenix app